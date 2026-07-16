enum CommuteNotificationType {
  journeyConfirmation,
  joinRequest,
  cancellation,
  backupDriver,
  message,
}

enum CommuteNotificationPriority { normal, actionRequired, urgent }

class CommuteNotification {
  const CommuteNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.contextRoute,
    this.read = false,
    this.priority = CommuteNotificationPriority.normal,
  });

  final String id;
  final CommuteNotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final String? contextRoute;
  final bool read;
  final CommuteNotificationPriority priority;

  CommuteNotification copyWith({bool? read}) => CommuteNotification(
    id: id,
    type: type,
    title: title,
    body: body,
    createdAt: createdAt,
    contextRoute: contextRoute,
    read: read ?? this.read,
    priority: priority,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'title': title,
    'body': body,
    'createdAt': createdAt.toIso8601String(),
    'contextRoute': contextRoute,
    'read': read,
    'priority': priority.name,
  };

  factory CommuteNotification.fromJson(Map<String, dynamic> json) =>
      CommuteNotification(
        id: json['id'] as String,
        type: CommuteNotificationType.values.byName(json['type'] as String),
        title: json['title'] as String,
        body: json['body'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        contextRoute: json['contextRoute'] as String?,
        read: json['read'] as bool? ?? false,
        priority: CommuteNotificationPriority.values.byName(
          json['priority'] as String? ??
              CommuteNotificationPriority.normal.name,
        ),
      );
}
