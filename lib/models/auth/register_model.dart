class RegisterRequestModel {
  final String userFirstname;
  final String userLastname;
  final String userEmail;
  final String userPhone;
  final String userPassword;
  final String version;
  final String platform;
  final bool policy;
  final bool kvkk;

  RegisterRequestModel({
    required this.userFirstname,
    required this.userLastname,
    required this.userEmail,
    required this.userPhone,
    required this.userPassword,
    required this.version,
    required this.platform,
    required this.policy,
    required this.kvkk,
  });

  Map<String, dynamic> toJson() {
    return {
      "userFirstname": userFirstname,
      "userLastname": userLastname,
      "userEmail": userEmail,
      "userPhone": userPhone,
      "userPassword": userPassword,
      "version": version,
      "platform": platform,
      "policy": policy,
      "kvkk": kvkk,
    };
  }
}

class RegisterResponseModel {
  final int userID;
  final String userToken;
  final String codeToken;

  RegisterResponseModel({
    required this.userID,
    required this.userToken,
    required this.codeToken,
  });

  factory RegisterResponseModel.fromJson(Map<String, dynamic> json) {
    return RegisterResponseModel(
      userID: json['userID'],
      userToken: json['userToken'],
      codeToken: json['codeToken'],
    );
  }
}
