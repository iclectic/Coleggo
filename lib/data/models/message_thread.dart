enum MessageThreadType { commuteCircle, acceptedCommute, journey }

enum MessageDeliveryState { stored, flagged, removed }

enum ModerationReportStatus { submitted, reviewed, dismissed }

class CommuteMessage {
  const CommuteMessage({
    required this.id,
    required this.threadId,
    required this.senderProfileId,
    required this.body,
    required this.sentAt,
    this.deliveryState = MessageDeliveryState.stored,
  });

  final String id;
  final String threadId;
  final String senderProfileId;
  final String body;
  final DateTime sentAt;
  final MessageDeliveryState deliveryState;

  CommuteMessage copyWith({MessageDeliveryState? deliveryState}) =>
      CommuteMessage(
        id: id,
        threadId: threadId,
        senderProfileId: senderProfileId,
        body: body,
        sentAt: sentAt,
        deliveryState: deliveryState ?? this.deliveryState,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'threadId': threadId,
    'senderProfileId': senderProfileId,
    'body': body,
    'sentAt': sentAt.toIso8601String(),
    'deliveryState': deliveryState.name,
  };

  factory CommuteMessage.fromJson(Map<String, dynamic> json) => CommuteMessage(
    id: json['id'] as String,
    threadId: json['threadId'] as String,
    senderProfileId: json['senderProfileId'] as String,
    body: json['body'] as String,
    sentAt: DateTime.parse(json['sentAt'] as String),
    deliveryState: MessageDeliveryState.values.byName(
      json['deliveryState'] as String? ?? MessageDeliveryState.stored.name,
    ),
  );
}

class MessageThread {
  const MessageThread({
    required this.id,
    required this.type,
    required this.contextId,
    required this.participantProfileIds,
    required this.messages,
    required this.createdAt,
    this.archived = false,
  });

  final String id;
  final MessageThreadType type;
  final String contextId;
  final List<String> participantProfileIds;
  final List<CommuteMessage> messages;
  final DateTime createdAt;
  final bool archived;

  bool canAccess(String profileId) => participantProfileIds.contains(profileId);

  MessageThread copyWith({List<CommuteMessage>? messages, bool? archived}) =>
      MessageThread(
        id: id,
        type: type,
        contextId: contextId,
        participantProfileIds: participantProfileIds,
        messages: messages ?? this.messages,
        createdAt: createdAt,
        archived: archived ?? this.archived,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'contextId': contextId,
    'participantProfileIds': participantProfileIds,
    'messages': messages.map((message) => message.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'archived': archived,
  };

  factory MessageThread.fromJson(Map<String, dynamic> json) => MessageThread(
    id: json['id'] as String,
    type: MessageThreadType.values.byName(json['type'] as String),
    contextId: json['contextId'] as String,
    participantProfileIds: (json['participantProfileIds'] as List<dynamic>)
        .cast<String>(),
    messages: (json['messages'] as List<dynamic>? ?? const [])
        .map(
          (message) => CommuteMessage.fromJson(message as Map<String, dynamic>),
        )
        .toList(),
    createdAt: DateTime.parse(json['createdAt'] as String),
    archived: json['archived'] as bool? ?? false,
  );
}

class MessageModerationReport {
  const MessageModerationReport({
    required this.id,
    required this.threadId,
    required this.messageId,
    required this.reporterProfileId,
    required this.reason,
    required this.createdAt,
    this.status = ModerationReportStatus.submitted,
  });

  final String id;
  final String threadId;
  final String messageId;
  final String reporterProfileId;
  final String reason;
  final DateTime createdAt;
  final ModerationReportStatus status;

  Map<String, dynamic> toJson() => {
    'id': id,
    'threadId': threadId,
    'messageId': messageId,
    'reporterProfileId': reporterProfileId,
    'reason': reason,
    'createdAt': createdAt.toIso8601String(),
    'status': status.name,
  };

  factory MessageModerationReport.fromJson(Map<String, dynamic> json) =>
      MessageModerationReport(
        id: json['id'] as String,
        threadId: json['threadId'] as String,
        messageId: json['messageId'] as String,
        reporterProfileId: json['reporterProfileId'] as String,
        reason: json['reason'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        status: ModerationReportStatus.values.byName(
          json['status'] as String? ?? ModerationReportStatus.submitted.name,
        ),
      );
}
