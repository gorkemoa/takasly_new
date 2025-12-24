import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth/login_model.dart';
import '../models/auth/register_model.dart';
import '../models/auth/verification_model.dart';
import '../models/auth/forgot_password_model.dart';
import '../models/auth/get_user_model.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../main.dart'; // For navigatorKey
import '../views/auth/login_view.dart';

enum AuthState { idle, busy, error, success }

enum AuthFlow { register, forgotPassword }

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
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

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('userToken');
    final userId = prefs.getInt('userId');

    if (token != null && userId != null) {
      _user = LoginResponseModel(userID: userId, token: token);
      _logger.i("Restored session for user: $userId");
      notifyListeners();
      // Optionally refresh user profile
      getUser();
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
        await prefs.setInt('userId', _user!.userID);
      }

      _state = AuthState.success;
      _logger.i("Login successful for user: ${_user?.userID}");
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = e.toString();
      _logger.e("Login failed: $e");
    } finally {
      notifyListeners();
    }
  }

  Future<void> getUser() async {
    if (_user?.token == null) {
      // If we don't have a token, we can't fetch the user.
      // Ideally should handle this case (logout or re-login).
      _logger.w("getUser called but no user token available.");
      return;
    }

    _state = AuthState.busy;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = GetUserRequestModel(
        userToken: _user!.token,
        platform: "ios", // Placeholder, ideally from device info
        version: "1.0.0", // Placeholder, ideally from package_info
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
      final request = RegisterRequestModel(
        userFirstname: firstName,
        userLastname: lastName,
        userEmail: email,
        userPhone: phone,
        userPassword: password,
        version: "1.0.0",
        platform: "android", // TODO: Update based on real platform if needed
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
          await prefs.setInt('userId', _user!.userID);

          _logger.i(
            "Verification successful (Register). User logged in: ${_user?.userID}",
          );
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

  Future<void> logout({bool autoRedirect = false}) async {
    _user = null;
    _userProfile = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userToken');
    await prefs.remove('userId');

    _state = AuthState.idle;
    _errorMessage = null;
    _logger.i("User logged out");
    notifyListeners();

    if (autoRedirect) {
      navigatorKey.currentState?.pushAndRemoveUntil(
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
}
