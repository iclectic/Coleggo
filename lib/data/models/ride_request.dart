enum RequestStatus {
  pending,
  accepted,
  declined,
  cancelled;

  String get label => switch (this) {
    RequestStatus.pending => 'Pending',
    RequestStatus.accepted => 'Accepted',
    RequestStatus.declined => 'Declined',
    RequestStatus.cancelled => 'Cancelled',
  };
}

enum RequestDirection { incoming, outgoing }

enum RequestKind {
  seat,
  lift;

  String get actionLabel => switch (this) {
    RequestKind.seat => 'Request a seat',
    RequestKind.lift => 'Offer a lift',
  };
}

class RideRequest {
  const RideRequest({
    required this.id,
    required this.profileId,
    required this.direction,
    required this.kind,
    required this.status,
    required this.createdAt,
    required this.recurringDays,
  });

  final String id;
  final String profileId;
  final RequestDirection direction;
  final RequestKind kind;
  final RequestStatus status;
  final DateTime createdAt;
  final Set<int> recurringDays;

  RideRequest copyWith({RequestStatus? status}) => RideRequest(
    id: id,
    profileId: profileId,
    direction: direction,
    kind: kind,
    status: status ?? this.status,
    createdAt: createdAt,
    recurringDays: recurringDays,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'profileId': profileId,
    'direction': direction.name,
    'kind': kind.name,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'recurringDays': recurringDays.toList(),
  };

  factory RideRequest.fromJson(Map<String, dynamic> json) => RideRequest(
    id: json['id'] as String,
    profileId: json['profileId'] as String,
    direction: RequestDirection.values.byName(json['direction'] as String),
    kind: RequestKind.values.byName(json['kind'] as String),
    status: RequestStatus.values.byName(json['status'] as String),
    createdAt: DateTime.parse(json['createdAt'] as String),
    recurringDays: (json['recurringDays'] as List<dynamic>).cast<int>().toSet(),
  );
}
