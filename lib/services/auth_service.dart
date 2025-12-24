import '../core/constants/api_constants.dart';
import '../models/auth/login_model.dart';
import '../models/auth/register_model.dart';
import '../models/auth/verification_model.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();

  Future<LoginResponseModel> login(LoginRequestModel request) async {
    final response = await _apiService.post(
      ApiConstants.login,
      request.toJson(),
    );

    // Verify response structure based on user request:
    // {
    //     "error": false,
    //     "success": true,
    //     "data": {
    //         "userID": 3,
    //         "token": "C4i3HWgKOZ8r9syC9o0m566DtABZDCYs"
    //     },
    //     "200": "OK"
    // }

    if (response['data'] != null) {
      return LoginResponseModel.fromJson(response['data']);
    } else {
      // Should be handled by ApiService or custom logic if structure differs
      throw Exception("Login failed: invalid response structure");
    }
  }

  Future<RegisterResponseModel> register(RegisterRequestModel request) async {
    final response = await _apiService.post(
      ApiConstants.register,
      request.toJson(),
    );

    if (response['data'] != null) {
      return RegisterResponseModel.fromJson(response['data']);
    } else {
      throw Exception("Register failed: invalid response structure");
    }
  }

  Future<CodeControlResponseModel> verifyCode(
    CodeControlRequestModel request,
  ) async {
    final response = await _apiService.post(
      ApiConstants.checkCode,
      request.toJson(),
    );

    if (response['data'] != null) {
      return CodeControlResponseModel.fromJson(response['data']);
    } else {
      // verification success but no data needed strictly, but model expects it
      // if data is empty map or null, we can return empty model or handle accordingly
      // Based on user provided response: "data": { "passToken": "" }
      return CodeControlResponseModel.fromJson(response['data']);
    }
  }

  Future<ResendCodeResponseModel> resendCode(
    ResendCodeRequestModel request,
  ) async {
    final response = await _apiService.post(
      ApiConstants.againSendCode,
      request.toJson(),
    );

    if (response['data'] != null) {
      return ResendCodeResponseModel.fromJson(response['data']);
    } else {
      throw Exception("Resend code failed: invalid data");
    }
  }
}
