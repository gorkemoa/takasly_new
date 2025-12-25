import 'package:flutter/material.dart';
import '../models/general_models.dart';
import '../services/general_service.dart';

class ContactViewModel extends ChangeNotifier {
  final GeneralService _generalService = GeneralService();

  List<ContactSubject> _subjects = [];
  bool _isLoading = false;
  ContactSubject? _selectedSubject;
  final TextEditingController messageController = TextEditingController();

  List<ContactSubject> get subjects => _subjects;
  bool get isLoading => _isLoading;
  ContactSubject? get selectedSubject => _selectedSubject;

  Future<void> fetchSubjects() async {
    _setLoading(true);
    try {
      _subjects = await _generalService.getContactSubjects();
    } catch (e) {
      debugPrint('Error fetching subjects: $e');
    } finally {
      _setLoading(false);
    }
  }

  void setSubject(ContactSubject? subject) {
    _selectedSubject = subject;
    notifyListeners();
  }

  Future<bool> sendMessage(String userToken) async {
    if (_selectedSubject == null || messageController.text.trim().isEmpty) {
      return false;
    }

    _setLoading(true);
    try {
      final response = await _generalService.sendMessage(
        userToken: userToken,
        subjectId: _selectedSubject!.subjectID!,
        message: messageController.text.trim(),
      );

      if (response['success'] == true) {
        messageController.clear();
        _selectedSubject = null;
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error sending message: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }
}
