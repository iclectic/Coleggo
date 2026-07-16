import '../../core/constants/app_constants.dart';
import '../mock/mock_data.dart';
import '../models/app_state.dart';
import '../models/commute.dart';
import '../models/commute_circle.dart';
import '../models/commute_request.dart';
import '../models/commuter_profile.dart';
import '../models/journey.dart';
import '../models/message_thread.dart';
import '../models/match_result.dart';
import '../models/reliability_profile.dart';
import '../models/ride_request.dart';
import '../models/workplace.dart';
import '../models/workplace_verification.dart';
import '../services/local_storage_service.dart';
import '../services/matching_service.dart';
import 'repository_interfaces.dart';

class MockWorkplaceRepository implements WorkplaceRepository {
  @override
  List<Workplace> getWorkplaces() => MockData.workplaces;
}

class MockProfileRepository implements ProfileRepository {
  @override
  List<CommuterProfile> getCommuters() => MockData.commuters;

  @override
  CommuterProfile getById(String id) => MockData.commuter(id);
}

class LocalCommuteRepository implements CommuteRepository {
  LocalCommuteRepository(this._storage);
  final LocalStorageService _storage;

  @override
  Future<AppState> loadState() => _storage.load();

  @override
  Future<void> saveState(AppState state) => _storage.save(state);

  @override
  Future<void> clearState() => _storage.clear();

  @override
  Commute createFor(CommuterProfile profile) => Commute(
    id: 'local-commute',
    profileId: profile.id,
    homeArea: profile.homeArea,
    worksiteId: profile.worksiteId,
    days: profile.days,
    arrivalMinutes: profile.arrivalMinutes,
    departureMinutes: profile.departureMinutes,
    recurring: true,
    publicMeetingPoint: '${profile.homeArea} public transport stop',
  );
}

class MockMatchRepository implements MatchRepository {
  const MockMatchRepository(this._matchingService);
  final MatchingService _matchingService;

  @override
  List<MatchResult> getMatches(CommuterProfile profile) =>
      _matchingService.findMatches(profile, MockData.commuters);

  @override
  MatchResult getMatch(CommuterProfile profile, String candidateId) =>
      _matchingService.score(profile, MockData.commuter(candidateId));
}

class MockRideRequestRepository implements RideRequestRepository {
  @override
  List<RideRequest> seededRequests() => MockData.seededRequests();
}

class MockCommuteCircleRepository implements CommuteCircleRepository {
  @override
  Future<RepositoryResult<List<CommuteCircle>>> getCircles() async =>
      RepositoryResult.data(MockData.commuteCircles());

  @override
  Future<RepositoryResult<CommuteCircle>> getCircle(String id) async {
    try {
      return RepositoryResult.data(MockData.circle(id));
    } on StateError {
      return const RepositoryResult.failure('Commute Circle not found.');
    }
  }

