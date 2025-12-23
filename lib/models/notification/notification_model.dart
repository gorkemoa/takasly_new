class NotificationModel {
  final int id;
  final String title;
  final String body;
  final String type;
  final String typeId;
  final String url;
  final bool isRead;
  final String createDate;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.typeId,
    required this.url,
    required this.isRead,
    required this.createDate,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: json['type'] ?? '',
      typeId: json['type_id'] ?? '0',
      url: json['url'] ?? '',
      isRead: json['isRead'] ?? false,
      createDate: json['create_date'] ?? '',
    );
  }
}
