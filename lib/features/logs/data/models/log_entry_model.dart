class LogEntryModel {
  const LogEntryModel({
    required this.device,
    required this.message,
    required this.createdAt,
  });

  final String device;
  final String message;
  final DateTime createdAt;

  factory LogEntryModel.fromJson(Map<String, dynamic> json) {
    return LogEntryModel(
      device: (json['device'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}
