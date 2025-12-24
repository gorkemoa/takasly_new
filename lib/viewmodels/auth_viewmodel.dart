import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../models/auth/login_model.dart';
import '../models/auth/register_model.dart';
import '../models/auth/verification_model.dart';
import '../services/auth_service.dart';

enum AuthState { idle, busy, error, success }

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final Logger _logger = Logger();

  AuthState _state = AuthState.idle;
  AuthState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  LoginResponseModel? _user;
  LoginResponseModel? get user => _user;

  // Temp storage for verification flow
  int? _tempUserId;
  String? _tempUserToken;
  String? _codeToken;

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

      await _authService.verifyCode(request);

      // Verification successful, now we can log the user in
      _user = LoginResponseModel(userID: _tempUserId!, token: _tempUserToken!);

      _state = AuthState.success;
      _logger.i("Verification successful. User logged in: ${_user?.userID}");

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

  void logout() {
    _user = null;
    _state = AuthState.idle;
    _errorMessage = null;
    _logger.i("User logged out");
    notifyListeners();
  }

  // Reset state method in case we leave the page and come back
  void resetState() {
    _state = AuthState.idle;
    _errorMessage = null;
    notifyListeners();
  }
}
