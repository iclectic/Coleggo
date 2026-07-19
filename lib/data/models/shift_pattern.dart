enum ShiftKind { early, late, night, standardOffice, custom }

enum ShiftDayType { day, night }

const _minutesPerDay = 24 * 60;

class ShiftPattern {
  const ShiftPattern({
    required this.id,
    required this.name,
    required this.kind,
    required this.startMinutes,
    required this.endMinutes,
    required this.arrivalBufferMinutes,
    required this.departureWindowStartMinutes,
    required this.departureWindowEndMinutes,
    required this.recurringDays,
    this.rotaWeek,
    this.dayType = ShiftDayType.day,
  });

  final String id;
  final String name;
  final ShiftKind kind;
  final int startMinutes;
  final int endMinutes;
  final int arrivalBufferMinutes;
  final int departureWindowStartMinutes;
  final int departureWindowEndMinutes;
  final Set<int> recurringDays;
  final int? rotaWeek;
  final ShiftDayType dayType;

  bool get isOvernight => endMinutes <= startMinutes;

  int get durationMinutes {
    final raw = endMinutes - startMinutes;
    return raw > 0 ? raw : raw + _minutesPerDay;
  }

  bool overlapsWith(ShiftPattern other, {int toleranceMinutes = 30}) {
    final startsClose =
        _cyclicDifference(startMinutes, other.startMinutes) <= toleranceMinutes;
    final endsClose =
        _cyclicDifference(endMinutes, other.endMinutes) <= toleranceMinutes;
    return startsClose &&
        endsClose &&
        recurringDays.intersection(other.recurringDays).isNotEmpty;
  }

  int _cyclicDifference(int a, int b) {
    final difference = (a - b).abs();
    return difference > _minutesPerDay / 2
        ? _minutesPerDay - difference
        : difference;
  }

  ShiftPattern copyWith({
    Set<int>? recurringDays,
    int? startMinutes,
    int? endMinutes,
    int? departureWindowStartMinutes,
    int? departureWindowEndMinutes,
  }) => ShiftPattern(
    id: id,
    name: name,
    kind: kind,
    startMinutes: startMinutes ?? this.startMinutes,
    endMinutes: endMinutes ?? this.endMinutes,
    arrivalBufferMinutes: arrivalBufferMinutes,
    departureWindowStartMinutes:
        departureWindowStartMinutes ?? this.departureWindowStartMinutes,
    departureWindowEndMinutes:
        departureWindowEndMinutes ?? this.departureWindowEndMinutes,
    recurringDays: recurringDays ?? this.recurringDays,
    rotaWeek: rotaWeek,
    dayType: dayType,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'kind': kind.name,
    'startMinutes': startMinutes,
    'endMinutes': endMinutes,
    'arrivalBufferMinutes': arrivalBufferMinutes,
    'departureWindowStartMinutes': departureWindowStartMinutes,
    'departureWindowEndMinutes': departureWindowEndMinutes,
    'recurringDays': recurringDays.toList(),
    'rotaWeek': rotaWeek,
    'dayType': dayType.name,
  };

  factory ShiftPattern.fromJson(Map<String, dynamic> json) => ShiftPattern(
    id: json['id'] as String,
    name: json['name'] as String,
    kind: ShiftKind.values.byName(json['kind'] as String),
    startMinutes: json['startMinutes'] as int,
    endMinutes: json['endMinutes'] as int,
    arrivalBufferMinutes: json['arrivalBufferMinutes'] as int? ?? 15,
    departureWindowStartMinutes:
        json['departureWindowStartMinutes'] as int? ??
        json['startMinutes'] as int,
    departureWindowEndMinutes:
        json['departureWindowEndMinutes'] as int? ??
        json['startMinutes'] as int,
    recurringDays: (json['recurringDays'] as List<dynamic>).cast<int>().toSet(),
    rotaWeek: json['rotaWeek'] as int?,
    dayType: ShiftDayType.values.byName(
      json['dayType'] as String? ?? ShiftDayType.day.name,
    ),
  );

  static const early = ShiftPattern(
    id: 'early',
    name: 'Early',
    kind: ShiftKind.early,
    startMinutes: 7 * 60,
    endMinutes: 19 * 60,
    arrivalBufferMinutes: 20,
    departureWindowStartMinutes: 6 * 60 + 40,
    departureWindowEndMinutes: 6 * 60 + 55,
    recurringDays: {1, 2, 3, 4, 5},
  );

  static const late = ShiftPattern(
    id: 'late',
    name: 'Late',
    kind: ShiftKind.late,
    startMinutes: 12 * 60,
    endMinutes: 20 * 60,
    arrivalBufferMinutes: 15,
    departureWindowStartMinutes: 11 * 60 + 25,
    departureWindowEndMinutes: 11 * 60 + 45,
    recurringDays: {1, 2, 3, 4, 5},
  );

  static const night = ShiftPattern(
    id: 'night',
    name: 'Night',
    kind: ShiftKind.night,
    startMinutes: 20 * 60,
    endMinutes: 8 * 60,
    arrivalBufferMinutes: 20,
    departureWindowStartMinutes: 19 * 60 + 20,
    departureWindowEndMinutes: 19 * 60 + 45,
    recurringDays: {1, 2, 3, 4, 5},
    dayType: ShiftDayType.night,
  );

  static const standardOffice = ShiftPattern(
    id: 'standard-office',
    name: 'Standard office',
    kind: ShiftKind.standardOffice,
    startMinutes: 9 * 60,
    endMinutes: 17 * 60,
    arrivalBufferMinutes: 10,
    departureWindowStartMinutes: 8 * 60 + 20,
    departureWindowEndMinutes: 8 * 60 + 45,
    recurringDays: {1, 2, 3, 4, 5},
  );
}
