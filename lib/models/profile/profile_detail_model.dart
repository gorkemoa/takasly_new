class ProfileDetailModel {
  final int? userID;
  final String? userFullname;
  final String? userImage;
  final String? memberSince;
  final int? averageRating;
  final int? totalReviews;
  final List<ProfileProduct>? products;
  final List<ProfileReview>? reviews;
  final bool? isApproved;
  final bool? isAdmin;

  ProfileDetailModel({
    this.userID,
    this.userFullname,
    this.userImage,
    this.memberSince,
    this.averageRating,
    this.totalReviews,
    this.products,
    this.reviews,
    this.isApproved,
    this.isAdmin,
  });

  factory ProfileDetailModel.fromJson(Map<String, dynamic> json) {
    return ProfileDetailModel(
      userID: json['userID'],
      userFullname: json['userFullname'],
      userImage: json['userImage'],
      memberSince: json['memberSince'],
      averageRating: json['averageRating'],
      totalReviews: json['totalReviews'],
      products: json['products'] != null
          ? (json['products'] as List)
                .map((i) => ProfileProduct.fromJson(i))
                .toList()
          : null,
      reviews: json['reviews'] != null
          ? (json['reviews'] as List)
                .map((i) => ProfileReview.fromJson(i))
                .toList()
          : null,
      isApproved: json['isApproved'],
      isAdmin: json['isAdmin'] == true || json['isAdmin'] == 1,
    );
  }
}

class ProfileProduct {
  final int? productID;
  final String? productTitle;
  final String? productDesc;
  final String? productImage;
  final String? productCondition;
  final int? conditionID;
  final int? cityID;
  final int? districtID;
  final String? cityTitle;
  final String? districtTitle;
  final List<Category>? categoryList;
  final bool? isFavorite;

  ProfileProduct({
    this.productID,
    this.productTitle,
    this.productDesc,
    this.productImage,
    this.productCondition,
    this.conditionID,
    this.cityID,
    this.districtID,
    this.cityTitle,
    this.districtTitle,
    this.categoryList,
    this.isFavorite,
  });

  factory ProfileProduct.fromJson(Map<String, dynamic> json) {
    return ProfileProduct(
      productID: json['productID'],
      productTitle: json['productTitle'],
      productDesc: json['productDesc'],
      productImage: json['productImage'],
      productCondition: json['productCondition'],
      conditionID: json['conditionID'],
      cityID: json['cityID'],
      districtID: json['districtID'],
      cityTitle: json['cityTitle'],
      districtTitle: json['districtTitle'],
      categoryList: json['categoryList'] != null
          ? (json['categoryList'] as List)
                .map((i) => Category.fromJson(i))
                .toList()
          : null,
      isFavorite: json['isFavorite'],
    );
  }
}

class Category {
  final int? catID;
  final String? catName;

  Category({this.catID, this.catName});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(catID: json['catID'], catName: json['catName']);
  }
}

class ProfileReview {
  final int? reviewID;
  final String? reviewerName;
  final String? reviewerImage;
  final int? rating;
  final String? comment;
  final String? reviewDate;

  ProfileReview({
    this.reviewID,
    this.reviewerName,
    this.reviewerImage,
    this.rating,
    this.comment,
    this.reviewDate,
  });

  factory ProfileReview.fromJson(Map<String, dynamic> json) {
    return ProfileReview(
      reviewID: json['reviewID'],
      reviewerName: json['reviewerName'],
      reviewerImage: json['reviewerImage'],
      rating: json['rating'],
      comment: json['comment'],
      reviewDate: json['reviewDate'],
    );
  }
}
