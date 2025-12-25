import 'package:flutter/material.dart';
import '../models/products/product_models.dart';
import '../services/product_service.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';

import 'package:logger/logger.dart';

class ProductViewModel extends ChangeNotifier {
  final ProductService _productService = ProductService();
  final LocationService _locationService = LocationService();
  final Logger _logger = Logger();

  List<Product> products = [];
  bool isLoading = false;
  bool isLoadMoreRunning = false;
  bool isLastPage = false;
  int currentPage = 1;
  String? errorMessage;

  // Default filter
  ProductRequestModel _currentFilter = ProductRequestModel(page: 1);

  Future<void> init() async {
    // Try to get location first
    await _fetchLocation();
    // After location is determined (success or fail), fetch products.
    // fetchProducts uses _currentFilter which _fetchLocation modifies.
    await fetchProducts(isRefresh: true);
  }

  Future<void> _fetchLocation() async {
    try {
      final position = await _locationService.getCurrentLocation();
      if (position != null) {
        _currentFilter.userLat = position.latitude.toString();
        _currentFilter.userLong = position.longitude.toString();
        _currentFilter.sortType = 'location'; // Set sort type to location
        _logger.i(
          'Location fetched: ${position.latitude}, ${position.longitude}. Sort type set to location.',
        );
      } else {
        _logger.w('Location could not be fetched. Using default sort.');
        _currentFilter.sortType = 'default';
        _currentFilter.userLat = "";
        _currentFilter.userLong = "";
      }
    } catch (e) {
      _logger.e('Error fetching location: $e');
      _currentFilter.sortType = 'default';
    }
  }

  Future<void> fetchProducts({bool isRefresh = false}) async {
    // Race condition fix: Allow refresh even if isLoading is true,
    // because we might be switching from "default sort" to "location sort"
    // immediately after app start.
    if (isLoading && isRefresh) {
      // We log but continue, effectively cancelling/overriding the previous request logically
      // (though network request might still finish, we'll overwrite the data)
      _logger.d(
        'Yükleme devam ederken yenileme istendi (Olası Konum/Token güncellemesi). Devam ediliyor.',
      );
      // Don't return here!
    }

    if (isLoadMoreRunning && !isRefresh) {
      _logger.d(
        'Daha fazla yükleme devam ederken yeni yükleme denendi. İptal ediliyor.',
      );
      return; // Don't load more if already loading more
    }
    if (!isRefresh && isLastPage) {
      _logger.d('Son sayfadayken daha fazla yükleme denendi. İptal ediliyor.');
      return;
    }

    if (isRefresh) {
      _logger.i('İlk ürün getirme/yenileme başlatılıyor.');
      isLoading = true;
      isLastPage = false;
      currentPage = 1;
      errorMessage = null;
      notifyListeners();
    } else {
      _logger.i('"Daha fazla yükle" ürün getirme başlatılıyor.');
      isLoadMoreRunning = true;
      notifyListeners();
    }

    int startPage = isRefresh ? 1 : currentPage;
    _currentFilter.page = startPage;

    _logger.i(
      'Ürünler getiriliyor. Yenileme: $isRefresh, Başlangıç Sayfası: ${_currentFilter.page}, Sort: ${_currentFilter.sortType}, Lat: ${_currentFilter.userLat}, Long: ${_currentFilter.userLong}',
    );

    try {
      _currentFilter.page = currentPage;
      final response = await _productService.getAllProducts(_currentFilter);

      if (response.success == true && response.data != null) {
        final newProducts = response.data!.products ?? [];

        if (isRefresh && currentPage == 1) {
          products = List.from(newProducts);
          isLoading = false; // Hide initial loader once first page is here
        } else {
          products.addAll(newProducts);
        }

        _logger.i(
          'Sayfa $currentPage: ${newProducts.length} ürün getirildi. Toplam ürün: ${products.length}',
        );

        // Pagination logic
        if (newProducts.isEmpty) {
          isLastPage = true;
        } else {
          // Check total pages if available
          if (response.data!.totalPages != null &&
              currentPage >= response.data!.totalPages!) {
            isLastPage = true;
          } else {
            // Prepare for next page
            currentPage++;
          }
        }
        notifyListeners(); // Notify for each page loaded
      } else {
        errorMessage = response.message ?? "Veri alınamadı";
        _logger.w('Ürün getirme başarısız (Sayfa $currentPage): $errorMessage');
      }
    } catch (e, stackTrace) {
      if (e is EndOfListException) {
        _logger.i('Ürün listesinin sonuna ulaşıldı (Status 410).');
        isLastPage = true;
      } else if (e is BusinessException) {
        errorMessage = e.message;
        _logger.w('Ürünleri getirirken iş mantığı hatası: $errorMessage');
      } else {
        errorMessage = "Bir hata oluştu: $e";
        _logger.e(
          'Ürünleri getirirken beklenmedik hata',
          error: e,
          stackTrace: stackTrace,
        );
      }
    } finally {
      isLoading = false;
      isLoadMoreRunning = false;
      notifyListeners();
    }
  }

  void filterByCategory(int? categoryId) {
    _currentFilter.categoryID = categoryId ?? 0;
    fetchProducts(isRefresh: true);
  }

  void loadNextPage() {
    if (!isLastPage && !isLoading && !isLoadMoreRunning) {
      fetchProducts();
    }
  }

  void updateAllFilters({
    String? sortType,
    int? categoryID,
    List<int>? conditionIDs,
    int? cityID,
    int? districtID,
  }) {
    if (sortType != null) _currentFilter.sortType = sortType;
    if (categoryID != null) _currentFilter.categoryID = categoryID;
    if (conditionIDs != null) _currentFilter.conditionIDs = conditionIDs;
    if (cityID != null) _currentFilter.cityID = cityID;
    if (districtID != null) _currentFilter.districtID = districtID;

    _logger.i(
      'Full Filter updated: Sort: $sortType, Cat: $categoryID, Conds: $conditionIDs, Loc: $cityID/$districtID',
    );
    fetchProducts(isRefresh: true);
  }

  String? get userToken => _currentFilter.userToken;

  void setUserToken(String? token, {bool refresh = true}) {
    if (_currentFilter.userToken != token) {
      _currentFilter.userToken = token;
      _logger.i(
        'User token updated in ProductViewModel: $token. Refresh products: $refresh',
      );
      if (refresh) {
        fetchProducts(isRefresh: true);
      }
    }
  }

  Future<void> toggleFavorite(Product product) async {
    final token = _currentFilter.userToken;
    if (token == null || token.isEmpty) {
      _logger.w('Cannot toggle favorite: User not logged in.');
      // Optional: Show "Please login" dialog via UI callback or event
      return;
    }

    // Capture old state for rollback
    final oldState = product.isFavorite;
    // Optimistic update
    product.isFavorite = !(oldState ?? false);
    notifyListeners();

    try {
      if (product.isFavorite == true) {
        await _productService.addFavorite(token, product.productID!);
      } else {
        await _productService.removeFavoriteProduct(token, product.productID!);
      }
      _logger.i('Favorite status updated for product ${product.productID}');
    } catch (e) {
      // Revert on failure
      product.isFavorite = oldState;
      _logger.e('Failed to toggle favorite', error: e);
      errorMessage = "Favori işlemi başarısız oldu.";
      notifyListeners();
    }
  }
}
