import 'package:coleggo/data/mock/mock_data.dart';
import 'package:coleggo/data/models/commuter_profile.dart';
import 'package:coleggo/data/models/match_result.dart';
import 'package:coleggo/data/models/shift_pattern.dart';
import 'package:coleggo/data/services/matching_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = MatchingService();
  final user = CommuterProfile(
    id: 'user',
    firstName: 'Test',
    initials: 'TE',
    role: CommuteRole.passenger,
    workplaceId: 'northstar',
    worksiteId: 'central_exchange',
    homeArea: 'Bearwood',
    corridor: MockData.areaCorridors['Bearwood']!,
    days: const {1, 2, 3},
    arrivalMinutes: 510,
    departureMinutes: 1050,
  );

  CommuterProfile driver({
    String id = 'driver',
    String worksiteId = 'central_exchange',
    String area = 'Bearwood',
    Set<int> days = const {1, 2, 3},
    int arrival = 510,
    int departure = 1050,
    int seats = 2,
    ShiftPattern? shiftPattern,
  }) => CommuterProfile(
    id: id,
    firstName: 'Driver',
    initials: 'DR',
    role: CommuteRole.driver,
    workplaceId: 'northstar',
    worksiteId: worksiteId,
    homeArea: area,
    corridor: MockData.areaCorridors[area]!,
    days: days,
    arrivalMinutes: arrival,
    departureMinutes: departure,
    availableSeats: seats,
    shiftPattern: shiftPattern,
  );

  test('weights exact area, time, worksite, days and role to 100', () {
    final candidate = driver();

    final result = service.score(user, candidate);

    expect(result.score, 100);
    expect(result.level, MatchLevel.excellent);
    expect(result.breakdown.worksite, 25);
    expect(result.breakdown.area, 20);
    expect(result.breakdown.time, 20);
    expect(result.breakdown.days, 15);
    expect(result.breakdown.role, 10);
    expect(result.breakdown.seats, 5);
    expect(result.breakdown.recurring, 5);
    expect(result.isEligible, isTrue);
    expect(result.reasons, contains('Same verified worksite'));
    expect(result.reasons, contains('2 seats available'));
  });

  test('excludes role-incompatible candidates and sorts deterministically', () {
    final passenger = user.copyWith(firstName: 'Another');
    final matches = service.findMatches(user, [
      passenger,
      ...MockData.commuters,
    ]);

    expect(matches, isNotEmpty);
    expect(matches.every((item) => item.profile.role.canDrive), isTrue);
    for (var index = 1; index < matches.length; index++) {
      expect(
        matches[index - 1].score,
        greaterThanOrEqualTo(matches[index].score),
      );
    }
  });

  test('fixture set keeps discovery focused on useful eligible matches', () {
    final matches = service.findMatches(user, MockData.commuters);
    expect(matches.length, greaterThanOrEqualTo(8));
    expect(matches.every((match) => match.isEligible), isTrue);
  });

  test('marks different worksites as ineligible even when timings align', () {
    final result = service.score(user, driver(worksiteId: 'northfield_house'));

    expect(result.isEligible, isFalse);
    expect(result.level, MatchLevel.limited);
    expect(
      result.limitations.map((reason) => reason.message),
      contains('Different worksites, so the commute may not align'),
    );
  });

  test('supports overnight shift compatibility', () {
    final nightUser = user.copyWith(
      arrivalMinutes: 20 * 60,
      departureMinutes: 8 * 60,
      shiftPattern: ShiftPattern.night.copyWith(recurringDays: {2}),
      days: {2},
    );
    final nightDriver = driver(
      arrival: 20 * 60 + 10,
      departure: 8 * 60 + 10,
      days: {2},
      shiftPattern: ShiftPattern.night.copyWith(
        recurringDays: {2},
        startMinutes: 20 * 60 + 10,
        endMinutes: 8 * 60 + 10,
      ),
    );

    final result = service.score(nightUser, nightDriver);

    expect(ShiftPattern.night.isOvernight, isTrue);
    expect(ShiftPattern.night.durationMinutes, 12 * 60);
    expect(result.breakdown.time, 20);
    expect(result.isEligible, isTrue);
  });

  test('does not overstate incompatible shift endings', () {
    final lateFinishDriver = driver(
      arrival: 12 * 60,
      departure: 20 * 60,
      shiftPattern: ShiftPattern.late,
    );
    final officePassenger = user.copyWith(
      arrivalMinutes: 9 * 60,
      departureMinutes: 17 * 60,
      shiftPattern: ShiftPattern.standardOffice,
    );

    final result = service.score(officePassenger, lateFinishDriver);

    expect(result.breakdown.time, 0);
    expect(result.isEligible, isFalse);
    expect(result.level, MatchLevel.limited);
    expect(
      result.limitations.map((reason) => reason.message),
      contains('Shift windows do not overlap'),
    );
  });
}
