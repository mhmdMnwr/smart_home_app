class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.type,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  final String id;

  /// Used as the notification title.
  final String type;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      isRead: json['isread'] == true || json['isRead'] == true,
      createdAt: DateTime.tryParse(
            (json['createdAt'] ?? '').toString(),
          ) ??
          DateTime.now(),
    );
  }
}
