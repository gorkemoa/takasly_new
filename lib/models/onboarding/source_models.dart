class OnboardingSource {
  final int sourceID;
  final String sourceTitle;

  OnboardingSource({required this.sourceID, required this.sourceTitle});

  factory OnboardingSource.fromJson(Map<String, dynamic> json) {
    return OnboardingSource(
      sourceID: json['sourceID'] ?? 0,
      sourceTitle: json['sourceTitle'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'sourceID': sourceID, 'sourceTitle': sourceTitle};
  }
}

class AddSourceRequestModel {
  final int sourceTypeID;
  final String sourceType;
  final String platform;
  final String userAgent;

  AddSourceRequestModel({
    required this.sourceTypeID,
    required this.sourceType,
    required this.platform,
    required this.userAgent,
  });

  Map<String, dynamic> toJson() {
    return {
      'sourceTypeID': sourceTypeID,
      'sourceType': sourceType,
      'platform': platform,
      'userAgent': userAgent,
    };
  }
}
