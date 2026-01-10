import 'api_service.dart';
import '../core/constants/api_constants.dart';
import '../models/general_models.dart';

import '../models/search/popular_category_model.dart';

class GeneralService {
  final ApiService _apiService = ApiService();

  // Static Caches
  static final Map<int, Map<String, dynamic>> _categoriesCache = {};
  static List<City>? _citiesCache;
  static List<Condition>? _conditionsCache;
  static List<PopularCategory>? _popularCategoriesCache;
  static List<DeliveryType>? _deliveryTypesCache;
  static List<TradeStatus>? _tradeStatusesCache;

  Future<List<PopularCategory>> getPopularCategories() async {
    if (_popularCategoriesCache != null) return _popularCategoriesCache!;
    try {
      final response = await _apiService.get(ApiConstants.popularCategories);
      if (response['success'] == true && response['data'] != null) {
        final List list = response['data']['categories'];
        _popularCategoriesCache = list
            .map((e) => PopularCategory.fromJson(e))
            .toList();
        return _popularCategoriesCache!;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getLogos() async {
    try {
      final response = await _apiService.get(ApiConstants.logos);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCategories([int parentId = 0]) async {
    if (_categoriesCache.containsKey(parentId)) {
      return _categoriesCache[parentId]!;
    }
    try {
      final response = await _apiService.get(
        '${ApiConstants.categories}$parentId',
      );
      if (response['success'] == true) {
        _categoriesCache[parentId] = response;
      }
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<City>> getCities() async {
    if (_citiesCache != null) return _citiesCache!;
    try {
      final response = await _apiService.get(ApiConstants.cities);
      if (response['success'] == true && response['data'] != null) {
        final List list = response['data']['cities'];
        _citiesCache = list.map((e) => City.fromJson(e)).toList();
        return _citiesCache!;
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<List<District>> getDistricts(int cityId) async {
    // Districts change per city, maybe don't cache all cities districts yet
    // but could cache current city's districts.
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
    if (_conditionsCache != null) return _conditionsCache!;
    try {
      final response = await _apiService.get(ApiConstants.conditions);
      if (response['success'] == true && response['data'] != null) {
        final List list = response['data']['conditions'];
        _conditionsCache = list.map((e) => Condition.fromJson(e)).toList();
        return _conditionsCache!;
      }
      return [];
    } catch (e) {
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

  Future<List<DeliveryType>> getDeliveryTypes() async {
    if (_deliveryTypesCache != null) return _deliveryTypesCache!;
    try {
      final response = await _apiService.get(ApiConstants.deliveryTypes);
      if (response['success'] == true && response['data'] != null) {
        final List list = response['data']['deliveryTypes'];
        _deliveryTypesCache = list
            .map((e) => DeliveryType.fromJson(e))
            .toList();
        return _deliveryTypesCache!;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<TradeStatus>> getTradeStatuses() async {
    if (_tradeStatusesCache != null) return _tradeStatusesCache!;
    try {
      final response = await _apiService.get(ApiConstants.tradeStatuses);
      if (response['success'] == true && response['data'] != null) {
        final List list = response['data']['statuses'];
        _tradeStatusesCache = list.map((e) => TradeStatus.fromJson(e)).toList();
        return _tradeStatusesCache!;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Contract?> getContract(int id) async {
    try {
      final response = await _apiService.get('${ApiConstants.contract}$id');
      if (response['success'] == true && response['data'] != null) {
        return Contract.fromJson(response['data']);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
}
