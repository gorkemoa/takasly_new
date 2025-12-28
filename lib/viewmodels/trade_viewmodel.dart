import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../models/trade_model.dart';
import '../models/trade_detail_model.dart';
import '../services/product_service.dart';

class TradeViewModel extends ChangeNotifier {
  final ProductService _productService = ProductService();
  final Logger _logger = Logger();

  List<Trade> trades = [];
  TradeDetailData? currentTradeDetail;
  bool isLoading = false;
  String? errorMessage;

  Future<void> getTrades(int userId) async {
    if (isLoading) return;
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      trades = await _productService.getUserTrades(userId);
      _logger.i('Fetched ${trades.length} trades for user $userId');
    } catch (e) {
      errorMessage = 'Bir hata oluştu: $e';
      _logger.e('Error fetching trades', error: e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getTradeDetail(int offerId, String userToken) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      currentTradeDetail = await _productService.getTradeDetail(
        offerId,
        userToken,
      );
      _logger.i('Fetched trade detail for offer $offerId');
    } catch (e) {
      errorMessage = 'Bir hata oluştu: $e';
      _logger.e('Error fetching trade detail', error: e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
