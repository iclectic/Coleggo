import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../data/mock/mock_data.dart';
import '../../data/models/app_state.dart';
import '../../data/models/cancellation_record.dart';
import '../../data/models/commute.dart';
import '../../data/models/commute_circle.dart';
import '../../data/models/commute_request.dart';
import '../../data/models/commuter_profile.dart';
import '../../data/models/journey.dart';
import '../../data/models/ride_request.dart';
import 'providers.dart';

class AppController extends Notifier<AppState> {
  @override
  AppState build() {
    Future<void>.microtask(_restore);
    return const AppState(isLoading: true);
  }

  Future<void> _restore() async {
    final restored = await ref.read(commuteRepositoryProvider).loadState();
    state = restored.copyWith(isLoading: false);
  }

  Future<void> _setAndPersist(AppState next) async {
    state = next.copyWith(isLoading: false, clearError: true);
    try {
      await ref.read(commuteRepositoryProvider).saveState(state);
    } on Object {
      state = state.copyWith(
        errorMessage:
            'Your change was kept for this session but could not be saved.',
      );
    }
  }

  Future<void> completeOnboarding() =>
      _setAndPersist(state.copyWith(onboardingComplete: true));

  Future<void> selectWorkplace(String workplaceId, String worksiteId) =>
      _setAndPersist(
        state.copyWith(
          selectedWorkplaceId: workplaceId,
          selectedWorksiteId: worksiteId,
          workplaceVerified: false,
        ),
      );

  Future<bool> verifyWorkEmail(String email, String code) async {
    if (code != AppConstants.mockCode) return false;
    await _setAndPersist(
      state.copyWith(workEmail: email, workplaceVerified: true),
    );
    return true;
  }

  Future<void> saveProfileAndCommute(CommuterProfile profile) async {
    final commute = ref.read(commuteRepositoryProvider).createFor(profile);
    final requests = state.requests.isEmpty
        ? ref.read(rideRequestRepositoryProvider).seededRequests()
        : state.requests;
    final circles = state.circles.isEmpty
        ? MockData.commuteCircles()
        : state.circles;
    final journeys = state.journeys.isEmpty
        ? MockData.journeys()
        : state.journeys;
    final commuteRequests = state.commuteRequests.isEmpty
        ? MockData.commuteRequests()
        : state.commuteRequests;
    final reliabilityProfiles = state.reliabilityProfiles.isEmpty
        ? [MockData.reliabilityFor(profile.id)]
        : state.reliabilityProfiles;
    await _setAndPersist(
      state.copyWith(
        profile: profile,
        commute: commute,
        requests: requests,
        circles: circles,
        journeys: journeys,
        commuteRequests: commuteRequests,
        reliabilityProfiles: reliabilityProfiles,
        activeCircleId: circles.first.id,
      ),
    );
  }

  Future<void> updateCommute(Commute commute) {
    final profile = state.profile;
    final updatedProfile = profile?.copyWith(
      homeArea: commute.homeArea,
      corridor: MockData.areaCorridors[commute.homeArea],
      worksiteId: commute.worksiteId,
      days: commute.days,
      arrivalMinutes: commute.arrivalMinutes,
      departureMinutes: commute.departureMinutes,
    );
    return _setAndPersist(
      state.copyWith(commute: commute, profile: updatedProfile),
    );
  }

  Future<bool> sendRequest(String profileId, RequestKind kind) async {
    final duplicate = state.requests.any(
      (request) =>
          request.profileId == profileId &&
          request.status == RequestStatus.pending,
    );
    if (duplicate) return false;
    final profile = ref.read(profileRepositoryProvider).getById(profileId);
    final request = RideRequest(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      profileId: profileId,
      direction: RequestDirection.outgoing,
      kind: kind,
      status: RequestStatus.pending,
      createdAt: DateTime.now(),
      recurringDays: state.profile?.days.intersection(profile.days) ?? const {},
    );
    await _setAndPersist(
      state.copyWith(requests: [...state.requests, request]),
    );
    return true;
  }

  Future<void> updateRequest(String id, RequestStatus status) async {
    final requests = state.requests.map((request) {
      if (request.id != id) return request;
      final allowed = switch ((request.direction, request.status, status)) {
        (
          RequestDirection.incoming,
          RequestStatus.pending,
          RequestStatus.accepted,
        ) =>
          true,
        (
          RequestDirection.incoming,
          RequestStatus.pending,
          RequestStatus.declined,
        ) =>
          true,
        (
          RequestDirection.outgoing,
          RequestStatus.pending,
          RequestStatus.cancelled,
        ) =>
          true,
        _ => false,
      };
      return allowed ? request.copyWith(status: status) : request;
    }).toList();
    await _setAndPersist(state.copyWith(requests: requests));
  }

  Future<bool> requestToJoinCircle(String circleId) async {
    final profile = state.profile;
    final commute = state.commute;
    if (profile == null || commute == null) return false;
    final duplicate = state.commuteRequests.any(
      (request) =>
          request.circleId == circleId &&
          request.requesterProfileId == profile.id &&
          request.type == CommuteRequestType.joinCircle &&
          request.isActive,
    );
    if (duplicate) return false;
    final request = CommuteRequest(
      id: 'circle-${DateTime.now().microsecondsSinceEpoch}',
      requesterProfileId: profile.id,
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
      message: 'I would like to join this circle for my regular work commute.',
    );
    await _setAndPersist(
      state.copyWith(commuteRequests: [...state.commuteRequests, request]),
    );
    return true;
  }

