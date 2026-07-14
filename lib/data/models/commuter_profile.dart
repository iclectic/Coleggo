enum CommuteRole {
  driver,
  passenger,
  both;

  String get label => switch (this) {
    CommuteRole.driver => 'Driver',
    CommuteRole.passenger => 'Passenger',
    CommuteRole.both => 'Both',
  };

  bool get canDrive => this == driver || this == both;
  bool get canRide => this == passenger || this == both;
}

class CommuterProfile {
  const CommuterProfile({
    required this.id,
    required this.firstName,
    required this.initials,
    required this.role,
    required this.workplaceId,
    required this.worksiteId,
    required this.homeArea,
    required this.corridor,
    required this.days,
    required this.arrivalMinutes,
    required this.departureMinutes,
    this.availableSeats = 0,
    this.vehicleSummary,
    this.verifiedWorkplace = true,
  });

  final String id;
  final String firstName;
  final String initials;
  final CommuteRole role;
  final String workplaceId;
  final String worksiteId;
  final String homeArea;
  final String corridor;
  final Set<int> days;
  final int arrivalMinutes;
  final int departureMinutes;
  final int availableSeats;
  final String? vehicleSummary;
  final bool verifiedWorkplace;

  CommuterProfile copyWith({
    String? firstName,
    String? initials,
    CommuteRole? role,
    String? workplaceId,
    String? worksiteId,
    String? homeArea,
    String? corridor,
    Set<int>? days,
    int? arrivalMinutes,
    int? departureMinutes,
    int? availableSeats,
    String? vehicleSummary,
    bool? verifiedWorkplace,
  }) => CommuterProfile(
    id: id,
    firstName: firstName ?? this.firstName,
    initials: initials ?? this.initials,
    role: role ?? this.role,
    workplaceId: workplaceId ?? this.workplaceId,
    worksiteId: worksiteId ?? this.worksiteId,
    homeArea: homeArea ?? this.homeArea,
    corridor: corridor ?? this.corridor,
    days: days ?? this.days,
    arrivalMinutes: arrivalMinutes ?? this.arrivalMinutes,
    departureMinutes: departureMinutes ?? this.departureMinutes,
    availableSeats: availableSeats ?? this.availableSeats,
    vehicleSummary: vehicleSummary ?? this.vehicleSummary,
    verifiedWorkplace: verifiedWorkplace ?? this.verifiedWorkplace,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'firstName': firstName,
    'initials': initials,
    'role': role.name,
    'workplaceId': workplaceId,
    'worksiteId': worksiteId,
    'homeArea': homeArea,
    'corridor': corridor,
    'days': days.toList(),
    'arrivalMinutes': arrivalMinutes,
    'departureMinutes': departureMinutes,
    'availableSeats': availableSeats,
    'vehicleSummary': vehicleSummary,
    'verifiedWorkplace': verifiedWorkplace,
  };

  factory CommuterProfile.fromJson(Map<String, dynamic> json) =>
      CommuterProfile(
        id: json['id'] as String,
        firstName: json['firstName'] as String,
        initials: json['initials'] as String,
        role: CommuteRole.values.byName(json['role'] as String),
        workplaceId: json['workplaceId'] as String,
        worksiteId: json['worksiteId'] as String,
        homeArea: json['homeArea'] as String,
        corridor: json['corridor'] as String,
        days: (json['days'] as List<dynamic>).cast<int>().toSet(),
        arrivalMinutes: json['arrivalMinutes'] as int,
        departureMinutes: json['departureMinutes'] as int,
        availableSeats: json['availableSeats'] as int? ?? 0,
        vehicleSummary: json['vehicleSummary'] as String?,
        verifiedWorkplace: json['verifiedWorkplace'] as bool? ?? true,
      );
}
