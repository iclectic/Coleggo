import 'cancellation_record.dart';

enum JourneyStatus {
  scheduled,
  awaitingConfirmation,
  confirmed,
  completed,
  cancelled,
  missed,
  archived,
}

enum JourneyAttendanceStatus { confirmed, notTravelling, undecided }

class JourneyAttendance {
  const JourneyAttendance({
    required this.profileId,
    required this.status,
    required this.updatedAt,
  });

  final String profileId;
  final JourneyAttendanceStatus status;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
    'profileId': profileId,
    'status': status.name,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory JourneyAttendance.fromJson(Map<String, dynamic> json) =>
      JourneyAttendance(
        profileId: json['profileId'] as String,
        status: JourneyAttendanceStatus.values.byName(json['status'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}

class JourneyBackupPlan {
  const JourneyBackupPlan({
    required this.primaryDriverId,
    this.backupDriverId,
    this.cancellationDeadline,
    this.alternativeMatchIds = const [],
    this.publicTransportNote,
  });

  final String primaryDriverId;
  final String? backupDriverId;
  final DateTime? cancellationDeadline;
  final List<String> alternativeMatchIds;
  final String? publicTransportNote;

  JourneyBackupPlan copyWith({String? backupDriverId}) => JourneyBackupPlan(
    primaryDriverId: primaryDriverId,
    backupDriverId: backupDriverId ?? this.backupDriverId,
    cancellationDeadline: cancellationDeadline,
    alternativeMatchIds: alternativeMatchIds,
    publicTransportNote: publicTransportNote,
  );

  Map<String, dynamic> toJson() => {
    'primaryDriverId': primaryDriverId,
    'backupDriverId': backupDriverId,
    'cancellationDeadline': cancellationDeadline?.toIso8601String(),
    'alternativeMatchIds': alternativeMatchIds,
    'publicTransportNote': publicTransportNote,
  };

  factory JourneyBackupPlan.fromJson(Map<String, dynamic> json) =>
      JourneyBackupPlan(
        primaryDriverId: json['primaryDriverId'] as String,
        backupDriverId: json['backupDriverId'] as String?,
        cancellationDeadline: json['cancellationDeadline'] == null
            ? null
            : DateTime.parse(json['cancellationDeadline'] as String),
        alternativeMatchIds:
            (json['alternativeMatchIds'] as List<dynamic>? ?? const [])
                .cast<String>(),
        publicTransportNote: json['publicTransportNote'] as String?,
      );
}

class JourneyOccurrence {
  const JourneyOccurrence({
    required this.id,
    required this.circleId,
    required this.date,
    required this.departureWindowStartMinutes,
    required this.departureWindowEndMinutes,
    required this.arrivalTargetMinutes,
    required this.worksiteId,
    required this.status,
    required this.memberIds,
    required this.backupPlan,
    this.attendance = const [],
    this.cancellation,
  });

  final String id;
  final String circleId;
  final DateTime date;
  final int departureWindowStartMinutes;
  final int departureWindowEndMinutes;
  final int arrivalTargetMinutes;
  final String worksiteId;
  final JourneyStatus status;
  final List<String> memberIds;
  final List<JourneyAttendance> attendance;
  final JourneyBackupPlan backupPlan;
  final CancellationRecord? cancellation;

  int get confirmedCount => attendance
      .where((item) => item.status == JourneyAttendanceStatus.confirmed)
      .length;

  JourneyOccurrence copyWith({
    JourneyStatus? status,
    List<JourneyAttendance>? attendance,
    JourneyBackupPlan? backupPlan,
    CancellationRecord? cancellation,
  }) => JourneyOccurrence(
    id: id,
    circleId: circleId,
    date: date,
    departureWindowStartMinutes: departureWindowStartMinutes,
    departureWindowEndMinutes: departureWindowEndMinutes,
    arrivalTargetMinutes: arrivalTargetMinutes,
    worksiteId: worksiteId,
    status: status ?? this.status,
    memberIds: memberIds,
    attendance: attendance ?? this.attendance,
    backupPlan: backupPlan ?? this.backupPlan,
    cancellation: cancellation ?? this.cancellation,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'circleId': circleId,
    'date': date.toIso8601String(),
    'departureWindowStartMinutes': departureWindowStartMinutes,
    'departureWindowEndMinutes': departureWindowEndMinutes,
    'arrivalTargetMinutes': arrivalTargetMinutes,
    'worksiteId': worksiteId,
    'status': status.name,
    'memberIds': memberIds,
    'attendance': attendance.map((item) => item.toJson()).toList(),
    'backupPlan': backupPlan.toJson(),
    'cancellation': cancellation?.toJson(),
  };

  factory JourneyOccurrence.fromJson(Map<String, dynamic> json) =>
      JourneyOccurrence(
        id: json['id'] as String,
        circleId: json['circleId'] as String,
        date: DateTime.parse(json['date'] as String),
        departureWindowStartMinutes: json['departureWindowStartMinutes'] as int,
        departureWindowEndMinutes: json['departureWindowEndMinutes'] as int,
        arrivalTargetMinutes: json['arrivalTargetMinutes'] as int,
        worksiteId: json['worksiteId'] as String,
        status: JourneyStatus.values.byName(json['status'] as String),
        memberIds: (json['memberIds'] as List<dynamic>).cast<String>(),
        attendance: (json['attendance'] as List<dynamic>? ?? const [])
            .map(
              (item) =>
                  JourneyAttendance.fromJson(item as Map<String, dynamic>),
            )
            .toList(),
        backupPlan: JourneyBackupPlan.fromJson(
          json['backupPlan'] as Map<String, dynamic>,
        ),
        cancellation: json['cancellation'] == null
            ? null
            : CancellationRecord.fromJson(
                json['cancellation'] as Map<String, dynamic>,
              ),
      );
}
