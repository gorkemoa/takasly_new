import 'package:flutter/material.dart';
import '../models/products/product_models.dart';
import '../services/product_service.dart';
import '../services/api_service.dart';

class ProductViewModel extends ChangeNotifier {
  final ProductService _productService = ProductService();

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
    if (isLoading && isRefresh)
      return; // Don't refresh if already loading initial
    if (isLoadMoreRunning && !isRefresh)
      return; // Don't load more if already loading more
    if (!isRefresh && isLastPage) return;

    if (isRefresh) {
      isLoading = true;
      isLastPage = false;
      currentPage = 1;
      errorMessage = null;
      notifyListeners();
    } else {
      isLoadMoreRunning = true;
      notifyListeners();
    }

    _currentFilter.page = isRefresh ? 1 : currentPage;

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
      } else {
        errorMessage = response.message ?? "Veri alınamadı";
      }
    } catch (e) {
      if (e is EndOfListException) {
        isLastPage = true;
      } else if (e is BusinessException) {
        errorMessage = e.message;
      } else {
        errorMessage = "Bir hata oluştu: $e";
        debugPrint(e.toString());
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
