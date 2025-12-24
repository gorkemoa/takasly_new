import 'package:flutter/material.dart';
import '../models/products/product_models.dart';
import '../services/product_service.dart';
import '../services/api_service.dart';

import 'package:logger/logger.dart';

class ProductViewModel extends ChangeNotifier {
  final ProductService _productService = ProductService();
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
    fetchProducts(isRefresh: true);
  }

  Future<void> fetchProducts({bool isRefresh = false}) async {
    if (isLoading && isRefresh) {
      _logger.d('İlk yükleme devam ederken yenileme denendi. İptal ediliyor.');
      return; // Don't refresh if already loading initial
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
      'Ürünler getiriliyor. Yenileme: $isRefresh, Başlangıç Sayfası: ${_currentFilter.page}',
    );

    try {
      bool shouldContinue = true;
      while (shouldContinue) {
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
            shouldContinue = false;
          } else {
            // Check total pages if available
            if (response.data!.totalPages != null &&
                currentPage >= response.data!.totalPages!) {
              isLastPage = true;
              shouldContinue = false;
            } else {
              // Prepare for next page
              currentPage++;
              // If it's not a refresh (e.g. infinite scroll), we only load ONE page at a time
              if (!isRefresh) {
                shouldContinue = false;
              }
            }
          }
          notifyListeners(); // Notify for each page loaded
        } else {
          errorMessage = response.message ?? "Veri alınamadı";
          _logger.w(
            'Ürün getirme başarısız (Sayfa $currentPage): $errorMessage',
          );
          shouldContinue = false;
        }
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

  String? get userToken => _currentFilter.userToken;

  void setUserToken(String? token) {
    if (_currentFilter.userToken != token) {
      _currentFilter.userToken = token;
      _logger.i('User token updated in ProductViewModel: $token');
      // Refresh products with new token
      fetchProducts(isRefresh: true);
    }
  }
}
