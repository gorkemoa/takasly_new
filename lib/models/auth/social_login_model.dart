class SocialLoginRequestModel {
  String platform;
  String deviceID;
  String devicePlatform;
  String version;
  String fcmToken;
  String idToken;
  String? email;
  String? firstName;
  String? lastName;

  SocialLoginRequestModel({
    required this.platform,
    required this.deviceID,
    required this.devicePlatform,
    required this.version,
    required this.fcmToken,
    required this.idToken,
    this.email,
    this.firstName,
    this.lastName,
  });

  Map<String, dynamic> toJson() {
    return {
      'platform': platform,
      'deviceID': deviceID,
      'devicePlatform': devicePlatform,
      'version': version,
      'fcmToken': fcmToken,
      'idToken': idToken,
      if (email != null) 'email': email,
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
    };
  }
}
