class ProductRequestModel {
  String? userToken;
  String? searchText;
  int? categoryID;
  List<int>? conditionIDs;
  int? cityID;
  int? districtID;
  String? userLat;
  String? userLong;
  String? sortType;
  int page;

  ProductRequestModel({
    this.userToken,
    this.searchText,
    this.categoryID,
    this.conditionIDs,
    this.cityID,
    this.districtID,
    this.userLat,
    this.userLong,
    this.sortType = "default",
    required this.page,
  });

  Map<String, dynamic> toJson() {
    return {
      "userToken": userToken ?? "",
      "searchText": searchText ?? "",
      "categoryID": categoryID ?? 0,
      "conditionIDs": conditionIDs ?? [],
      "cityID": cityID ?? 0,
      "districtID": districtID ?? 0,
      "userLat": userLat ?? "",
      "userLong": userLong ?? "",
      "sortType": sortType ?? "default",
      "page": page,
    };
  }
}

class ProductResponseModel {
  bool? error;
  bool? success;
  ProductData? data;
  String? message; // In case of 417 or error

  ProductResponseModel({this.error, this.success, this.data, this.message});

  factory ProductResponseModel.fromJson(Map<String, dynamic> json) {
    return ProductResponseModel(
      error: json['error'],
      success: json['success'],
      data: json['data'] != null ? ProductData.fromJson(json['data']) : null,
      message: json['message'], // Capture message if present
    );
  }
}

class ProductData {
  int? page;
  int? pageSize;
  int? totalPages;
  int? totalItems;
  String? emptyMessage;
  List<Product>? products;

  ProductData({
    this.page,
    this.pageSize,
    this.totalPages,
    this.totalItems,
    this.emptyMessage,
    this.products,
  });

  factory ProductData.fromJson(Map<String, dynamic> json) {
    return ProductData(
      page: json['page'],
      pageSize: json['pageSize'],
      totalPages: json['totalPages'],
      totalItems: json['totalItems'],
      emptyMessage: json['emptyMessage'],
      products: json['products'] != null
          ? (json['products'] as List).map((i) => Product.fromJson(i)).toList()
          : [],
    );
  }
}

class Product {
  int? productID;
  String? productCode;
  String? productTitle;
  String? productDesc;
  String? productImage;
  String? productCondition;
  List<Category>? categoryList;
  int? userID;
  int? categoryID;
  int? conditionID;
  int? cityID;
  int? districtID;
  String? cityTitle;
  String? districtTitle;
  String? productLat;
  String? productLong;
  String? userFullname;
  String? userFirstname;
  String? userLastname;
  String? createdAt;
  bool? isFavorite;
  bool? isSponsor;
  bool? isTrade;

  Product({
    this.productID,
    this.productCode,
    this.productTitle,
    this.productDesc,
    this.productImage,
    this.productCondition,
    this.categoryList,
    this.userID,
    this.categoryID,
    this.conditionID,
    this.cityID,
    this.districtID,
    this.cityTitle,
    this.districtTitle,
    this.productLat,
    this.productLong,
    this.userFullname,
    this.userFirstname,
    this.userLastname,
    this.createdAt,
    this.isFavorite,
    this.isSponsor,
    this.isTrade,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      productID: json['productID'],
      productCode: json['productCode'],
      productTitle: json['productTitle'],
      productDesc: json['productDesc'],
      productImage: json['productImage'],
      productCondition: json['productCondition'],
      categoryList: json['categoryList'] != null
          ? (json['categoryList'] as List)
                .map((i) => Category.fromJson(i))
                .toList()
          : [],
      userID: json['userID'],
      categoryID: json['categoryID'],
      conditionID: json['conditionID'],
      cityID: json['cityID'],
      districtID: json['districtID'],
      cityTitle: json['cityTitle'],
      districtTitle: json['districtTitle'],
      productLat: json['productLat'],
      productLong: json['productLong'],
      userFullname: json['userFullname'],
      userFirstname: json['userFirstname'],
      userLastname: json['userLastname'],
      createdAt: json['createdAt'],
      isFavorite: json['isFavorite'],
      isSponsor: json['isSponsor'],
      isTrade: json['isTrade'],
    );
  }
  Product copyWith({
    int? productID,
    String? productCode,
    String? productTitle,
    String? productDesc,
    String? productImage,
    String? productCondition,
    List<Category>? categoryList,
    int? userID,
    int? categoryID,
    int? conditionID,
    int? cityID,
    int? districtID,
    String? cityTitle,
    String? districtTitle,
    String? productLat,
    String? productLong,
    String? userFullname,
    String? userFirstname,
    String? userLastname,
    String? createdAt,
    bool? isFavorite,
    bool? isSponsor,
    bool? isTrade,
    bool? isSold,
  }) {
    return Product(
      productID: productID ?? this.productID,
      productCode: productCode ?? this.productCode,
      productTitle: productTitle ?? this.productTitle,
      productDesc: productDesc ?? this.productDesc,
      productImage: productImage ?? this.productImage,
      productCondition: productCondition ?? this.productCondition,
      categoryList: categoryList ?? this.categoryList,
      userID: userID ?? this.userID,
      categoryID: categoryID ?? this.categoryID,
      conditionID: conditionID ?? this.conditionID,
      cityID: cityID ?? this.cityID,
      districtID: districtID ?? this.districtID,
      cityTitle: cityTitle ?? this.cityTitle,
      districtTitle: districtTitle ?? this.districtTitle,
      productLat: productLat ?? this.productLat,
      productLong: productLong ?? this.productLong,
      userFullname: userFullname ?? this.userFullname,
      userFirstname: userFirstname ?? this.userFirstname,
      userLastname: userLastname ?? this.userLastname,
      createdAt: createdAt ?? this.createdAt,
      isFavorite: isFavorite ?? this.isFavorite,
      isSponsor: isSponsor ?? this.isSponsor,
      isTrade: isTrade ?? this.isTrade,
    );
  }

  String? get categoryTitle {
    if (categoryList == null || categoryList!.isEmpty) return null;
    if (categoryID != null) {
      try {
        final category = categoryList!.firstWhere((c) => c.catID == categoryID);
        return category.catName;
      } catch (_) {
        return categoryList!.first.catName;
      }
    }
    return categoryList!.first.catName;
  }
}

class Category {
  int? catID;
  String? catName;

  Category({this.catID, this.catName});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(catID: json['catID'], catName: json['catName']);
  }
}