  Future<void> updateCommuteRequest(
    String id,
    CommuteRequestStatus status,
  ) async {
    final currentRequest = state.commuteRequests
        .where((request) => request.id == id)
        .firstOrNull;
    if (currentRequest == null) return;
    final requests = state.commuteRequests
        .map(
          (request) =>
              request.id == id ? request.copyWith(status: status) : request,
        )
        .toList();
    var circles = state.circles;
    var activeCircleId = state.activeCircleId;
    if (status == CommuteRequestStatus.accepted &&
        currentRequest.type == CommuteRequestType.joinCircle &&
        currentRequest.circleId != null) {
      circles = circles.map((circle) {
        if (circle.id != currentRequest.circleId) return circle;
        final alreadyMember = circle.members.any(
          (member) => member.profileId == currentRequest.requesterProfileId,
        );
        if (alreadyMember) return circle;
        final members = [
          ...circle.members,
          CircleMember(
            profileId: currentRequest.requesterProfileId,
            role: CircleMemberRole.passenger,
          ),
        ];
        final seats = (circle.availableSeats - currentRequest.seatsRequired)
            .clamp(0, 99);
        return circle.copyWith(
          members: members,
          availableSeats: seats,
          state: seats == 0
              ? CommuteCircleState.full
              : CommuteCircleState.active,
          activity: [
            CircleActivity(
              id: 'activity-${DateTime.now().microsecondsSinceEpoch}',
              label: 'Join request accepted',
              createdAt: DateTime.now(),
            ),
            ...circle.activity,
          ],
        );
      }).toList();
      activeCircleId = currentRequest.circleId;
    }
    await _setAndPersist(
      state.copyWith(
        commuteRequests: requests,
        circles: circles,
        activeCircleId: activeCircleId,
      ),
    );
  }

  Future<void> pauseCircleParticipation(String circleId, bool paused) async {
    final profileId = state.profile?.id;
    if (profileId == null) return;
    final circles = state.circles.map((circle) {
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
    }).toList();
    await _setAndPersist(state.copyWith(circles: circles));
  }

  Future<void> leaveCircle(String circleId) async {
    final profileId = state.profile?.id;
    if (profileId == null) return;
    final circles = state.circles.map((circle) {
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
    }).toList();
    await _setAndPersist(
      state.copyWith(
        circles: circles,
        activeCircleId: state.activeCircleId == circleId
            ? null
            : state.activeCircleId,
      ),
    );
  }

  Future<void> setJourneyAttendance(
    String journeyId,
    JourneyAttendanceStatus status,
  ) async {
    final profileId = state.profile?.id;
    if (profileId == null) return;
    final journeys = state.journeys.map((journey) {
      if (journey.id != journeyId) return journey;
      final attendance = [
        ...journey.attendance.where((item) => item.profileId != profileId),
        JourneyAttendance(
          profileId: profileId,
          status: status,
          updatedAt: DateTime.now(),
        ),
      ];
      return journey.copyWith(attendance: attendance);
    }).toList();
    await _setAndPersist(state.copyWith(journeys: journeys));
  }

  Future<void> cancelJourney(String journeyId, {String? reason}) async {
    final journey = state.journeys
        .where((item) => item.id == journeyId)
        .firstOrNull;
    final profileId = state.profile?.id;
    if (journey == null || profileId == null) return;
    final cancellation = CancellationRecord(
      id: 'cancel-${DateTime.now().microsecondsSinceEpoch}',
      journeyId: journey.id,
      cancelledByProfileId: profileId,
      actor: CancellationActor.driver,
      cancelledAt: DateTime.now(),
      affectedProfileIds: journey.memberIds
          .where((memberId) => memberId != profileId)
          .toList(),
      reason: reason ?? 'Driver cancelled in prototype flow',
    );
    final journeys = state.journeys
        .map(
          (item) => item.id == journeyId
              ? item.copyWith(
                  status: JourneyStatus.cancelled,
                  cancellation: cancellation,
                )
              : item,
        )
        .toList();
    await _setAndPersist(
      state.copyWith(
        journeys: journeys,
        cancellationHistory: [...state.cancellationHistory, cancellation],
      ),
    );
  }

  Future<void> selectBackupDriver(String journeyId, String profileId) async {
    final journeys = state.journeys
        .map(
          (journey) => journey.id == journeyId
              ? journey.copyWith(
                  status: JourneyStatus.confirmed,
                  backupPlan: journey.backupPlan.copyWith(
                    backupDriverId: profileId,
                  ),
                )
              : journey,
        )
        .toList();
    await _setAndPersist(state.copyWith(journeys: journeys));
  }

  Future<void> setTheme(AppThemePreference preference) =>
      _setAndPersist(state.copyWith(themePreference: preference));

  Future<void> selectTab(int index) =>
      _setAndPersist(state.copyWith(selectedTab: index));

  Future<void> reset() async {
    await ref.read(commuteRepositoryProvider).clearState();
    state = const AppState();
  }

  void dismissError() => state = state.copyWith(clearError: true);
}
