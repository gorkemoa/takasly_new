import 'package:flutter/material.dart';
import '../models/product_detail_model.dart';
import '../services/api_service.dart';
import 'package:logger/logger.dart';

class ProductDetailViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final Logger _logger = Logger();

  ProductDetail? productDetail;
  bool isLoading = false;
  String? errorMessage;

  Future<void> getProductDetail(int productId, {String? userToken}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.getProductDetail(
        productId,
        userToken: userToken,
      );
      if (response.success == true && response.data?.product != null) {
        productDetail = response.data!.product;
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
}
