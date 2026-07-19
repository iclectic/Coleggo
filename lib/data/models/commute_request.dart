enum CommuteRequestType {
  requestSeat,
  offerSeat,
  joinCircle,
  inviteToCircle,
  becomeBackupDriver,
}

enum CommuteRequestStatus { pending, accepted, rejected, cancelled, expired }

enum CommuteArrangementIntent { oneOff, recurring }

class CommuteRequest {
  const CommuteRequest({
    required this.id,
    required this.requesterProfileId,
    required this.type,
    required this.status,
    required this.intendedDays,
    required this.windowStartMinutes,
    required this.windowEndMinutes,
    required this.worksiteId,
    required this.seatsRequired,
    required this.intent,
    required this.createdAt,
    required this.expiresAt,
    this.targetProfileId,
    this.circleId,
    this.message,
  });

  final String id;
  final String requesterProfileId;
  final String? targetProfileId;
  final String? circleId;
  final CommuteRequestType type;
  final CommuteRequestStatus status;
  final Set<int> intendedDays;
  final int windowStartMinutes;
  final int windowEndMinutes;
  final String worksiteId;
  final int seatsRequired;
  final String? message;
  final CommuteArrangementIntent intent;
  final DateTime createdAt;
  final DateTime expiresAt;

  bool get isActive =>
      status == CommuteRequestStatus.pending &&
      DateTime.now().isBefore(expiresAt);

  CommuteRequest copyWith({CommuteRequestStatus? status}) => CommuteRequest(
    id: id,
    requesterProfileId: requesterProfileId,
    targetProfileId: targetProfileId,
    circleId: circleId,
    type: type,
    status: status ?? this.status,
    intendedDays: intendedDays,
    windowStartMinutes: windowStartMinutes,
    windowEndMinutes: windowEndMinutes,
    worksiteId: worksiteId,
    seatsRequired: seatsRequired,
    message: message,
    intent: intent,
    createdAt: createdAt,
    expiresAt: expiresAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'requesterProfileId': requesterProfileId,
    'targetProfileId': targetProfileId,
    'circleId': circleId,
    'type': type.name,
    'status': status.name,
    'intendedDays': intendedDays.toList(),
    'windowStartMinutes': windowStartMinutes,
    'windowEndMinutes': windowEndMinutes,
    'worksiteId': worksiteId,
    'seatsRequired': seatsRequired,
    'message': message,
    'intent': intent.name,
    'createdAt': createdAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
  };

  factory CommuteRequest.fromJson(Map<String, dynamic> json) => CommuteRequest(
    id: json['id'] as String,
    requesterProfileId: json['requesterProfileId'] as String,
    targetProfileId: json['targetProfileId'] as String?,
    circleId: json['circleId'] as String?,
    type: CommuteRequestType.values.byName(json['type'] as String),
    status: CommuteRequestStatus.values.byName(json['status'] as String),
    intendedDays: (json['intendedDays'] as List<dynamic>).cast<int>().toSet(),
    windowStartMinutes: json['windowStartMinutes'] as int,
    windowEndMinutes: json['windowEndMinutes'] as int,
    worksiteId: json['worksiteId'] as String,
    seatsRequired: json['seatsRequired'] as int,
    message: json['message'] as String?,
    intent: CommuteArrangementIntent.values.byName(json['intent'] as String),
    createdAt: DateTime.parse(json['createdAt'] as String),
    expiresAt: DateTime.parse(json['expiresAt'] as String),
  );
}
