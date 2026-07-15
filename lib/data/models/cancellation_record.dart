enum CancellationActor { driver, passenger, organiser }

class CancellationRecord {
  const CancellationRecord({
    required this.id,
    required this.journeyId,
    required this.cancelledByProfileId,
    required this.actor,
    required this.cancelledAt,
    required this.affectedProfileIds,
    this.reason,
  });

  final String id;
  final String journeyId;
  final String cancelledByProfileId;
  final CancellationActor actor;
  final DateTime cancelledAt;
  final List<String> affectedProfileIds;
  final String? reason;

  Map<String, dynamic> toJson() => {
    'id': id,
    'journeyId': journeyId,
    'cancelledByProfileId': cancelledByProfileId,
    'actor': actor.name,
    'cancelledAt': cancelledAt.toIso8601String(),
    'affectedProfileIds': affectedProfileIds,
    'reason': reason,
  };

  factory CancellationRecord.fromJson(Map<String, dynamic> json) =>
      CancellationRecord(
        id: json['id'] as String,
        journeyId: json['journeyId'] as String,
        cancelledByProfileId: json['cancelledByProfileId'] as String,
        actor: CancellationActor.values.byName(json['actor'] as String),
        cancelledAt: DateTime.parse(json['cancelledAt'] as String),
        affectedProfileIds: (json['affectedProfileIds'] as List<dynamic>)
            .cast<String>(),
        reason: json['reason'] as String?,
      );
}
