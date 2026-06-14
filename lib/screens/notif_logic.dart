class AppNotification {
  final String title;
  final String message;
  final String type;

  AppNotification({
    required this.title,
    required this.message,
    required this.type,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      title: json['alert_type'] ?? 'Alert',
      message: json['message'] ?? '',
      type: json['severity'] ?? 'info',
    );
  }
}