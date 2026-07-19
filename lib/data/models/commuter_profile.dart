import 'accessibility_requirement.dart';
import 'private_commute_location.dart';
import 'shift_pattern.dart';

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
    this.privateLocation,
    this.shiftPattern,
    this.accessibilityRequirements = const [],
    this.commuteNote,
    this.prefersPublicMeetingPoints = true,
    this.quietCommute = false,
    this.conversationWelcome = true,
    this.noFoodInVehicle = false,
    this.flexibleDepartureWindow = false,
    this.womenOnlyCirclePreference = false,
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
  final PrivateCommuteLocation? privateLocation;
  final ShiftPattern? shiftPattern;
  final List<AccessibilityRequirement> accessibilityRequirements;
  final String? commuteNote;
  final bool prefersPublicMeetingPoints;
  final bool quietCommute;
  final bool conversationWelcome;
  final bool noFoodInVehicle;
  final bool flexibleDepartureWindow;
  final bool womenOnlyCirclePreference;

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
    PrivateCommuteLocation? privateLocation,
    ShiftPattern? shiftPattern,
    List<AccessibilityRequirement>? accessibilityRequirements,
    String? commuteNote,
    bool? prefersPublicMeetingPoints,
    bool? quietCommute,
    bool? conversationWelcome,
    bool? noFoodInVehicle,
    bool? flexibleDepartureWindow,
    bool? womenOnlyCirclePreference,
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
    privateLocation: privateLocation ?? this.privateLocation,
    shiftPattern: shiftPattern ?? this.shiftPattern,
    accessibilityRequirements:
        accessibilityRequirements ?? this.accessibilityRequirements,
    commuteNote: commuteNote ?? this.commuteNote,
    prefersPublicMeetingPoints:
        prefersPublicMeetingPoints ?? this.prefersPublicMeetingPoints,
    quietCommute: quietCommute ?? this.quietCommute,
    conversationWelcome: conversationWelcome ?? this.conversationWelcome,
    noFoodInVehicle: noFoodInVehicle ?? this.noFoodInVehicle,
    flexibleDepartureWindow:
        flexibleDepartureWindow ?? this.flexibleDepartureWindow,
    womenOnlyCirclePreference:
        womenOnlyCirclePreference ?? this.womenOnlyCirclePreference,
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
    'privateLocation': privateLocation?.toJson(),
    'shiftPattern': shiftPattern?.toJson(),
    'accessibilityRequirements': accessibilityRequirements
        .map((requirement) => requirement.toJson())
        .toList(),
    'commuteNote': commuteNote,
    'prefersPublicMeetingPoints': prefersPublicMeetingPoints,
    'quietCommute': quietCommute,
    'conversationWelcome': conversationWelcome,
    'noFoodInVehicle': noFoodInVehicle,
    'flexibleDepartureWindow': flexibleDepartureWindow,
    'womenOnlyCirclePreference': womenOnlyCirclePreference,
  };

  factory CommuterProfile.fromJson(
    Map<String, dynamic> json,
  ) => CommuterProfile(
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
    privateLocation: json['privateLocation'] == null
        ? null
        : PrivateCommuteLocation.fromJson(
            json['privateLocation'] as Map<String, dynamic>,
          ),
    shiftPattern: json['shiftPattern'] == null
        ? null
        : ShiftPattern.fromJson(json['shiftPattern'] as Map<String, dynamic>),
    accessibilityRequirements:
        (json['accessibilityRequirements'] as List<dynamic>? ?? const [])
            .map(
              (requirement) => AccessibilityRequirement.fromJson(
                requirement as Map<String, dynamic>,
              ),
            )
            .toList(),
    commuteNote: json['commuteNote'] as String?,
    prefersPublicMeetingPoints:
        json['prefersPublicMeetingPoints'] as bool? ?? true,
    quietCommute: json['quietCommute'] as bool? ?? false,
    conversationWelcome: json['conversationWelcome'] as bool? ?? true,
    noFoodInVehicle: json['noFoodInVehicle'] as bool? ?? false,
    flexibleDepartureWindow: json['flexibleDepartureWindow'] as bool? ?? false,
    womenOnlyCirclePreference:
        json['womenOnlyCirclePreference'] as bool? ?? false,
  );
}
