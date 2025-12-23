import 'api_service.dart';
import '../core/constants/api_constants.dart';
import '../models/products/product_models.dart';

class ProductService {
  final ApiService _apiService = ApiService();

  Future<ProductResponseModel> getAllProducts(
    ProductRequestModel request,
  ) async {
    try {
      final response = await _apiService.post(
        ApiConstants.allProductList,
        request.toJson(),
      );
      return ProductResponseModel.fromJson(response);
    } catch (e) {
      // If it's a 410, ApiService throws EndOfListException
      rethrow;
    }
  }
}
