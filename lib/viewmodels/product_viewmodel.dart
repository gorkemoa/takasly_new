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

    _currentFilter.page = isRefresh ? 1 : currentPage;

    _logger.i(
      'Ürünler getiriliyor. Yenileme: $isRefresh, Sayfa: ${_currentFilter.page}',
    );

    try {
      final response = await _productService.getAllProducts(_currentFilter);

      if (response.success == true && response.data != null) {
        final newProducts = response.data!.products ?? [];

        if (isRefresh) {
          products = newProducts;
        } else {
          products.addAll(newProducts);
        }

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
        _logger.i(
          '${newProducts.length} ürün getirildi. Toplam ürün: ${products.length}',
        );
      } else {
        errorMessage = response.message ?? "Veri alınamadı";
        _logger.w('Ürün getirme başarısız: $errorMessage');
      }
    } catch (e, stackTrace) {
      if (e is EndOfListException) {
        _logger.i('Ürün listesinin sonuna ulaşıldı.');
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

  void loadNextPage() {
    if (!isLastPage && !isLoading && !isLoadMoreRunning) {
      fetchProducts();
    }
  }
}
