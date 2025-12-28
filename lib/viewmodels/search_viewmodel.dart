import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import '../models/products/product_models.dart' hide Category;
import '../services/product_service.dart';
import 'package:logger/logger.dart';

import '../services/general_service.dart';
import '../models/search/popular_category_model.dart';
import '../models/home/home_models.dart';
import '../models/general_models.dart';

class SearchViewModel extends ChangeNotifier {
  final ProductService _productService = ProductService();
  final GeneralService _generalService = GeneralService();
  final Logger _logger = Logger();

  List<Product> products = [];
  List<PopularCategory> popularCategories = [];
  bool isLoading = false;
  bool isLoadMoreRunning = false;
  bool isLastPage = false;
  int currentPage = 1;
  String? errorMessage;
  String _currentQuery = "";

  // Core Search Filter
  int? _currentCategoryId;
  String? _currentCategoryName;

  // Additional Filters
  List<City> cities = [];
  List<District> districts = [];
  List<Condition> conditions = [];
  List<Category> categories = []; // For filter selection if needed

  City? selectedCity;
  District? selectedDistrict;
  List<int> selectedConditionIds = [];
  String sortType = 'default';

  int totalItems = 0;

  String get currentQuery => _currentQuery;
  String? get currentCategoryName => _currentCategoryName;

  Future<void> init() async {
    // Parallel fetch of initial data
    await Future.wait([
      fetchPopularCategories(),
      fetchCities(),
      fetchConditions(),
      fetchCategories(),
    ]);
  }

