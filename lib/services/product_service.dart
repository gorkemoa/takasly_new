import 'api_service.dart';
import '../core/constants/api_constants.dart';
import '../models/products/product_models.dart';
import '../models/trade_model.dart';
import '../models/product_detail_model.dart';
import '../models/trade_detail_model.dart';

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

  Future<ProductDetailModel> getProductDetail(
    int productId, {
    String? userToken,
  }) async {
    try {
      String url = '${ApiConstants.productDetail}$productId/productDetail';
      if (userToken != null && userToken.isNotEmpty) {
        url += '?userToken=$userToken';
      }
      final response = await _apiService.get(url);
      // The _handleResponse returns dynamic (Map<String, dynamic>), so we parse it here
      return ProductDetailModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Product>> getUserFavorites(int userId) async {
    try {
      final response = await _apiService.get(
        '${ApiConstants.favoriteList}$userId/favoriteList',
      );

      final result = ProductResponseModel.fromJson(response);

      if (result.success == true && result.data?.products != null) {
        return result.data!.products!;
      } else {
        return [];
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Trade>> getUserTrades(int userId) async {
    try {
      final response = await _apiService.get(
        '${ApiConstants.tradeList}$userId/tradeList',
      );

      final result = TradeResponseModel.fromJson(response);

      if (result.success == true && result.data?.trades != null) {
        return result.data!.trades!;
      } else {
        return [];
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addFavorite(String userToken, int productId) async {
    try {
      final payload = {"userToken": userToken, "productID": productId};
      await _apiService.post(ApiConstants.addFavorite, payload);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeFavoriteProduct(String userToken, int productId) async {
    try {
      final payload = {"userToken": userToken, "productID": productId};
      await _apiService.post(ApiConstants.removeFavorite, payload);
    } catch (e) {
      rethrow;
    }
  }

  Future<TradeDetailData> getTradeDetail(int offerId, String userToken) async {
    try {
      final response = await _apiService.get(
        '${ApiConstants.tradeList}$offerId/tradeDetail?userToken=$userToken',
      );

      final result = TradeDetailResponseModel.fromJson(response);

      if (result.success == true && result.data != null) {
        return result.data!; // Return the TradeDetailData object
      } else {
        throw Exception('Takas detayı yüklenemedi.');
      }
    } catch (e) {
      rethrow;
    }
  }
}