  @override
  Future<RepositoryResult<CommuteRequest>> requestToJoin({
    required List<CommuteRequest> currentRequests,
    required String requesterProfileId,
    required String circleId,
    required Commute commute,
    required CommuterProfile profile,
  }) async {
    final duplicate = currentRequests.any(
      (request) =>
          request.circleId == circleId &&
          request.requesterProfileId == requesterProfileId &&
          request.type == CommuteRequestType.joinCircle &&
          request.isActive,
    );
    if (duplicate) {
      return const RepositoryResult.failure(
        'You already have an active request for this circle.',
      );
    }
    return RepositoryResult.data(
      CommuteRequest(
        id: 'circle-${DateTime.now().microsecondsSinceEpoch}',
        requesterProfileId: requesterProfileId,
        circleId: circleId,
        type: CommuteRequestType.joinCircle,
        status: CommuteRequestStatus.pending,
        intendedDays: commute.days,
        windowStartMinutes: commute.arrivalMinutes - 45,
        windowEndMinutes: commute.arrivalMinutes,
        worksiteId: commute.worksiteId,
        seatsRequired: profile.role.canRide ? 1 : 0,
        intent: CommuteArrangementIntent.recurring,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 7)),
        message:
            'I would like to join this circle for my regular work commute.',
      ),
    );
  }

  @override
  Future<RepositoryResult<List<CommuteCircle>>> applyMembershipDecision({
    required List<CommuteCircle> circles,
    required CommuteRequest request,
    required CommuteRequestStatus status,
  }) async {
    if (status != CommuteRequestStatus.accepted ||
        request.type != CommuteRequestType.joinCircle ||
        request.circleId == null) {
      return RepositoryResult.data(circles);
    }
    return RepositoryResult.data(
      circles.map((circle) {
        if (circle.id != request.circleId) return circle;
        final alreadyMember = circle.members.any(
          (member) => member.profileId == request.requesterProfileId,
        );
        if (alreadyMember) return circle;
        final members = [
          ...circle.members,
          CircleMember(
            profileId: request.requesterProfileId,
            role: CircleMemberRole.passenger,
          ),
        ];
        final seats = (circle.availableSeats - request.seatsRequired).clamp(
          0,
          99,
        );
        return circle.copyWith(
          members: members,
          availableSeats: seats,
          state: seats == 0
              ? CommuteCircleState.full
              : CommuteCircleState.active,
          activity: [
            CircleActivity(
              id: 'activity-${DateTime.now().microsecondsSinceEpoch}',
              label: 'Join request accepted by circle organiser',
              createdAt: DateTime.now(),
            ),
            ...circle.activity,
          ],
        );
      }).toList(),
    );
  }

  @override
  Future<RepositoryResult<List<CommuteCircle>>> pauseParticipation({
    required List<CommuteCircle> circles,
    required String circleId,
    required String profileId,
    required bool paused,
  }) async => RepositoryResult.data(
    circles.map((circle) {
      if (circle.id != circleId) return circle;
      final members = circle.members
          .map(
            (member) => member.profileId == profileId
                ? member.copyWith(
                    status: paused
                        ? CircleParticipationStatus.paused
                        : CircleParticipationStatus.active,
                  )
                : member,
          )
          .toList();
      return circle.copyWith(
        members: members,
        state: paused ? CommuteCircleState.paused : CommuteCircleState.active,
      );
    }).toList(),
  );

  @override
  Future<RepositoryResult<List<CommuteCircle>>> leaveCircle({
    required List<CommuteCircle> circles,
    required String circleId,
    required String profileId,
  }) async => RepositoryResult.data(
    circles.map((circle) {
      if (circle.id != circleId) return circle;
      final wasMember = circle.members.any(
        (member) => member.profileId == profileId,
      );
      final members = circle.members
          .where((member) => member.profileId != profileId)
          .toList();
      return circle.copyWith(
        members: members,
        availableSeats: wasMember
            ? (circle.availableSeats + 1).clamp(0, 99)
            : circle.availableSeats,
        state: CommuteCircleState.forming,
      );
    }).toList(),
  );
}

class MockJourneyRepository implements JourneyRepository {
  @override
  Future<RepositoryResult<List<JourneyOccurrence>>> getJourneys() async =>
      RepositoryResult.data(MockData.journeys());
}

class MockReliabilityRepository implements ReliabilityRepository {
  @override
  Future<RepositoryResult<CommuteReliabilityProfile>> getForProfile(
    String id,
  ) async => RepositoryResult.data(MockData.reliabilityFor(id));
}

class MockWorkplaceVerificationRepository
    implements WorkplaceVerificationRepository {
  @override
  Future<RepositoryResult<WorkplaceVerificationSession>> start({
    required String workplaceId,
    required String worksiteId,
    required String email,
  }) async {
    final workplace = MockData.workplaces
        .where((item) => item.id == workplaceId)
        .firstOrNull;
    if (workplace == null ||
        !workplace.worksites.any((site) => site.id == worksiteId)) {
      return const RepositoryResult.failure('Choose an approved worksite.');
    }
    if (!email.contains('@') || !email.contains('.')) {
      return const RepositoryResult.failure(
        'Enter a valid work email address.',
      );
    }
    return RepositoryResult.data(
      WorkplaceVerificationSession(
        id: 'verify-${DateTime.now().microsecondsSinceEpoch}',
        workplaceId: workplaceId,
        worksiteId: worksiteId,
        email: email,
        status: WorkplaceVerificationStatus.codeSent,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(minutes: 15)),
      ),
    );
  }

  @override
  Future<RepositoryResult<bool>> verify({
    required String workplaceId,
    required String worksiteId,
    required String email,
    required String code,
  }) async {
    final session = await start(
      workplaceId: workplaceId,
      worksiteId: worksiteId,
      email: email,
    );
    if (session.hasError) {
      return RepositoryResult.failure(session.errorMessage);
    }
    return RepositoryResult.data(code == AppConstants.mockCode);
  }
}

