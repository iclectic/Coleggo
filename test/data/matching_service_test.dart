import 'package:coleggo/data/mock/mock_data.dart';
import 'package:coleggo/data/models/commuter_profile.dart';
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

  test('weights exact area, time, worksite, days and role to 100', () {
    final candidate = CommuterProfile(
      id: 'driver',
      firstName: 'Driver',
      initials: 'DR',
      role: CommuteRole.driver,
      workplaceId: 'northstar',
      worksiteId: 'central_exchange',
      homeArea: 'Bearwood',
      corridor: MockData.areaCorridors['Bearwood']!,
      days: const {1, 2, 3},
      arrivalMinutes: 510,
      departureMinutes: 1050,
      availableSeats: 2,
    );

    final result = service.score(user, candidate);

    expect(result.score, 100);
    expect(result.breakdown.area, 35);
    expect(result.breakdown.time, 25);
    expect(result.breakdown.worksite, 20);
    expect(result.breakdown.days, 15);
    expect(result.breakdown.role, 5);
    expect(result.reasons, contains('Same worksite'));
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

  test('fixture set supports at least twelve useful matches', () {
    final matches = service.findMatches(user, MockData.commuters);
    expect(matches.length, greaterThanOrEqualTo(12));
  });
}
