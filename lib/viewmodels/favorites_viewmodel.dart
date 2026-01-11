import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../models/products/product_models.dart';
import '../services/product_service.dart';
import '../services/analytics_service.dart';

class FavoritesViewModel extends ChangeNotifier {
  final ProductService _productService = ProductService();
  final Logger _logger = Logger();

  List<Product> favorites = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> fetchFavorites(int userId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final products = await _productService.getUserFavorites(userId);
      favorites = products.map((product) {
        product.isFavorite = true;
        return product;
      }).toList();
      _logger.i(
        'Fetched ${favorites.length} favorite products for user $userId',
      );
    } catch (e) {
      errorMessage = 'Bir hata oluştu: $e';
      _logger.e('Error fetching favorites', error: e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeFavorite(Product product, String userToken) async {
    // Optimistically remove
    final index = favorites.indexOf(product);
    favorites.remove(product);
    notifyListeners();

    try {
      // API call to remove
      await _productService.removeFavoriteProduct(
        userToken,
        product.productID!,
      );
      _logger.i('Removed product ${product.productID} from favorites');
      AnalyticsService().logEvent(
        'remove_favorite',
        parameters: {
          'product_id': product.productID!,
          'from': 'favorites_page',
        },
      );
    } catch (e) {
      // Revert if failed
      if (index != -1) {
        favorites.insert(index, product);
        notifyListeners();
      }
      _logger.e('Failed to remove favorite', error: e);
      // Optional: show error toast via UI callback
    }
  }
}
