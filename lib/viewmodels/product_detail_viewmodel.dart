import 'package:flutter/material.dart';
import '../models/product_detail_model.dart';
import '../services/product_service.dart';
import 'package:logger/logger.dart';
import '../services/analytics_service.dart';
import '../models/user/report_user_model.dart';

class ProductDetailViewModel extends ChangeNotifier {
  final ProductService _productService = ProductService();
  final Logger _logger = Logger();

  ProductDetail? productDetail;
  bool isLoading = false;
  String? errorMessage;

  Future<void> getProductDetail(int productId, {String? userToken}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await _productService.getProductDetail(
        productId,
        userToken: userToken,
      );
      if (response.success == true && response.data?.product != null) {
        productDetail = response.data!.product;
        // Log view item
        if (productDetail != null) {
          AnalyticsService().logViewItem(
            itemId: productDetail!.productID.toString(),
            itemName: productDetail!.productTitle ?? 'Unknown',
            itemCategory: productDetail!.categoryList?.isNotEmpty == true
                ? productDetail!.categoryList!.first.catName ?? 'Unknown'
                : 'Unknown',
          );
        }
      } else {
        errorMessage = "Ürün detayları alınamadı.";
      }
    } catch (e) {
      _logger.e('Ürün detayı getirilirken hata oluştu', error: e);
      errorMessage = "Bir hata oluştu: $e";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteProduct(String userToken, int userId) async {
    if (productDetail?.productID == null) return false;

    isLoading = true;
    notifyListeners();

    try {
      await _productService.deleteProduct(
        userToken,
        userId,
        productDetail!.productID!,
      );
      AnalyticsService().logEvent(
        'delete_product',
        parameters: {'product_id': productDetail!.productID!, 'from': 'detail'},
      );
      productDetail = null;
      return true;
    } catch (e) {
      _logger.e('Ürün silinirken hata oluştu', error: e);
      errorMessage = "Ürün silinemedi: $e";
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(String userToken) async {
    if (productDetail?.productID == null) return;

    // Capture old state for rollback
    final oldState = productDetail?.isFavorite;
    // Optimistic update
    productDetail?.isFavorite = !(oldState ?? false);
    notifyListeners();

    try {
      if (productDetail?.isFavorite == true) {
        await _productService.addFavorite(userToken, productDetail!.productID!);
        AnalyticsService().logAddToWishlist(
          itemId: productDetail!.productID.toString(),
          itemCategory: productDetail!.categoryList?.isNotEmpty == true
              ? productDetail!.categoryList!.first.catName ?? 'Unknown'
              : 'Unknown',
        );
      } else {
        await _productService.removeFavoriteProduct(
          userToken,
          productDetail!.productID!,
        );
        AnalyticsService().logEvent(
          'remove_favorite',
          parameters: {'product_id': productDetail!.productID!},
        );
      }
      _logger.i(
        'Favorite status updated for product ${productDetail!.productID}',
      );
    } catch (e) {
      // Revert on failure
      productDetail?.isFavorite = oldState;
      _logger.e('Failed to toggle favorite', error: e);
      errorMessage = "Favori işlemi başarısız oldu.";
      notifyListeners();
    }
  }

  Future<bool> reportProduct({
    required String userToken,
    required String reason,
    required String step,
  }) async {
    if (productDetail == null || productDetail!.userID == null) return false;

    try {
      final request = ReportUserRequest(
        userToken: userToken,
        reportedUserID: productDetail!.userID!,
        reason: reason,
        step: step,
        productID: productDetail!.productID,
      );
      await _productService.reportUser(request);
      AnalyticsService().logEvent(
        'report_product',
        parameters: {
          'reported_user_id': productDetail!.userID!,
          'product_id': productDetail!.productID!,
          'reason': reason,
          'step': step,
        },
      );
      return true;
    } catch (e) {
      _logger.e("Report Product Hata", error: e);
      return false;
    }
  }
}