class MockCommuteRequestRepository implements CommuteRequestRepository {
  @override
  Future<RepositoryResult<List<CommuteRequest>>> getRequests() async =>
      RepositoryResult.data(MockData.commuteRequests());
}

class MockMessagingRepository implements MessagingRepository {
  @override
  Future<RepositoryResult<MessageThread>> getOrCreateCircleThread({
    required List<MessageThread> threads,
    required CommuteCircle circle,
    required String requesterProfileId,
  }) async {
    final isMember = circle.members.any(
      (member) =>
          member.profileId == requesterProfileId &&
          member.status == CircleParticipationStatus.active,
    );
    if (!isMember) {
      return const RepositoryResult.failure(
        'Secure messaging is available after circle membership is accepted.',
      );
    }
    final existing = threads
        .where(
          (thread) =>
              thread.type == MessageThreadType.commuteCircle &&
              thread.contextId == circle.id,
        )
        .firstOrNull;
    if (existing != null) return RepositoryResult.data(existing);
    return RepositoryResult.data(
      MessageThread(
        id: 'thread-${circle.id}',
        type: MessageThreadType.commuteCircle,
        contextId: circle.id,
        participantProfileIds: circle.members
            .map((member) => member.profileId)
            .toList(),
        messages: [
          CommuteMessage(
            id: 'message-${DateTime.now().microsecondsSinceEpoch}',
            threadId: 'thread-${circle.id}',
            senderProfileId: 'system',
            body:
                'Secure circle messaging is enabled for accepted members. It is asynchronous in this prototype and not real-time chat.',
            sentAt: DateTime.now(),
          ),
        ],
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<RepositoryResult<MessageThread>> sendMessage({
    required MessageThread thread,
    required String senderProfileId,
    required String body,
  }) async {
    final trimmed = body.trim();
    if (!thread.canAccess(senderProfileId)) {
      return const RepositoryResult.failure(
        'You do not have access to this message thread.',
      );
    }
    if (trimmed.isEmpty) {
      return const RepositoryResult.failure('Enter a message before sending.');
    }
    if (trimmed.length > 500) {
      return const RepositoryResult.failure(
        'Keep prototype messages under 500 characters.',
      );
    }
    final lowered = trimmed.toLowerCase();
    final flagged =
        lowered.contains('home address') ||
        lowered.contains('phone number') ||
        lowered.contains('cash');
    final message = CommuteMessage(
      id: 'message-${DateTime.now().microsecondsSinceEpoch}',
      threadId: thread.id,
      senderProfileId: senderProfileId,
      body: trimmed,
      sentAt: DateTime.now(),
      deliveryState: flagged
          ? MessageDeliveryState.flagged
          : MessageDeliveryState.stored,
    );
    return RepositoryResult.data(
      thread.copyWith(messages: [...thread.messages, message]),
    );
  }

  @override
  Future<RepositoryResult<MessageModerationReport>> reportMessage({
    required MessageThread thread,
    required CommuteMessage message,
    required String reporterProfileId,
    required String reason,
  }) async {
    if (!thread.canAccess(reporterProfileId)) {
      return const RepositoryResult.failure(
        'You do not have access to this message thread.',
      );
    }
    return RepositoryResult.data(
      MessageModerationReport(
        id: 'report-${DateTime.now().microsecondsSinceEpoch}',
        threadId: thread.id,
        messageId: message.id,
        reporterProfileId: reporterProfileId,
        reason: reason.trim().isEmpty ? 'No reason supplied' : reason.trim(),
        createdAt: DateTime.now(),
      ),
    );
  }
}
