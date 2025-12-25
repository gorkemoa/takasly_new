import 'products/product_models.dart';

class TradeDetailResponseModel {
  bool? error;
  bool? success;
  TradeDetailData? data;

  TradeDetailResponseModel({this.error, this.success, this.data});

  factory TradeDetailResponseModel.fromJson(Map<String, dynamic> json) {
    return TradeDetailResponseModel(
      error: json['error'],
      success: json['success'],
      data: json['data'] != null
          ? TradeDetailData.fromJson(json['data'])
          : null,
    );
  }
}

class TradeDetailData {
  int? offerID;
  int? senderUserID;
  int? receiverUserID;
  int? senderStatusID;
  int? receiverStatusID;
  String? senderStatusTitle;
  String? receiverStatusTitle;
  int? deliveryTypeID;
  String? deliveryTypeTitle;
  String? meetingLocation;
  String? senderCancelDesc;
  String? receiverCancelDesc;
  String? createdAt;
  String? completedAt;
  bool? isSenderConfirm;
  bool? isReceiverConfirm;
  bool? isTradeConfirm;
  bool? isTradeStart;
  bool? isTradeRejected;
  TradeUser? sender;
  TradeUser? receiver;

  TradeDetailData({
    this.offerID,
    this.senderUserID,
    this.receiverUserID,
    this.senderStatusID,
    this.receiverStatusID,
    this.senderStatusTitle,
    this.receiverStatusTitle,
    this.deliveryTypeID,
    this.deliveryTypeTitle,
    this.meetingLocation,
    this.senderCancelDesc,
    this.receiverCancelDesc,
    this.createdAt,
    this.completedAt,
    this.isSenderConfirm,
    this.isReceiverConfirm,
    this.isTradeConfirm,
    this.isTradeStart,
    this.isTradeRejected,
    this.sender,
    this.receiver,
  });

  factory TradeDetailData.fromJson(Map<String, dynamic> json) {
    return TradeDetailData(
      offerID: json['offerID'],
      senderUserID: json['senderUserID'],
      receiverUserID: json['receiverUserID'],
      senderStatusID: json['senderStatusID'],
      receiverStatusID: json['receiverStatusID'],
      senderStatusTitle: json['senderStatusTitle'],
      receiverStatusTitle: json['receiverStatusTitle'],
      deliveryTypeID: json['deliveryTypeID'],
      deliveryTypeTitle: json['deliveryTypeTitle'],
      meetingLocation: json['meetingLocation'],
      senderCancelDesc: json['senderCancelDesc'],
      receiverCancelDesc: json['receiverCancelDesc'],
      createdAt: json['createdAt'],
      completedAt: json['completedAt'],
      isSenderConfirm: json['isSenderConfirm'],
      isReceiverConfirm: json['isReceiverConfirm'],
      isTradeConfirm: json['isTradeConfirm'],
      isTradeStart: json['isTradeStart'],
      isTradeRejected: json['isTradeRejected'],
      sender: json['sender'] != null
          ? TradeUser.fromJson(json['sender'])
          : null,
      receiver: json['receiver'] != null
          ? TradeUser.fromJson(json['receiver'])
          : null,
    );
  }
}

class TradeUser {
  int? userID;
  String? userName;
  String? profilePhoto;
  Product? product;

  TradeUser({this.userID, this.userName, this.profilePhoto, this.product});

  factory TradeUser.fromJson(Map<String, dynamic> json) {
    return TradeUser(
      userID: json['userID'],
      userName: json['userName'],
      profilePhoto: json['profilePhoto'],
      product: json['product'] != null
          ? Product.fromJson(json['product'])
          : null,
    );
  }
}
