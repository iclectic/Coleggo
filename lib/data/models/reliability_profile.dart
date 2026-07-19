enum ReliabilitySignalType {
  completedCommutes,
  recurringParticipation,
  lateCancellation,
  noShow,
  responseConsistency,
  profileCompletion,
}

class ReliabilitySignal {
  const ReliabilitySignal({
    required this.type,
    required this.label,
    required this.count,
    this.warning = false,
  });

  final ReliabilitySignalType type;
  final String label;
  final int count;
  final bool warning;

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'label': label,
    'count': count,
    'warning': warning,
  };

  factory ReliabilitySignal.fromJson(Map<String, dynamic> json) =>
      ReliabilitySignal(
        type: ReliabilitySignalType.values.byName(json['type'] as String),
        label: json['label'] as String,
        count: json['count'] as int,
        warning: json['warning'] as bool? ?? false,
      );
}

class CommuteReliabilityProfile {
  const CommuteReliabilityProfile({
    required this.profileId,
    this.workplaceVerified = true,
    this.signals = const [],
  });

  final String profileId;
  final bool workplaceVerified;
  final List<ReliabilitySignal> signals;

  List<ReliabilitySignal> get positives =>
      signals.where((signal) => !signal.warning).toList();

  List<ReliabilitySignal> get warnings =>
      signals.where((signal) => signal.warning).toList();

  Map<String, dynamic> toJson() => {
    'profileId': profileId,
    'workplaceVerified': workplaceVerified,
    'signals': signals.map((signal) => signal.toJson()).toList(),
  };

  factory CommuteReliabilityProfile.fromJson(Map<String, dynamic> json) =>
      CommuteReliabilityProfile(
        profileId: json['profileId'] as String,
        workplaceVerified: json['workplaceVerified'] as bool? ?? true,
        signals: (json['signals'] as List<dynamic>? ?? const [])
            .map(
              (signal) =>
                  ReliabilitySignal.fromJson(signal as Map<String, dynamic>),
            )
            .toList(),
      );
}
