import 'package:coleggo/data/mock/mock_data.dart';
import 'package:coleggo/data/models/commuter_profile.dart';
import 'package:coleggo/data/models/ride_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fictional fixture breadth meets prototype requirements', () {
    expect(MockData.workplaces.length, greaterThanOrEqualTo(5));
    expect(
      MockData.workplaces.expand((workplace) => workplace.worksites).length,
      greaterThanOrEqualTo(8),
    );
    expect(MockData.commuters.length, greaterThanOrEqualTo(18));
    expect(
      MockData.commuters.any((item) => item.role == CommuteRole.driver),
      isTrue,
    );
    expect(
      MockData.commuters.any((item) => item.role == CommuteRole.passenger),
      isTrue,
    );
    expect(
      MockData.commuters.any((item) => item.role == CommuteRole.both),
      isTrue,
    );
  });

  test('seeded requests cover every required status', () {
    final statuses = MockData.seededRequests()
        .map((item) => item.status)
        .toSet();
    expect(statuses, containsAll(RequestStatus.values));
  });
}