  Future<String?> _getUserToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userToken');
  }

  Future<void> fetchPopularCategories() async {
    try {
      popularCategories = await _generalService.getPopularCategories();
      notifyListeners();
    } catch (e) {
      _logger.e("Error fetching popular categories: $e");
    }
  }

  Future<void> fetchCities() async {
    try {
      cities = await _generalService.getCities();
    } catch (e) {
      _logger.e("Error fetching cities: $e");
    }
  }

  Future<void> fetchDistricts(int cityId) async {
    try {
      districts = await _generalService.getDistricts(cityId);
      notifyListeners();
    } catch (e) {
      _logger.e("Error fetching districts: $e");
      districts = [];
      notifyListeners();
    }
  }

  Future<void> fetchConditions() async {
    try {
      conditions = await _generalService.getConditions();
    } catch (e) {
      _logger.e('Error fetching conditions: $e');
    }
  }

  Future<void> fetchCategories([int parentId = 0]) async {
    try {
      final response = await _generalService.getCategories(parentId);
      if (response['success'] == true && response['data'] != null) {
        final List cats = response['data']['categories'];
        categories = cats.map((e) => Category.fromJson(e)).toList();
      }
    } catch (e) {
      _logger.e('Error fetching categories: $e');
    }
  }

  // Filter Management Methods
  void setCategoryFilter(int categoryId, String categoryName) {
    _currentCategoryId = categoryId;
    _currentCategoryName = categoryName;
    notifyListeners();
  }

  void setSelectedCity(City? city) {
    selectedCity = city;
    selectedDistrict = null;
    districts = [];
    if (city?.cityNo != null) {
      fetchDistricts(city!.cityNo!);
    } else {
      notifyListeners();
    }
  }

  void setSelectedDistrict(District? district) {
    selectedDistrict = district;
    notifyListeners();
  }

  void toggleCondition(int conditionId) {
    if (selectedConditionIds.contains(conditionId)) {
      selectedConditionIds.remove(conditionId);
    } else {
      selectedConditionIds.add(conditionId);
    }
    notifyListeners();
  }

  void setSortType(String type) {
    sortType = type;
    notifyListeners();
  }

  // Apply filters triggers a search refresh
  void applyFilters() {
    search(_currentQuery, isRefresh: true);
  }

  // Favorites
  Future<void> toggleFavorite(int productId) async {
    final token = await _getUserToken();
    if (token == null) {
      // Don't show error message, just return. UI might show login prompt separately if needed.
      // Or show a snackbar via callback? ViewModel shouldn't depend on context.
      // We can set a localized error that UI observes.
      return;
    }

    // Optimistic update
    final index = products.indexWhere((p) => p.productID == productId);
    if (index != -1) {
      final product = products[index];
      final oldStatus = product.isFavorite ?? false;
      final newStatus = !oldStatus;

      // Update local state
      products[index] = product.copyWith(isFavorite: newStatus);
      notifyListeners();

      try {
        if (newStatus) {
          await _productService.addFavorite(token, productId);
        } else {
          await _productService.removeFavoriteProduct(token, productId);
        }
      } catch (e) {
        _logger.e("Error toggling favorite: $e");
        // Revert
        products[index] = product.copyWith(isFavorite: oldStatus);
        notifyListeners();
      }
    }
  }

  Future<void> searchByCategory(int categoryId, String categoryName) async {
    _currentCategoryId = categoryId;
    _currentCategoryName = categoryName;
    _currentQuery = ""; // Clear text search
    await _performSearchRequest(isRefresh: true);
  }

  Future<void> search(String query, {bool isRefresh = true}) async {
    if (isRefresh) {
      // NOTE: When doing a new text search, we usually clear category,
      // but maybe we want to KEEP other filters (city, sort)?
      // For now, let's keep other filters but clear category if query is non-empty.
      // If query is empty, it's just a refresh or filter application.
      if (query.isNotEmpty) {
        _currentCategoryId = null;
        _currentCategoryName = null;
      }
    }

    if (query.trim().isEmpty &&
        _currentCategoryId == null &&
        selectedCity == null &&
        selectedConditionIds.isEmpty &&
        sortType == 'default') {
      // All empty
      if (query.trim().isEmpty && _currentCategoryId == null) {
        products = [];
        _currentQuery = "";
        totalItems = 0;
        notifyListeners();
        return;
      }
    }

    if (isRefresh) {
      _currentQuery = query;
      isLoading = true;
      isLastPage = false;
      currentPage = 1;
      products = [];
      totalItems = 0;
      errorMessage = null;
      notifyListeners();
    } else {
      if (isLoadMoreRunning || isLastPage) return;
      isLoadMoreRunning = true;
      notifyListeners();
    }

    await _performSearchRequest(isRefresh: isRefresh);
  }

  String? userLat;
  String? userLong;

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium, // Medium is faster/sufficient
      );

      userLat = position.latitude.toString();
      userLong = position.longitude.toString();
    } catch (e) {
      _logger.e("Error getting user location for search: $e");
    }
  }

  Future<void> _performSearchRequest({required bool isRefresh}) async {
    try {
      // If sort is location, ensure we have coordinates
      if (sortType == 'location') {
        if (userLat == null || userLong == null) {
          await _getUserLocation();
        }

        // If still null after attempt, fallback to default sort to avoid API crash
        if (userLat == null || userLong == null) {
          _logger.w(
            "Sort type is location but no location found. Falling back to default.",
          );
          // We don't change 'sortType' variable to keep UI consistent (showing selected 'Location'),
          // but we switch it in the request to avoid backend error.
          // Actually, better to just let requestModel handle it, but we need to pass something safe or null.
          // If we pass null sortType, backend defaults.
        }
      }

      // Determine effective sort type
      String? effectiveSortType = sortType;
      if (sortType == 'location' && (userLat == null || userLong == null)) {
        effectiveSortType = 'default';
      } else if (sortType == 'default') {
        effectiveSortType = null;
      }

      final requestModel = ProductRequestModel(
        page: currentPage,
        searchText: _currentQuery,
        categoryID: _currentCategoryId,
        cityID: selectedCity?.cityNo,
        districtID: selectedDistrict?.districtNo,
        conditionIDs: selectedConditionIds.isNotEmpty
            ? selectedConditionIds
            : null,
        sortType: effectiveSortType,
        userLat: userLat,
        userLong: userLong,
      );

      final response = await _productService.getAllProducts(requestModel);

      if (response.success == true && response.data != null) {
        final newProducts = response.data!.products ?? [];

        // Update total items count
        if (response.data!.totalItems != null) {
          totalItems = response.data!.totalItems!;
        }

        if (isRefresh) {
          products = newProducts;
        } else {
          products.addAll(newProducts);
        }

        if (newProducts.isEmpty) {
          isLastPage = true;
        } else if (response.data?.totalPages != null &&
            currentPage >= response.data!.totalPages!) {
          isLastPage = true;
        } else {
          currentPage++;
        }
      } else {
        errorMessage = response.message ?? "Arama sonucu alınamadı.";
      }
    } catch (e) {
      _logger.e("Search error: $e");
      errorMessage = "Bir hata oluştu.";
    } finally {
      isLoading = false;
      isLoadMoreRunning = false;
      notifyListeners();
    }
  }

  void loadMore() {
    if ((_currentQuery.isNotEmpty ||
            _currentCategoryId != null ||
            products.isNotEmpty) &&
        !isLoading &&
        !isLoadMoreRunning &&
        !isLastPage) {
      isLoadMoreRunning = true;
      notifyListeners();
      _performSearchRequest(isRefresh: false);
    }
  }

  void clearSearch() {
    _currentQuery = "";
    _currentCategoryId = null;
    _currentCategoryName = null;

    // Clear filters too
    selectedCity = null;
    selectedDistrict = null;
    districts = [];
    selectedConditionIds = [];
    sortType = 'default';

    products = [];
    errorMessage = null;
    isLastPage = false;
    currentPage = 1;
    notifyListeners();
  }
}
