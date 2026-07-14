class Commute {
  const Commute({
    required this.id,
    required this.profileId,
    required this.homeArea,
    required this.worksiteId,
    required this.days,
    required this.arrivalMinutes,
    required this.departureMinutes,
    required this.recurring,
    this.publicMeetingPoint,
  });

  final String id;
  final String profileId;
  final String homeArea;
  final String worksiteId;
  final Set<int> days;
  final int arrivalMinutes;
  final int departureMinutes;
  final bool recurring;
  final String? publicMeetingPoint;

  Commute copyWith({
    String? homeArea,
    String? worksiteId,
    Set<int>? days,
    int? arrivalMinutes,
    int? departureMinutes,
    bool? recurring,
    String? publicMeetingPoint,
  }) => Commute(
    id: id,
    profileId: profileId,
    homeArea: homeArea ?? this.homeArea,
    worksiteId: worksiteId ?? this.worksiteId,
    days: days ?? this.days,
    arrivalMinutes: arrivalMinutes ?? this.arrivalMinutes,
    departureMinutes: departureMinutes ?? this.departureMinutes,
    recurring: recurring ?? this.recurring,
    publicMeetingPoint: publicMeetingPoint ?? this.publicMeetingPoint,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'profileId': profileId,
    'homeArea': homeArea,
    'worksiteId': worksiteId,
    'days': days.toList(),
    'arrivalMinutes': arrivalMinutes,
    'departureMinutes': departureMinutes,
    'recurring': recurring,
    'publicMeetingPoint': publicMeetingPoint,
  };

  factory Commute.fromJson(Map<String, dynamic> json) => Commute(
    id: json['id'] as String,
    profileId: json['profileId'] as String,
    homeArea: json['homeArea'] as String,
    worksiteId: json['worksiteId'] as String,
    days: (json['days'] as List<dynamic>).cast<int>().toSet(),
    arrivalMinutes: json['arrivalMinutes'] as int,
    departureMinutes: json['departureMinutes'] as int,
    recurring: json['recurring'] as bool? ?? true,
    publicMeetingPoint: json['publicMeetingPoint'] as String?,
  );
}
