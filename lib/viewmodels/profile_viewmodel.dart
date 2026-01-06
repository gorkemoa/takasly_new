import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../models/profile/profile_detail_model.dart';
import '../services/auth_service.dart';
import '../services/product_service.dart';
import '../services/account_service.dart';
import '../models/user/report_user_model.dart';
import '../models/account/blocked_user_model.dart';

enum ProfileState { idle, busy, error, success }

class ProfileViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final ProductService _productService = ProductService();
  final AccountService _accountService = AccountService();
  final Logger _logger = Logger();

  ProfileState _state = ProfileState.idle;
  ProfileState get state => _state;

  ProfileDetailModel? _profileDetail;
  ProfileDetailModel? get profileDetail => _profileDetail;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> getProfileDetail(int userId, String? userToken) async {
    _state = ProfileState.busy;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.getProfileDetail(userId, userToken);
      _profileDetail = response;
      _state = ProfileState.success;
      _logger.i("Profile detail loaded for user: $userId");
    } catch (e) {
      _state = ProfileState.error;
      _errorMessage = e.toString();
      _logger.e("Failed to load profile details: $e");
    } finally {
      notifyListeners();
    }
  }

  // Helper to check if the loaded profile belongs to the current user
  bool isCurrentUser(int? currentUserId) {
    if (currentUserId == null || _profileDetail == null) return false;
    return _profileDetail!.userID == currentUserId;
  }

  Future<bool> reportUser({
    required String userToken,
    required int reportedUserID,
    required String reason,
    required String step,
    int? productID,
    int? offerID,
  }) async {
    try {
      final request = ReportUserRequest(
        userToken: userToken,
        reportedUserID: reportedUserID,
        reason: reason,
        step: step,
        productID: productID,
        offerID: offerID,
      );
      await _productService.reportUser(request);
      return true;
    } catch (e) {
      _logger.e("Report User Hata", error: e);
      return false;
    }
  }

  Future<bool> blockUser({
    required String userToken,
    required int blockedUserID,
    String? reason,
  }) async {
    try {
      final request = BlockedUserRequest(
        userToken: userToken,
        blockedUserID: blockedUserID,
        reason: reason,
      );
      await _accountService.blockUser(request);
      return true;
    } catch (e) {
      _logger.e("Block User Hata", error: e);
      return false;
    }
  }

  Future<bool> deleteProduct({
    required String userToken,
    required int userId,
    required int productId,
  }) async {
    _state = ProfileState.busy;
    _errorMessage = null;
    notifyListeners();

    try {
      await _productService.deleteProduct(userToken, userId, productId);
      // Remove from local list if successful to avoid full refetch
      if (_profileDetail?.products != null) {
        _profileDetail!.products!.removeWhere((p) => p.productID == productId);
      }
      _state = ProfileState.success;
      return true;
    } catch (e) {
      _state = ProfileState.error;
      _errorMessage = e.toString();
      _logger.e("Product delete error: $e");
      return false;
    } finally {
      notifyListeners();
    }
  }

  Future<String?> sponsorProduct({
    required String userToken,
    required int productId,
  }) async {
    _errorMessage = null;
    notifyListeners();

    try {
      final message = await _productService.sponsorProduct(
        userToken,
        productId,
      );
      return message;
    } catch (e) {
      _logger.e("Product sponsor error: $e");
      return e.toString();
    } finally {
      notifyListeners();
    }
  }
}
