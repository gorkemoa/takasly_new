import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/notification/notification_model.dart';
import 'package:logger/logger.dart';

class NotificationViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final Logger _logger = Logger();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<NotificationModel> _notifications = [];
  List<NotificationModel> get notifications => _notifications;

  Future<void> fetchNotifications(int userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.getNotifications(userId);

      if (response['success'] == true &&
          response['data'] != null &&
          response['data']['notifications'] != null) {
        final List list = response['data']['notifications'];
        _notifications = list
            .map((e) => NotificationModel.fromJson(e))
            .toList();
      } else {
        _notifications = [];
      }
    } catch (e) {
      _errorMessage = e.toString();
      _logger.e('Fetch notifications error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
