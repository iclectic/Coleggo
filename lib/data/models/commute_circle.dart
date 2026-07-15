import 'reliability_profile.dart';
import 'shift_pattern.dart';

enum CommuteCircleState { forming, active, full, paused, archived }

enum CircleMemberRole { primaryDriver, backupDriver, passenger }

enum CircleParticipationStatus { active, paused }

class CircleMember {
  const CircleMember({
    required this.profileId,
    required this.role,
    this.status = CircleParticipationStatus.active,
  });

  final String profileId;
  final CircleMemberRole role;
  final CircleParticipationStatus status;

  bool get isDriver =>
      role == CircleMemberRole.primaryDriver ||
      role == CircleMemberRole.backupDriver;

  CircleMember copyWith({CircleParticipationStatus? status}) => CircleMember(
    profileId: profileId,
    role: role,
    status: status ?? this.status,
  );

  Map<String, dynamic> toJson() => {
    'profileId': profileId,
    'role': role.name,
    'status': status.name,
  };

  factory CircleMember.fromJson(Map<String, dynamic> json) => CircleMember(
    profileId: json['profileId'] as String,
    role: CircleMemberRole.values.byName(json['role'] as String),
    status: CircleParticipationStatus.values.byName(
      json['status'] as String? ?? CircleParticipationStatus.active.name,
    ),
  );
}

class CircleActivity {
  const CircleActivity({
    required this.id,
    required this.label,
    required this.createdAt,
  });

  final String id;
  final String label;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'createdAt': createdAt.toIso8601String(),
  };

  factory CircleActivity.fromJson(Map<String, dynamic> json) => CircleActivity(
    id: json['id'] as String,
    label: json['label'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

class CommuteCircle {
  const CommuteCircle({
    required this.id,
    required this.name,
    required this.workplaceId,
    required this.worksiteId,
    required this.state,
    required this.members,
    required this.days,
    required this.departureWindowStartMinutes,
    required this.departureWindowEndMinutes,
    required this.arrivalTargetMinutes,
    required this.meetingPointArea,
    required this.availableSeats,
    required this.rules,
    required this.shiftPattern,
    this.activity = const [],
    this.reliabilitySummaries = const [],
  });

  final String id;
  final String name;
  final String workplaceId;
  final String worksiteId;
  final CommuteCircleState state;
  final List<CircleMember> members;
  final Set<int> days;
  final int departureWindowStartMinutes;
  final int departureWindowEndMinutes;
  final int arrivalTargetMinutes;
  final String meetingPointArea;
  final int availableSeats;
  final List<String> rules;
  final ShiftPattern shiftPattern;
  final List<CircleActivity> activity;
  final List<CommuteReliabilityProfile> reliabilitySummaries;

  bool get hasBackupDriver =>
      members.any((member) => member.role == CircleMemberRole.backupDriver);

  CommuteCircle copyWith({
    CommuteCircleState? state,
    List<CircleMember>? members,
    int? availableSeats,
    List<CircleActivity>? activity,
  }) => CommuteCircle(
    id: id,
    name: name,
    workplaceId: workplaceId,
    worksiteId: worksiteId,
    state: state ?? this.state,
    members: members ?? this.members,
    days: days,
    departureWindowStartMinutes: departureWindowStartMinutes,
    departureWindowEndMinutes: departureWindowEndMinutes,
    arrivalTargetMinutes: arrivalTargetMinutes,
    meetingPointArea: meetingPointArea,
    availableSeats: availableSeats ?? this.availableSeats,
    rules: rules,
    shiftPattern: shiftPattern,
    activity: activity ?? this.activity,
    reliabilitySummaries: reliabilitySummaries,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'workplaceId': workplaceId,
    'worksiteId': worksiteId,
    'state': state.name,
    'members': members.map((member) => member.toJson()).toList(),
    'days': days.toList(),
    'departureWindowStartMinutes': departureWindowStartMinutes,
    'departureWindowEndMinutes': departureWindowEndMinutes,
    'arrivalTargetMinutes': arrivalTargetMinutes,
    'meetingPointArea': meetingPointArea,
    'availableSeats': availableSeats,
    'rules': rules,
    'shiftPattern': shiftPattern.toJson(),
    'activity': activity.map((item) => item.toJson()).toList(),
    'reliabilitySummaries': reliabilitySummaries
        .map((item) => item.toJson())
        .toList(),
  };

  factory CommuteCircle.fromJson(Map<String, dynamic> json) => CommuteCircle(
    id: json['id'] as String,
    name: json['name'] as String,
    workplaceId: json['workplaceId'] as String,
    worksiteId: json['worksiteId'] as String,
    state: CommuteCircleState.values.byName(json['state'] as String),
    members: (json['members'] as List<dynamic>)
        .map((member) => CircleMember.fromJson(member as Map<String, dynamic>))
        .toList(),
    days: (json['days'] as List<dynamic>).cast<int>().toSet(),
    departureWindowStartMinutes: json['departureWindowStartMinutes'] as int,
    departureWindowEndMinutes: json['departureWindowEndMinutes'] as int,
    arrivalTargetMinutes: json['arrivalTargetMinutes'] as int,
    meetingPointArea: json['meetingPointArea'] as String,
    availableSeats: json['availableSeats'] as int,
    rules: (json['rules'] as List<dynamic>).cast<String>(),
    shiftPattern: ShiftPattern.fromJson(
      json['shiftPattern'] as Map<String, dynamic>,
    ),
    activity: (json['activity'] as List<dynamic>? ?? const [])
        .map((item) => CircleActivity.fromJson(item as Map<String, dynamic>))
        .toList(),
    reliabilitySummaries:
        (json['reliabilitySummaries'] as List<dynamic>? ?? const [])
            .map(
              (item) => CommuteReliabilityProfile.fromJson(
                item as Map<String, dynamic>,
              ),
            )
            .toList(),
  );
}
