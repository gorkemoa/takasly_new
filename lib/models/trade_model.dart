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
  bool? showButtons;
  String? statusMessage;
  bool? isSender;
  bool? isReceiver;
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
    this.showButtons,
    this.statusMessage,
    this.isSender,
    this.isReceiver,
    this.myProduct,
    this.theirProduct,
  });

  factory Trade.fromJson(Map<String, dynamic> json) {
    bool? toBool(dynamic value) {
      if (value == null) return null;
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) {
        final lower = value.toLowerCase();
        return lower == 'true' || lower == '1';
      }
      return null;
    }

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
      isSenderConfirm: toBool(json['isSenderConfirm']),
      isReceiverConfirm: toBool(json['isReceiverConfirm']),
      isTradeConfirm: toBool(json['isTradeConfirm']),
      isTradeStart: toBool(json['isTradeStart']),
      isSenderReview: toBool(json['isSenderReview']),
      isReceiverReview: toBool(json['isReceiverReview']),
      isTradeRejected: toBool(json['isTradeRejected']),
      showButtons: toBool(json['showButtons']),
      statusMessage: json['statusMessage'] ?? json['message'],
      isSender: toBool(json['isSender']),
      isReceiver: toBool(json['isReceiver']),
      myProduct: json['myProduct'] != null
          ? Product.fromJson(json['myProduct'])
          : null,
      theirProduct: json['theirProduct'] != null
          ? Product.fromJson(json['theirProduct'])
          : null,
    );
  }
}

class StartTradeRequestModel {
  final String userToken;
  final int senderProductID;
  final int receiverProductID;
  final int deliveryTypeID;
  final String? meetingLocation;

  StartTradeRequestModel({
    required this.userToken,
    required this.senderProductID,
    required this.receiverProductID,
    required this.deliveryTypeID,
    this.meetingLocation,
  });

  Map<String, dynamic> toJson() {
    return {
      "userToken": userToken,
      "senderProductID": senderProductID,
      "receiverProductID": receiverProductID,
      "deliveryTypeID": deliveryTypeID,
      "meetingLocation": meetingLocation,
    };
  }
}

class ConfirmTradeRequestModel {
  final String userToken;
  final int offerID;
  final int isConfirm; // 1 for confirm, 0 for reject
  final String? cancelDesc;

  ConfirmTradeRequestModel({
    required this.userToken,
    required this.offerID,
    required this.isConfirm,
    this.cancelDesc,
  });

  Map<String, dynamic> toJson() {
    return {
      "userToken": userToken,
      "offerID": offerID,
      "isConfirm": isConfirm,
      "cancelDesc": cancelDesc ?? "",
    };
  }
}
