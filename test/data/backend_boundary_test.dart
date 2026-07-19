import 'package:coleggo/data/mock/mock_data.dart';
import 'package:coleggo/data/models/commute.dart';
import 'package:coleggo/data/models/commute_circle.dart';
import 'package:coleggo/data/models/commute_request.dart';
import 'package:coleggo/data/models/commuter_profile.dart';
import 'package:coleggo/data/models/workplace_verification.dart';
import 'package:coleggo/data/repositories/local_repositories.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('prototype backend starts and verifies workplace sessions', () async {
    final repository = MockWorkplaceVerificationRepository();

    final session = await repository.start(
      workplaceId: 'northstar',
      worksiteId: 'central_exchange',
      email: 'alex@northstar.example',
    );
    final rejected = await repository.verify(
      workplaceId: 'northstar',
      worksiteId: 'central_exchange',
      email: 'alex@northstar.example',
      code: '000000',
    );
    final verified = await repository.verify(
      workplaceId: 'northstar',
      worksiteId: 'central_exchange',
      email: 'alex@northstar.example',
      code: '246810',
    );

    expect(session.value?.status, WorkplaceVerificationStatus.codeSent);
    expect(rejected.value, isFalse);
    expect(verified.value, isTrue);
  });

  test('circle repository prevents duplicate active join requests', () async {
    final repository = MockCommuteCircleRepository();
    final profile = _profile();
    final commute = _commute();
    final first = await repository.requestToJoin(
      currentRequests: const [],
      requesterProfileId: profile.id,
      circleId: 'circle-moseley-late',
      commute: commute,
      profile: profile,
    );
    final duplicate = await repository.requestToJoin(
      currentRequests: [first.value!],
      requesterProfileId: profile.id,
      circleId: 'circle-moseley-late',
      commute: commute,
      profile: profile,
    );

    expect(first.value?.type, CommuteRequestType.joinCircle);
    expect(duplicate.hasError, isTrue);
  });

  test(
    'circle repository applies accepted membership and seat state',
    () async {
      final repository = MockCommuteCircleRepository();
      final circle = MockData.commuteCircles().first;
      final request = CommuteRequest(
        id: 'request-test',
        requesterProfileId: 'p12',
        circleId: circle.id,
        type: CommuteRequestType.joinCircle,
        status: CommuteRequestStatus.pending,
        intendedDays: circle.days,
        windowStartMinutes: circle.departureWindowStartMinutes,
        windowEndMinutes: circle.departureWindowEndMinutes,
        worksiteId: circle.worksiteId,
        seatsRequired: 1,
        intent: CommuteArrangementIntent.recurring,
        createdAt: DateTime(2026, 7, 16),
        expiresAt: DateTime(2026, 7, 23),
      );

      final result = await repository.applyMembershipDecision(
        circles: [circle],
        request: request,
        status: CommuteRequestStatus.accepted,
      );
      final updated = result.value!.single;

      expect(
        updated.members.any((member) => member.profileId == 'p12'),
        isTrue,
      );
      expect(updated.availableSeats, circle.availableSeats - 1);
      expect(updated.state, CommuteCircleState.full);
    },
  );
}

CommuterProfile _profile() => CommuterProfile(
  id: 'local-user',
  firstName: 'Alex',
  initials: 'AL',
  role: CommuteRole.passenger,
  workplaceId: 'northstar',
  worksiteId: 'central_exchange',
  homeArea: 'Bearwood',
  corridor: MockData.areaCorridors['Bearwood']!,
  days: const {1, 3, 5},
  arrivalMinutes: 510,
  departureMinutes: 1050,
);

Commute _commute() => const Commute(
  id: 'local-commute',
  profileId: 'local-user',
  homeArea: 'Bearwood',
  worksiteId: 'central_exchange',
  days: {1, 3, 5},
  arrivalMinutes: 510,
  departureMinutes: 1050,
  recurring: true,
);
