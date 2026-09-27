class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    this.payload,
  });

  final int id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final String? payload;

  AppNotification copyWith({
    int? id,
    String? title,
    String? body,
    DateTime? createdAt,
    bool? isRead,
    String? payload,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      payload: payload ?? this.payload,
    );
  }
}
