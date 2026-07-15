enum MeetingPointType {
  trainStationEntrance,
  supermarketCarPark,
  publicCarPark,
  workplaceShuttleStop,
  recognisedLandmark,
}

enum ProximityCategory { sameArea, nearbyArea, alongYourRoute, moderateDetour }

class PrivateCommuteLocation {
  const PrivateCommuteLocation({
    required this.areaName,
    required this.postcodeDistrict,
    required this.approximateLatitude,
    required this.approximateLongitude,
    required this.privacyRadiusMetres,
    required this.preferredMeetingPointType,
    this.preciseLocationShared = false,
  });

  final String areaName;
  final String postcodeDistrict;
  final double approximateLatitude;
  final double approximateLongitude;
  final int privacyRadiusMetres;
  final MeetingPointType preferredMeetingPointType;
  final bool preciseLocationShared;

  Map<String, dynamic> toJson() => {
    'areaName': areaName,
    'postcodeDistrict': postcodeDistrict,
    'approximateLatitude': approximateLatitude,
    'approximateLongitude': approximateLongitude,
    'privacyRadiusMetres': privacyRadiusMetres,
    'preferredMeetingPointType': preferredMeetingPointType.name,
    'preciseLocationShared': preciseLocationShared,
  };

  factory PrivateCommuteLocation.fromJson(Map<String, dynamic> json) =>
      PrivateCommuteLocation(
        areaName: json['areaName'] as String,
        postcodeDistrict: json['postcodeDistrict'] as String,
        approximateLatitude: (json['approximateLatitude'] as num).toDouble(),
        approximateLongitude: (json['approximateLongitude'] as num).toDouble(),
        privacyRadiusMetres: json['privacyRadiusMetres'] as int,
        preferredMeetingPointType: MeetingPointType.values.byName(
          json['preferredMeetingPointType'] as String,
        ),
        preciseLocationShared: json['preciseLocationShared'] as bool? ?? false,
      );
}
