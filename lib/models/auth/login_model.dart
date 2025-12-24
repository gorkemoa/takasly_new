class LoginRequestModel {
  final String userEmail;
  final String userPassword;

  LoginRequestModel({required this.userEmail, required this.userPassword});

  Map<String, dynamic> toJson() {
    return {"userEmail": userEmail, "userPassword": userPassword};
  }
}

class LoginResponseModel {
  final int userID;
  final String token;

  LoginResponseModel({required this.userID, required this.token});

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(userID: json['userID'], token: json['token']);
  }
}
