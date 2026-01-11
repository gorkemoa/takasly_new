class TicketListResponse {
  bool? error;
  bool? success;
  TicketData? data;
  String? message;

  TicketListResponse({this.error, this.success, this.data, this.message});

  TicketListResponse.fromJson(Map<String, dynamic> json) {
    error = json['error'];
    success = json['success'];
    data = json['data'] != null ? TicketData.fromJson(json['data']) : null;
    message =
        json['410']; // Handle "Gone" message if present at top level or check standard error message field
    if (message == null && json['message'] != null) {
      message = json['message'];
    }
  }

  static String? _fixUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http')) return url;
    return 'https://takasly.tr/$url';
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['error'] = error;
    data['success'] = success;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class TicketData {
  int? page;
  int? pageSize;
  int? totalPages;
  int? totalItems;
  bool? hasNextPage;
  String? emptyMessage;
  List<Ticket>? tickets;

  TicketData({
    this.page,
    this.pageSize,
    this.totalPages,
    this.totalItems,
    this.hasNextPage,
    this.emptyMessage,
    this.tickets,
  });

  TicketData.fromJson(Map<String, dynamic> json) {
    page = json['page'];
    pageSize = json['pageSize'];
    totalPages = json['totalPages'];
    totalItems = json['totalItems'];
    hasNextPage = json['hasNextPage'];
    emptyMessage = json['emptyMessage'];
    if (json['tickets'] != null) {
      tickets = <Ticket>[];
      json['tickets'].forEach((v) {
        tickets!.add(Ticket.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['page'] = page;
    data['pageSize'] = pageSize;
    data['totalPages'] = totalPages;
    data['totalItems'] = totalItems;
    data['hasNextPage'] = hasNextPage;
    data['emptyMessage'] = emptyMessage;
    if (tickets != null) {
      data['tickets'] = tickets!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Ticket {
  int? ticketID;
  String? ticketStatus;
  int? otherUserID;
  String? otherFullname;
  String? otherPhoto;
  String? otherProfilePhoto;
  String? productTitle;
  String? productImage;
  int? productID;
  int? offerID;
  String? lastMessage;
  String? lastMessageCreatedAt;
  String? lastMessageAt;
  int? unreadCount;
  bool? isUnread;
  bool? isAdmin;

  Ticket({
    this.ticketID,
    this.ticketStatus,
    this.otherUserID,
    this.otherFullname,
    this.otherPhoto,
    this.otherProfilePhoto,
    this.productTitle,
    this.productImage,
    this.productID,
    this.offerID,
    this.lastMessage,
    this.lastMessageCreatedAt,
    this.lastMessageAt,
    this.unreadCount,
    this.isUnread,
    this.isAdmin,
  });

  Ticket.fromJson(Map<String, dynamic> json) {
    ticketID = json['ticketID'];
    ticketStatus = json['ticketStatus'];
    otherUserID = json['otherUserID'];
    otherFullname = json['otherFullname'];
    otherPhoto = TicketListResponse._fixUrl(json['otherPhoto']);
    otherProfilePhoto = TicketListResponse._fixUrl(json['otherProfilePhoto']);
    productTitle = json['productTitle'];
    productImage = TicketListResponse._fixUrl(json['productImage']);
    productID = json['productID'];
    offerID = json['offerID'];
    lastMessage = json['lastMessage'];
    lastMessageCreatedAt = json['lastMessageCreatedAt'];
    lastMessageAt = json['lastMessageAt'];
    unreadCount = json['unreadCount'];
    isUnread = json['isUnread'];
    isAdmin = json['isAdmin'] == true || json['isAdmin'] == 1;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['ticketID'] = ticketID;
    data['ticketStatus'] = ticketStatus;
    data['otherUserID'] = otherUserID;
    data['otherFullname'] = otherFullname;
    data['otherPhoto'] = otherPhoto;
    data['otherProfilePhoto'] = otherProfilePhoto;
    data['productTitle'] = productTitle;
    data['productImage'] = productImage;
    data['productID'] = productID;
    data['offerID'] = offerID;
    data['lastMessage'] = lastMessage;
    data['lastMessageCreatedAt'] = lastMessageCreatedAt;
    data['lastMessageAt'] = lastMessageAt;
    data['unreadCount'] = unreadCount;
    data['isUnread'] = isUnread;
    data['isAdmin'] = isAdmin;
    return data;
  }
}

class TicketMessagesResponse {
  bool? error;
  bool? success;
  TicketMessageData? data;
  String? message;

  TicketMessagesResponse({this.error, this.success, this.data, this.message});

  TicketMessagesResponse.fromJson(Map<String, dynamic> json) {
    error = json['error'];
    success = json['success'];
    data = json['data'] != null
        ? TicketMessageData.fromJson(json['data'])
        : null;
    message = json['410'];
    if (message == null && json['message'] != null) {
      message = json['message'];
    }
  }
}

class TicketMessageData {
  int? page;
  int? pageSize;
  int? totalPages;
  int? totalItems;
  bool? hasNextPage;
  String? emptyMessage;
  List<TicketMessage>? messages;

  TicketMessageData({
    this.page,
    this.pageSize,
    this.totalPages,
    this.totalItems,
    this.hasNextPage,
    this.emptyMessage,
    this.messages,
  });

  TicketMessageData.fromJson(Map<String, dynamic> json) {
    page = json['page'];
    pageSize = json['pageSize'];
    totalPages = json['totalPages'];
    totalItems = json['totalItems'];
    hasNextPage = json['hasNextPage'];
    emptyMessage = json['emptyMessage'];
    if (json['messages'] != null) {
      messages = <TicketMessage>[];
      json['messages'].forEach((v) {
        messages!.add(TicketMessage.fromJson(v));
      });
    }
  }
}

class TicketMessage {
  int? messageID;
  int? senderUserID;
  String? senderName;
  String? senderPhoto;
  String? message;
  String? createdAt;
  bool? isMine;
  bool? isAdmin;
  bool? isRead;

  TicketMessage({
    this.messageID,
    this.senderUserID,
    this.senderName,
    this.senderPhoto,
    this.message,
    this.createdAt,
    this.isMine,
    this.isAdmin,
    this.isRead,
  });

  TicketMessage.fromJson(Map<String, dynamic> json) {
    messageID = json['messageID'];
    senderUserID = json['senderUserID'];
    senderName = json['senderName'];
    senderPhoto = TicketListResponse._fixUrl(json['senderPhoto']);
    message = json['message'];
    createdAt = json['createdAt'];
    isMine = json['isMine'];
    isAdmin = json['isAdmin'] == true || json['isAdmin'] == 1;
    isRead = json['isRead'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['messageID'] = messageID;
    data['senderUserID'] = senderUserID;
    data['senderName'] = senderName;
    data['senderPhoto'] = senderPhoto;
    data['message'] = message;
    data['createdAt'] = createdAt;
    data['isMine'] = isMine;
    data['isAdmin'] = isAdmin;
    data['isRead'] = isRead;
    return data;
  }
}

class TicketDetailResponse {
  bool? error;
  bool? success;
  TicketDetailData? data;
  String? message;

  TicketDetailResponse({this.error, this.success, this.data, this.message});

  TicketDetailResponse.fromJson(Map<String, dynamic> json) {
    error = json['error'];
    success = json['success'];
    data = json['data'] != null
        ? TicketDetailData.fromJson(json['data'])
        : null;
    message = json['message'];
  }
}

class TicketDetailData {
  int? ticketID;
  String? ticketStatus;
  TicketProduct? targetProduct;
  TicketProduct? offeredProduct;
  int? otherUserID;
  String? otherFullname;
  String? lastMessage;
  String? lastMessageCreatedAt;
  String? lastMessageAt;
  int? unreadCount;
  bool? isUnread;
  bool? isAdmin;
  String? createdAt;

  TicketDetailData({
    this.ticketID,
    this.ticketStatus,
    this.targetProduct,
    this.offeredProduct,
    this.otherUserID,
    this.otherFullname,
    this.lastMessage,
    this.lastMessageCreatedAt,
    this.lastMessageAt,
    this.unreadCount,
    this.isUnread,
    this.isAdmin,
    this.createdAt,
  });

  TicketDetailData.fromJson(Map<String, dynamic> json) {
    ticketID = json['ticketID'];
    ticketStatus = json['ticketStatus'];
    targetProduct = json['targetProduct'] != null
        ? TicketProduct.fromJson(json['targetProduct'])
        : null;
    offeredProduct = json['offeredProduct'] != null
        ? TicketProduct.fromJson(json['offeredProduct'])
        : null;
    otherUserID = json['otherUserID'];
    otherFullname = json['otherFullname'];
    lastMessage = json['lastMessage'];
    lastMessageCreatedAt = json['lastMessageCreatedAt'];
    lastMessageAt = json['lastMessageAt'];
    unreadCount = json['unreadCount'];
    isUnread = json['isUnread'];
    isAdmin = json['isAdmin'] == true || json['isAdmin'] == 1;
    createdAt = json['createdAt'];
  }
}

class TicketProduct {
  int? productID;
  String? productTitle;
  String? productCode;
  String? productImage;

  TicketProduct({
    this.productID,
    this.productTitle,
    this.productCode,
    this.productImage,
  });

  TicketProduct.fromJson(Map<String, dynamic> json) {
    productID = json['productID'];
    productTitle = json['productTitle'];
    productCode = json['productCode'];
    productImage = TicketListResponse._fixUrl(json['productImage']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['productID'] = productID;
    data['productTitle'] = productTitle;
    data['productCode'] = productCode;
    data['productImage'] = productImage;
    return data;
  }
}
