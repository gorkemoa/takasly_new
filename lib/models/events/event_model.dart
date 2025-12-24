class EventModel {
  final int eventID;
  final String eventTitle;
  final String eventDesc;
  final String eventLocation;
  final String eventImage;
  final String eventStartDate;
  final String eventEndDate;
  final String createDate;
  final List<EventImage>? images;

  EventModel({
    required this.eventID,
    required this.eventTitle,
    required this.eventDesc,
    required this.eventLocation,
    required this.eventImage,
    required this.eventStartDate,
    required this.eventEndDate,
    required this.createDate,
    this.images,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      eventID: json['eventID'] is int
          ? json['eventID']
          : int.parse(json['eventID'].toString()),
      eventTitle: json['eventTitle'] ?? '',
      eventDesc: json['eventDesc'] ?? '',
      eventLocation: json['eventLocation'] ?? '',
      eventImage: json['eventImage'] ?? '',
      eventStartDate: json['eventStartDate'] ?? '',
      eventEndDate: json['eventEndDate'] ?? '',
      createDate: json['createDate'] ?? '',
      images: json['images'] != null
          ? (json['images'] as List).map((i) => EventImage.fromJson(i)).toList()
          : null,
    );
  }
}

class EventImage {
  final int imageID;
  final String imagePath;

  EventImage({required this.imageID, required this.imagePath});

  factory EventImage.fromJson(Map<String, dynamic> json) {
    return EventImage(
      imageID: json['imageID'] is int
          ? json['imageID']
          : int.parse(json['imageID'].toString()),
      imagePath: json['imagePath'] ?? '',
    );
  }
}
