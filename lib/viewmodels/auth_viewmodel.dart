import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth/social_login_model.dart';
import '../models/auth/login_model.dart';
import '../models/auth/register_model.dart';
import '../models/auth/verification_model.dart';
import '../models/auth/forgot_password_model.dart';
import '../models/auth/get_user_model.dart';
import '../services/auth_service.dart';
import '../services/account_service.dart';
import '../services/api_service.dart';
import '../services/general_service.dart';
import '../models/general_models.dart';
import '../models/account/update_user_model.dart';
import '../models/account/change_password_model.dart';
import '../models/account/delete_user_model.dart';
import '../services/firebase_messaging_service.dart';
import '../services/navigation_service.dart';
import '../services/analytics_service.dart';
import '../views/auth/login_view.dart';

enum AuthState { idle, busy, error, success }

enum AuthFlow { register, forgotPassword }

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final AccountService _accountService = AccountService();
  final GeneralService _generalService = GeneralService();
  final Logger _logger = Logger();

  AuthState _state = AuthState.idle;
  AuthState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  LoginResponseModel? _user;
  LoginResponseModel? get user => _user;

  // Full user profile data
  User? _userProfile;
  User? get userProfile => _userProfile;

  // Temp storage for verification flow
  int? _tempUserId;
  String? _tempUserToken;
  String? _codeToken;

  // Forgot Password Flow
  AuthFlow _currentFlow = AuthFlow.register;
  AuthFlow get currentFlow => _currentFlow;

  String? _passToken;

  AuthViewModel() {
    _init();
  }

  Future<void> _init() async {
    // Setup Global 403 Handler
    ApiService().onForbidden = () {
      logout(autoRedirect: true);
    };

    await _checkLoginStatus();
  }

  bool _isAuthCheckComplete = false;
  bool get isAuthCheckComplete => _isAuthCheckComplete;

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('userToken');

    // Get userID supporting both Int and String storage
    int? userId;
    final dynamic rawUserId = prefs.get('userID');
    if (rawUserId is int) {
      userId = rawUserId;
    } else if (rawUserId is String) {
      userId = int.tryParse(rawUserId);
    }

    if (token != null && userId != null) {
      _user = LoginResponseModel(userID: userId, token: token);
      FirebaseMessagingService.subscribeToUserTopic(userId.toString());
      _logger.i("Restored session for user: $userId");
      notifyListeners();
      // Optionally refresh user profile
      getUser();
    }
    _isAuthCheckComplete = true;
    notifyListeners();
  }

  Future<Contract?> getContract(int id) async {
    try {
      return await _generalService.getContract(id);
    } catch (e) {
      _logger.e("Get Contract failed: $e");
      return null;
    }
  }

  Future<void> login(String email, String password) async {
    _state = AuthState.busy;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = LoginRequestModel(
        userEmail: email,
        userPassword: password,
      );
      _user = await _authService.login(request);

      // Save session
      if (_user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userToken', _user!.token);
        await prefs.setInt('userID', _user!.userID);
        FirebaseMessagingService.subscribeToUserTopic(_user!.userID.toString());

        // Automatically fetch user profile after successful login
        await _getUserInternal();
      }

      _state = AuthState.success;
      _logger.i("Login successful for user: ${_user?.userID}");
      AnalyticsService().logLogin('email');
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = e.toString();
      _logger.e("Login failed: $e");
    } finally {
      notifyListeners();
    }
  }

  Future<void> getUser() async {
    if (_state == AuthState.busy) return;
    await _getUserInternal();
  }

  Future<void> _getUserInternal() async {
    if (_user?.token == null) {
      _logger.w("_getUserInternal called but no user token available.");
      return;
    }

    _state = AuthState.busy;
    _errorMessage = null;
    notifyListeners();

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final request = GetUserRequestModel(
        userToken: _user!.token,
        platform: Platform.isIOS ? "ios" : "android",
        version: packageInfo.version,
      );

      final response = await _authService.getUser(request);
      _userProfile = response.user;

      _logger.i("User profile fetched: ${_userProfile?.userFullname}");
      _state = AuthState.success;
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = e.toString();
      _logger.e("Get User failed: $e");
    } finally {
      notifyListeners();
    }
  }

  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    bool policy = true,
    bool kvkk = true,
  }) async {
    _state = AuthState.busy;
    _errorMessage = null;
    _currentFlow = AuthFlow.register; // Set flow
    notifyListeners();

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final request = RegisterRequestModel(
        userFirstname: firstName,
        userLastname: lastName,
        userEmail: email,
        userPhone: phone,
        userPassword: password,
        version: packageInfo.version,
        platform: Platform.isIOS ? "ios" : "android",
        policy: policy,
        kvkk: kvkk,
      );

      final response = await _authService.register(request);

      // Store data temporarily for verification
      _tempUserId = response.userID;
      _tempUserToken = response.userToken;
      _codeToken = response.codeToken;

      // Do NOT set _user yet, wait for verification
      _state = AuthState.success;
      _logger.i(
        "Register initial success. Waiting for verification code. CodeToken: $_codeToken",
      );
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = e.toString();
      _logger.e("Register failed: $e");
    } finally {
      notifyListeners();
    }
  }

  Future<void> forgotPassword(String email) async {
    _state = AuthState.busy;
    _errorMessage = null;
    _currentFlow = AuthFlow.forgotPassword; // Set flow
    notifyListeners();

    try {
      final request = ForgotPasswordRequestModel(userEmail: email);
      final response = await _authService.forgotPassword(request);

      _codeToken = response.codeToken;
      // Note: We might not get a userToken here directly if the API doesn't return it for forgot password
      // But we need codeToken for verification.

      _state = AuthState.success;
      _logger.i("Forgot Password request success. CodeToken: $_codeToken");
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = e.toString();
      _logger.e("Forgot Password failed: $e");
    } finally {
      notifyListeners();
    }
  }

  Future<void> verifyCode(String code) async {
    if (_codeToken == null) {
      _state = AuthState.error;
      _errorMessage = "Doğrulama oturumu bulunamadı.";
      notifyListeners();
      return;
    }

    _state = AuthState.busy;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = CodeControlRequestModel(
        code: code,
        codeToken: _codeToken!,
      );

      final response = await _authService.verifyCode(request);

      if (_currentFlow == AuthFlow.register) {
        // Verification successful, now we can log the user in
        if (_tempUserId != null && _tempUserToken != null) {
          _user = LoginResponseModel(
            userID: _tempUserId!,
            token: _tempUserToken!,
          );

          // Save session
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userToken', _user!.token);
          await prefs.setInt('userID', _user!.userID);
          FirebaseMessagingService.subscribeToUserTopic(
            _user!.userID.toString(),
          );

          _logger.i(
            "Verification successful (Register). User logged in: ${_user?.userID}",
          );
          AnalyticsService().logSignUp('email');

          // Automatically fetch user profile after successful verification
          await _getUserInternal();
        } else {
          // Should not happen in register flow usually
          _logger.w(
            "Verification success but missing temp user data for login.",
          );
        }
      } else {
        // Forgot Password Flow
        _passToken = response.passToken;
        _logger.i(
          "Verification successful (Forgot Password). PassToken: $_passToken",
        );
      }

      _state = AuthState.success;

      // Clear temp data
      _tempUserId = null;
      _tempUserToken = null;
      _codeToken = null;
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = e.toString();
      _logger.e("Verification failed: $e");
    } finally {
      notifyListeners();
    }
  }

  // Update Password Method (Forgot Password Flow)
  Future<void> updatePassword(String password, String passwordAgain) async {
    if (_passToken == null) {
      _state = AuthState.error;
      _errorMessage = "Şifre yenileme oturumu bulunamadı.";
      notifyListeners();
      return;
    }

    _state = AuthState.busy;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = UpdatePasswordRequestModel(
        passToken: _passToken!,
        password: password,
        passwordAgain: passwordAgain,
      );

      await _authService.updatePassword(request);

      _state = AuthState.success;
      _logger.i("Password updated successfully.");

      // Clear pass token
      _passToken = null;
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = e.toString();
      _logger.e("Update Password failed: $e");
    } finally {
      notifyListeners();
    }
  }

  // Update Password Method (Profile Flow)
  Future<void> updateProfilePassword(
    String password,
    String passwordAgain,
  ) async {
    if (_user?.token == null) {
      _state = AuthState.error;
      _errorMessage = "Kullanıcı oturumu bulunamadı.";
      notifyListeners();
      return;
    }

    _state = AuthState.busy;
    _errorMessage = null;
    notifyListeners();

    try {
      // User says: use userToken as passToken
      final request = UpdatePasswordRequestModel(
        passToken: _user!.token,
        password: password,
        passwordAgain: passwordAgain,
      );

      await _authService.updatePassword(request);

      _state = AuthState.success;
      _logger.i("Profile password updated successfully.");
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = e.toString();
      _logger.e("Profile Update Password failed: $e");
    } finally {
      notifyListeners();
    }
  }

  Future<void> resendCode() async {
    if (_tempUserToken == null) {
      _state = AuthState.error;
      _errorMessage = "Kullanıcı oturumu bulunamadı.";
      notifyListeners();
      return;
    }

    _state = AuthState.busy;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = ResendCodeRequestModel(userToken: _tempUserToken!);
      final response = await _authService.resendCode(request);

      _codeToken = response.codeToken;
      // Do NOT set AuthState.success here to avoid triggering navigation
      _state = AuthState.idle;
      _logger.i("Code resent successfully. New CodeToken: $_codeToken");
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = e.toString();
      _logger.e("Resend code failed: $e");
    } finally {
      notifyListeners();
    }
  }

  // Social Login Methods

  Future<void> signInWithGoogle() async {
    _state = AuthState.busy;
    _errorMessage = null;
    notifyListeners();

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: Platform.isIOS
            ? '422264804561-llio284tijfqkh873at3ci09fna2epl0.apps.googleusercontent.com'
            : null,
        scopes: <String>['email'],
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in
        _state = AuthState.idle;
        notifyListeners();
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception("Google Sign-In failed: No ID Token retrieved.");
      }

      await _processSocialLogin(platform: 'google', idToken: idToken);
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = e.toString();
      _logger.e("Google Sign-In failed: $e");
    } finally {
      if (_state != AuthState.success) {
        notifyListeners();
      }
    }
  }

  Future<void> signInWithApple() async {
    _state = AuthState.busy;
    _errorMessage = null;
    notifyListeners();

    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final String? identityToken = credential.identityToken;
      if (identityToken == null) {
        throw Exception("Apple Sign-In failed: No Identity Token retrieved.");
      }

      await _processSocialLogin(
        platform: 'apple',
        idToken: identityToken,
        // appleGivenName: credential.givenName,
        // appleFamilyName: credential.familyName,
      );
    } catch (e) {
      if (e is SignInWithAppleAuthorizationException &&
          e.code == AuthorizationErrorCode.canceled) {
        _state = AuthState.idle;
        notifyListeners();
        return;
      }
      _state = AuthState.error;
      _errorMessage = e.toString();
      _logger.e("Apple Sign-In failed: $e");
    } finally {
      if (_state != AuthState.success) {
        notifyListeners();
      }
    }
  }

  Future<void> _processSocialLogin({
    required String platform,
    required String idToken,
  }) async {
    try {
      // 1. Get Device Info
      final deviceData = await _getDeviceInfo();
      final deviceID = deviceData['deviceID']!;
      final devicePlatform = deviceData['devicePlatform']!;

      // 2. Get App Version
      final packageInfo = await PackageInfo.fromPlatform();
      final version = packageInfo.version;

      // 3. Get FCM Token
      String? fcmToken = await FirebaseMessagingService.getToken();

      // On iOS simulators or if APNs not configured, this might be null.
      // We'll use a placeholder if null for dev purposes, but API might require it.
      fcmToken ??= "fcm-token-not-available";

      final request = SocialLoginRequestModel(
        platform: platform,
        deviceID: deviceID,
        devicePlatform: devicePlatform,
        version: version,
        fcmToken: fcmToken,
        idToken: idToken,
      );

      _user = await _authService.loginSocial(request);

      if (_user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userToken', _user!.token);
        await prefs.setInt('userID', _user!.userID);
        FirebaseMessagingService.subscribeToUserTopic(_user!.userID.toString());

        // Automatically fetch user profile after successful social login
        await _getUserInternal();

        _state = AuthState.success;
        _logger.i(
          "Social Login successful ($platform). User: ${_user!.userID}",
        );
        AnalyticsService().logLogin(platform);
      }
      // notifyListeners() is called in finally block of caller
    } catch (e) {
      // Re-throw to be caught by caller
      throw e;
    }
  }

  Future<Map<String, String>> _getDeviceInfo() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String deviceID = "unknown";
    String devicePlatform = Platform.isAndroid ? "android" : "ios";

    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceID = androidInfo.id; // Board ID or similar
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceID = iosInfo.identifierForVendor ?? "ios-vendor-id";
      }
    } catch (e) {
      _logger.w("Could not get detailed device info: $e");
    }

    return {'deviceID': deviceID, 'devicePlatform': devicePlatform};
  }

  Future<void> logout({bool autoRedirect = false}) async {
    if (_user?.userID != null) {
      FirebaseMessagingService.unsubscribeFromUserTopic(
        _user!.userID.toString(),
      );
    }
    _user = null;
    _userProfile = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userToken');
    await prefs.remove('userID');

    // Also sign out from social providers
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}

    // Apple doesn't have a programmatic sign out that clears state in the same way,
    // but we cleared our local session.

    _state = AuthState.idle;
    _errorMessage = null;
    _logger.i("User logged out");
    notifyListeners();

    if (autoRedirect) {
      NavigationService.navigatorKey?.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginView()),
        (route) => false,
      );
    }
  }

  // Reset state method in case we leave the page and come back
  void resetState() {
    _state = AuthState.idle;
    _errorMessage = null;
    notifyListeners();
  }

  // Account Management Methods

  Future<void> updateAccount(UpdateUserRequestModel request) async {
    if (_user?.token == null) return;
    request.userToken = _user!.token; // Ensure token is set

    _state = AuthState.busy;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _accountService.updateUser(request);
      if (response.success == true) {
        _logger.i("User account updated successfully.");
        AnalyticsService().logEvent('update_account');
        // Refresh user profile
        await _getUserInternal();
      } else {
        throw Exception(response.message ?? "Update failed");
      }
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = e.toString();
      _logger.e("Update User Account failed: $e");
    } finally {
      if (_state == AuthState.busy) {
        _state = AuthState.success;
      }
      notifyListeners();
    }
  }

  Future<void> changePasswordInApp(
    String currentPassword,
    String newPassword,
    String newPasswordAgain,
  ) async {
    if (_user?.token == null) return;

    _state = AuthState.busy;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = ChangePasswordRequestModel(
        userToken: _user!.token,
        currentPassword: currentPassword,
        password: newPassword,
        passwordAgain: newPasswordAgain,
      );

      final response = await _accountService.changePassword(request);
      if (response.success == true) {
        _state = AuthState.success;
        _logger.i("Password changed successfully.");
        AnalyticsService().logEvent('change_password');
      } else {
        throw Exception("Password change failed");
      }
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = e.toString();
      _logger.e("Change Password failed: $e");
    } finally {
      notifyListeners();
    }
  }

  Future<void> deleteAccount() async {
    if (_user?.token == null) return;

    _state = AuthState.busy;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = DeleteUserRequestModel(userToken: _user!.token);
      await _accountService.deleteUser(request);

      _logger.i("Account deleted successfully.");
      AnalyticsService().logEvent('delete_account');
      // Logout user after deletion
      await logout(autoRedirect: true);
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = e.toString();
      _logger.e("Delete Account failed: $e");
      notifyListeners();
    }
  }
}
