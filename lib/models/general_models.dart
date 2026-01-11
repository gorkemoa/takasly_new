class City {
  int? cityNo;
  String? cityName;

  City({this.cityNo, this.cityName});

  factory City.fromJson(Map<String, dynamic> json) {
    return City(cityNo: json['cityNo'], cityName: json['cityName']);
  }
}

class District {
  int? districtNo;
  String? districtName;

  District({this.districtNo, this.districtName});

  factory District.fromJson(Map<String, dynamic> json) {
    return District(
      districtNo: json['districtNo'],
      districtName: json['districtName'],
    );
  }
}

class Condition {
  int? id;
  String? name;

  Condition({this.id, this.name});

  factory Condition.fromJson(Map<String, dynamic> json) {
    return Condition(id: json['conditionID'], name: json['conditionName']);
  }
}

class ContactSubject {
  int? subjectID;
  String? subjectTitle;

  ContactSubject({this.subjectID, this.subjectTitle});

  factory ContactSubject.fromJson(Map<String, dynamic> json) {
    return ContactSubject(
      subjectID: json['subjectID'],
      subjectTitle: json['subjectTitle'],
    );
  }
}

class DeliveryType {
  int? deliveryID;
  String? deliveryTitle;

  DeliveryType({this.deliveryID, this.deliveryTitle});

  factory DeliveryType.fromJson(Map<String, dynamic> json) {
    return DeliveryType(
      deliveryID: json['deliveryID'],
      deliveryTitle: json['deliveryTitle'],
    );
  }
}

class TradeStatus {
  int? statusID;
  String? statusTitle;

  TradeStatus({this.statusID, this.statusTitle});

  factory TradeStatus.fromJson(Map<String, dynamic> json) {
    return TradeStatus(
      statusID: json['statusID'],
      statusTitle: json['statusTitle'],
    );
  }
}

class Contract {
  int? id;
  String? title;
  String? desc;

  Contract({this.id, this.title, this.desc});

  factory Contract.fromJson(Map<String, dynamic> json) {
    return Contract(id: json['id'], title: json['title'], desc: json['desc']);
  }
}

class Popup {
  int? popupID;
  String? popupTitle;
  String? popupDesc;
  int? popupView;
  String? popupLink;
  String? popupImage;
  String? popupStartDate;
  String? popupEndDate;

  Popup({
    this.popupID,
    this.popupTitle,
    this.popupDesc,
    this.popupView,
    this.popupLink,
    this.popupImage,
    this.popupStartDate,
    this.popupEndDate,
  });

  factory Popup.fromJson(Map<String, dynamic> json) {
    return Popup(
      popupID: json['popupID'],
      popupTitle: json['popupTitle'],
      popupDesc: json['popupDesc'],
      popupView: json['popupView'],
      popupLink: json['popupLink'],
      popupImage: json['popupImage'],
      popupStartDate: json['popupStartDate'],
      popupEndDate: json['popupEndDate'],
    );
  }
}
