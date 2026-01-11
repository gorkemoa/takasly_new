class GetUserRequestModel {
  final String userToken;
  final String platform;
  final String version;

  GetUserRequestModel({
    required this.userToken,
    required this.platform,
    required this.version,
  });

  Map<String, dynamic> toJson() {
    return {'userToken': userToken, 'platform': platform, 'version': version};
  }
}

class GetUserResponseModel {
  final User? user;

  GetUserResponseModel({this.user});

  factory GetUserResponseModel.fromJson(Map<String, dynamic> json) {
    return GetUserResponseModel(
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }
}

class User {
  final int? userID;
  final String? username;
  final String? userFirstname;
  final String? userLastname;
  final String? userFullname;
  final String? userEmail;
  final String? userBirthday;
  final String? userPhone;
  final String? userRank;
  final String? userStatus;
  final String? userGender;
  final String? userToken;
  final String? userPlatform;
  final String? userVersion;
  final String? profilePhoto;
  final String? memberSince;
  final int? averageRating;
  final int? totalReviews;
  final int? totalProducts;
  final int? totalProductsG;
  final int? totalFavorites;
  final bool? isShowContact; // Changed to bool
  final bool? isApproved;
  final bool? isTree;
  final bool? isAdmin;
  final List<Review>? reviews;
  final List<Review>? myReviews;

  User({
    this.userID,
    this.username,
    this.userFirstname,
    this.userLastname,
    this.userFullname,
    this.userEmail,
    this.userBirthday,
    this.userPhone,
    this.userRank,
    this.userStatus,
    this.userGender,
    this.userToken,
    this.userPlatform,
    this.userVersion,
    this.profilePhoto,
    this.memberSince,
    this.averageRating,
    this.totalReviews,
    this.totalProducts,
    this.totalProductsG,
    this.totalFavorites,
    this.isShowContact, // Updated constructor
    this.isApproved,
    this.isTree,
    this.isAdmin,
    this.reviews,
    this.myReviews,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userID: json['userID'],
      username: json['username'],
      userFirstname: json['userFirstname'],
      userLastname: json['userLastname'],
      userFullname: json['userFullname'],
      userEmail: json['userEmail'],
      userBirthday: json['userBirthday'],
      userPhone: json['userPhone'],
      userRank: json['userRank'],
      userStatus: json['userStatus'],
      userGender: json['userGender'],
      userToken: json['userToken'],
      userPlatform: json['userPlatform'],
      userVersion: json['userVersion'],
      profilePhoto: json['profilePhoto'],
      memberSince: json['memberSince'],
      averageRating: json['averageRating'],
      totalReviews: json['totalReviews'],
      totalProducts: json['totalProducts'],
      totalProductsG: json['totalProductsG'],
      totalFavorites: json['totalFavorites'],
      isShowContact:
          json['isShowContact'] == true ||
          json['showContact'] == true ||
          json['isShowContact'] == 1 ||
          json['showContact'] == 1,
      isApproved: json['isApproved'],
      isTree: json['isTree'],
      isAdmin: json['isAdmin'] == true || json['isAdmin'] == 1,
      reviews: json['reviews'] != null
          ? (json['reviews'] as List).map((i) => Review.fromJson(i)).toList()
          : null,
      myReviews: json['myReviews'] != null
          ? (json['myReviews'] as List).map((i) => Review.fromJson(i)).toList()
          : null,
    );
  }
}

class Review {
  final int? reviewID;
  final String? reviewerName;
  final String? reviewerImage;
  final String? revieweeName;
  final String? revieweeImage;
  final int? rating;
  final String? comment;
  final String? reviewDate;

  Review({
    this.reviewID,
    this.reviewerName,
    this.reviewerImage,
    this.revieweeName,
    this.revieweeImage,
    this.rating,
    this.comment,
    this.reviewDate,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      reviewID: json['reviewID'],
      reviewerName: json['reviewerName'],
      reviewerImage: json['reviewerImage'],
      revieweeName: json['revieweeName'], // Field for myReviews
      revieweeImage: json['revieweeImage'], // Field for myReviews
      rating: json['rating'],
      comment: json['comment'],
      reviewDate: json['reviewDate'],
    );
  }
}
