class CodeControlRequestModel {
  final String code;
  final String codeToken;

  CodeControlRequestModel({required this.code, required this.codeToken});

  Map<String, dynamic> toJson() {
    return {"code": code, "codeToken": codeToken};
  }
}

class CodeControlResponseModel {
  final String? passToken;

  CodeControlResponseModel({this.passToken});

  factory CodeControlResponseModel.fromJson(Map<String, dynamic> json) {
    return CodeControlResponseModel(passToken: json['passToken']);
  }
}

class ResendCodeRequestModel {
  final String userToken;

  ResendCodeRequestModel({required this.userToken});

  Map<String, dynamic> toJson() {
    return {"userToken": userToken};
  }
}

class ResendCodeResponseModel {
  final String codeToken;

  ResendCodeResponseModel({required this.codeToken});

  factory ResendCodeResponseModel.fromJson(Map<String, dynamic> json) {
    return ResendCodeResponseModel(codeToken: json['codeToken']);
  }
}
