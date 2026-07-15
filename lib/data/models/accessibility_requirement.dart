enum AccessibilityRequirementType {
  wheelchairAccessibleVehicle,
  limitedWalkingDistance,
  stepFreeMeetingPoint,
  additionalBoardingTime,
  assistanceAnimal,
  luggageOrEquipmentSpace,
}

class AccessibilityRequirement {
  const AccessibilityRequirement({
    required this.type,
    required this.label,
    this.publiclyVisible = false,
  });

  final AccessibilityRequirementType type;
  final String label;
  final bool publiclyVisible;

  String get publicSummary => switch (type) {
    AccessibilityRequirementType.wheelchairAccessibleVehicle =>
      'Accessible vehicle required',
    AccessibilityRequirementType.limitedWalkingDistance =>
      'Limited walking distance',
    AccessibilityRequirementType.stepFreeMeetingPoint =>
      'Step-free pickup point required',
    AccessibilityRequirementType.additionalBoardingTime =>
      'Additional boarding time helpful',
    AccessibilityRequirementType.assistanceAnimal =>
      'Assistance animal travelling',
    AccessibilityRequirementType.luggageOrEquipmentSpace =>
      'Equipment or luggage space required',
  };

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'label': label,
    'publiclyVisible': publiclyVisible,
  };

  factory AccessibilityRequirement.fromJson(Map<String, dynamic> json) =>
      AccessibilityRequirement(
        type: AccessibilityRequirementType.values.byName(
          json['type'] as String,
        ),
        label: json['label'] as String,
        publiclyVisible: json['publiclyVisible'] as bool? ?? false,
      );
}
