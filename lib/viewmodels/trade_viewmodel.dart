import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../models/trade_model.dart';
import '../models/trade_detail_model.dart';
import '../services/product_service.dart';
import '../services/general_service.dart';
import '../models/general_models.dart';

class TradeViewModel extends ChangeNotifier {
  final ProductService _productService = ProductService();
  final GeneralService _generalService = GeneralService();
  final Logger _logger = Logger();

  List<Trade> trades = [];
  TradeDetailData? currentTradeDetail;
  bool isLoading = false;
  String? errorMessage;
  Map<String, dynamic>? tradeCheckResult;
  final Set<int> _processingOfferIDs = {};
  Set<int> get processingOfferIDs => _processingOfferIDs;

  bool isProcessing(int offerID) => _processingOfferIDs.contains(offerID);

  void _setProcessing(int offerID, bool processing) {
    if (processing) {
      _processingOfferIDs.add(offerID);
    } else {
      _processingOfferIDs.remove(offerID);
    }
    notifyListeners();
  }

  void clearError() {
    if (errorMessage != null) {
      errorMessage = null;
      notifyListeners();
    }
  }

  Future<void> getTrades(int userId, {bool silent = false}) async {
    if (isLoading) return;
    if (!silent) {
      isLoading = true;
      errorMessage = null; // Clears error state on new fetch
      notifyListeners();
    }

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

      // Fetch additional status info for button visibility logic
      if (currentTradeDetail != null &&
          currentTradeDetail!.sender?.product?.productID != null &&
          currentTradeDetail!.receiver?.product?.productID != null) {
        final checkResponse = await _productService.checkTradeStatus(
          userToken: userToken,
          senderProductID: currentTradeDetail!.sender!.product!.productID!,
          receiverProductID: currentTradeDetail!.receiver!.product!.productID!,
        );
        tradeCheckResult = checkResponse['data'];
      }
    } catch (e) {
      errorMessage = 'Bir hata oluştu: $e';
      _logger.e('Error fetching trade detail', error: e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> confirmTrade(ConfirmTradeRequestModel request) async {
    _setProcessing(request.offerID, true);
    errorMessage = null;

    try {
      final message = await _productService.confirmTrade(request);
      _logger.i('Trade ${request.offerID} confirmation: $message');
      return message;
    } finally {
      _setProcessing(request.offerID, false);
    }
  }

  List<TradeStatus> tradeStatuses = [];
  bool isStatusesLoading = false;

  Future<void> fetchTradeStatuses() async {
    if (tradeStatuses.isNotEmpty) return;
    isStatusesLoading = true;
    notifyListeners();
    try {
      tradeStatuses = await _generalService.getTradeStatuses();
    } catch (e) {
      _logger.e('Error fetching trade statuses', error: e);
    } finally {
      isStatusesLoading = false;
      notifyListeners();
    }
  }

  Future<String?> completeTrade(String token, int offerID) async {
    _setProcessing(offerID, true);
    errorMessage = null;

    try {
      final message = await _productService.completeTrade(token, offerID);
      _logger.i('Trade $offerID completed: $message');
      return message;
    } catch (e) {
      _logger.e('Error completing trade', error: e);
      rethrow;
    } finally {
      _setProcessing(offerID, false);
    }
  }

  Future<Map<String, dynamic>> checkTradeStatus({
    required String userToken,
    required int senderProductID,
    required int receiverProductID,
  }) async {
    try {
      final response = await _productService.checkTradeStatus(
        userToken: userToken,
        senderProductID: senderProductID,
        receiverProductID: receiverProductID,
      );
      return response;
    } catch (e) {
      _logger.e('Error checking trade status', error: e);
      rethrow;
    }
  }

  Future<String?> addTradeReview({
    required String userToken,
    required int offerID,
    required int rating,
    String? comment,
  }) async {
    _setProcessing(offerID, true);
    errorMessage = null;

    try {
      final message = await _productService.addTradeReview(
        userToken: userToken,
        offerID: offerID,
        rating: rating,
        comment: comment,
      );
      _logger.i('Trade $offerID review sent: $message');
      return message;
    } catch (e) {
      _logger.e('Error sending trade review', error: e);
      rethrow;
    } finally {
      _setProcessing(offerID, false);
    }
  }
}
