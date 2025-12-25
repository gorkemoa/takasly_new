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
    return Condition(
      id: json['id'], // Assuming 'id' and 'name' based on typical pattern, verify if possible
      name: json['name'],
    );
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
