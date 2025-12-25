import 'api_service.dart';
import '../core/constants/api_constants.dart';
import '../models/general_models.dart';

class GeneralService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> getLogos() async {
    try {
      final response = await _apiService.get(ApiConstants.logos);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCategories([int parentId = 0]) async {
    try {
      // Using 0 as default parentId as per requirement "id asla statik gidemez"
      // but 0 is the root category ID typically.
      // We allow passing it in now.
      final response = await _apiService.get(
        '${ApiConstants.categories}$parentId',
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<City>> getCities() async {
    try {
      final response = await _apiService.get(ApiConstants.cities);
      if (response['success'] == true && response['data'] != null) {
        final List list = response['data']['cities'];
        return list.map((e) => City.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<List<District>> getDistricts(int cityId) async {
    try {
      final response = await _apiService.get(
        '${ApiConstants.districts}$cityId',
      );
      if (response['success'] == true && response['data'] != null) {
        final List list = response['data']['districts'];
        return list.map((e) => District.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Condition>> getConditions() async {
    try {
      final response = await _apiService.get(ApiConstants.conditions);
      if (response['success'] == true && response['data'] != null) {
        final List list = response['data']['conditions'];
        return list.map((e) => Condition.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      // Return empty list instead of rethrowing to not break entire filter UI if just this fails
      return [];
    }
  }

  Future<List<ContactSubject>> getContactSubjects() async {
    try {
      final response = await _apiService.get(ApiConstants.contactSubjects);
      if (response['success'] == true && response['data'] != null) {
        final List list = response['data']['subjects'];
        return list.map((e) => ContactSubject.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> sendMessage({
    required String userToken,
    required int subjectId,
    required String message,
  }) async {
    try {
      final response = await _apiService.post(ApiConstants.sendMessage, {
        'userToken': userToken,
        'subject': subjectId,
        'message': message,
      });
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
