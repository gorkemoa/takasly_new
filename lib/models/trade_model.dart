import 'products/product_models.dart';

class TradeResponseModel {
  bool? error;
  bool? success;
  TradeData? data;

  TradeResponseModel({this.error, this.success, this.data});

  factory TradeResponseModel.fromJson(Map<String, dynamic> json) {
    return TradeResponseModel(
      error: json['error'],
      success: json['success'],
      data: json['data'] != null ? TradeData.fromJson(json['data']) : null,
    );
  }
}

class TradeData {
  List<Trade>? trades;

  TradeData({this.trades});

  factory TradeData.fromJson(Map<String, dynamic> json) {
    return TradeData(
      trades: json['trades'] != null
          ? (json['trades'] as List).map((i) => Trade.fromJson(i)).toList()
          : [],
    );
  }
}

class Trade {
  int? offerID;
  int? senderUserID;
  int? receiverUserID;
  int? senderStatusID;
  int? receiverStatusID;
  String? deliveryType;
  String? meetingLocation;
  String? senderStatusTitle;
  String? receiverStatusTitle;
  String? senderCancelDesc;
  String? receiverCancelDesc;
  String? createdAt;
  String? completedAt;
  bool? isSenderConfirm;
  bool? isReceiverConfirm;
  bool? isTradeConfirm;
  bool? isTradeStart;
  bool? isSenderReview;
  bool? isReceiverReview;
  bool? isTradeRejected;
  Product? myProduct;
  Product? theirProduct;

  Trade({
    this.offerID,
    this.senderUserID,
    this.receiverUserID,
    this.senderStatusID,
    this.receiverStatusID,
    this.deliveryType,
    this.meetingLocation,
    this.senderStatusTitle,
    this.receiverStatusTitle,
    this.senderCancelDesc,
    this.receiverCancelDesc,
    this.createdAt,
    this.completedAt,
    this.isSenderConfirm,
    this.isReceiverConfirm,
    this.isTradeConfirm,
    this.isTradeStart,
    this.isSenderReview,
    this.isReceiverReview,
    this.isTradeRejected,
    this.myProduct,
    this.theirProduct,
  });

  factory Trade.fromJson(Map<String, dynamic> json) {
    return Trade(
      offerID: json['offerID'],
      senderUserID: json['senderUserID'],
      receiverUserID: json['receiverUserID'],
      senderStatusID: json['senderStatusID'],
      receiverStatusID: json['receiverStatusID'],
      deliveryType: json['deliveryType'],
      meetingLocation: json['meetingLocation'],
      senderStatusTitle: json['senderStatusTitle'],
      receiverStatusTitle: json['receiverStatusTitle'],
      senderCancelDesc: json['senderCancelDesc'],
      receiverCancelDesc: json['receiverCancelDesc'],
      createdAt: json['createdAt'],
      completedAt: json['completedAt'],
      isSenderConfirm: json['isSenderConfirm'],
      isReceiverConfirm: json['isReceiverConfirm'],
      isTradeConfirm: json['isTradeConfirm'],
      isTradeStart: json['isTradeStart'],
      isSenderReview: json['isSenderReview'],
      isReceiverReview: json['isReceiverReview'],
      isTradeRejected: json['isTradeRejected'],
      myProduct: json['myProduct'] != null
          ? Product.fromJson(json['myProduct'])
          : null,
      theirProduct: json['theirProduct'] != null
          ? Product.fromJson(json['theirProduct'])
          : null,
    );
  }
}
