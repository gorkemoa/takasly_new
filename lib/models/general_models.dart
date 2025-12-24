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
