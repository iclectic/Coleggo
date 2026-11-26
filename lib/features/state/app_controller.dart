import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock/mock_data.dart';
import '../../data/models/app_state.dart';
import '../../data/models/cancellation_record.dart';
import '../../data/models/commute.dart';
import '../../data/models/commute_request.dart';
import '../../data/models/commuter_profile.dart';
import '../../data/models/journey.dart';
import '../../data/models/notification_record.dart';
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
    var next = restored.copyWith(isLoading: false);
    if (ref.read(backendModeEnabledProvider) &&
        next.profile != null &&
        next.commute != null) {
      final token = await ref.read(tokenStorageServiceProvider).readToken();
      if (token != null && token.isNotEmpty) {
        final result = await ref
            .read(authRepositoryProvider)
            .migrateLocalState(next);
        if (result.hasError || result.value == null) {
          next = next.copyWith(
            errorMessage: result.errorMessage ??
                'Your local commute data could not be moved to the server.',
          );
        }
      }
    }
    state = next;
  }

  Future<bool> migrateLocalStateToBackend() async {
    if (!ref.read(backendModeEnabledProvider)) return false;
    final result = await ref
        .read(authRepositoryProvider)
        .migrateLocalState(state);
    if (result.hasError || result.value == null) {
      state = state.copyWith(
        errorMessage: result.errorMessage ??
            'Your local commute data could not be moved to the server.',
      );
      return false;
    }
    return true;
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

  Future<AppState> _withNotification(
    AppState base, {
    required CommuteNotificationType type,
    required String title,
    required String body,
    required CommuteNotificationPriority priority,
    String? contextRoute,
  }) async {
    final result = await ref
        .read(notificationRepositoryProvider)
        .create(
          type: type,
          title: title,
          body: body,
          priority: priority,
          contextRoute: contextRoute,
        );
    if (result.hasError || result.value == null) return base;
    return base.copyWith(notifications: [result.value!, ...base.notifications]);
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

  Future<bool> startWorkEmailVerification(String email) async {
    final workplaceId = state.selectedWorkplaceId;
    final worksiteId = state.selectedWorksiteId;
    if (workplaceId == null || worksiteId == null) return false;
    final result = await ref
        .read(workplaceVerificationRepositoryProvider)
        .start(workplaceId: workplaceId, worksiteId: worksiteId, email: email);
    if (result.hasError || result.value == null) {
      state = state.copyWith(
        errorMessage:
            result.errorMessage ?? 'Your verification code was not sent.',
      );
      return false;
    }
    return true;
  }

  Future<bool> verifyWorkEmail(String email, String code) async {
    final workplaceId = state.selectedWorkplaceId;
    final worksiteId = state.selectedWorksiteId;
    if (workplaceId == null || worksiteId == null) return false;
    final result = await ref
        .read(workplaceVerificationRepositoryProvider)
        .verify(
          workplaceId: workplaceId,
          worksiteId: worksiteId,
          email: email,
          code: code,
        );
    if (result.hasError || result.value != true) return false;
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
    final result = await ref
        .read(commuteCircleRepositoryProvider)
        .requestToJoin(
          currentRequests: state.commuteRequests,
          requesterProfileId: profile.id,
          circleId: circleId,
          commute: commute,
          profile: profile,
        );
    if (result.hasError || result.value == null) {
      state = state.copyWith(
        errorMessage: result.errorMessage ?? 'Your join request was not sent.',
      );
      return false;
    }
    final next = await _withNotification(
      state.copyWith(
        commuteRequests: [...state.commuteRequests, result.value!],
      ),
      type: CommuteNotificationType.joinRequest,
      title: 'Circle request sent',
      body: 'Your request to join this Commute Circle has been saved.',
      priority: CommuteNotificationPriority.normal,
      contextRoute: '/circles/$circleId',
    );
    await _setAndPersist(next);
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
    final membershipResult = await ref
        .read(commuteCircleRepositoryProvider)
        .applyMembershipDecision(
          circles: state.circles,
          request: currentRequest,
          status: status,
        );
    if (!membershipResult.hasError && membershipResult.value != null) {
      circles = membershipResult.value!;
    }
    if (status == CommuteRequestStatus.accepted &&
        currentRequest.type == CommuteRequestType.joinCircle &&
        currentRequest.circleId != null) {
      activeCircleId = currentRequest.circleId;
    }
    var next = state.copyWith(
      commuteRequests: requests,
      circles: circles,
      activeCircleId: activeCircleId,
    );
    if (status == CommuteRequestStatus.accepted) {
      next = await _withNotification(
        next,
        type: CommuteNotificationType.joinRequest,
        title: 'Circle request accepted',
        body: 'A colleague has been added to the Commute Circle.',
        priority: CommuteNotificationPriority.actionRequired,
        contextRoute: currentRequest.circleId == null
            ? '/requests'
            : '/circles/${currentRequest.circleId}',
      );
    }
    await _setAndPersist(next);
  }

  Future<void> pauseCircleParticipation(String circleId, bool paused) async {
    final profileId = state.profile?.id;
    if (profileId == null) return;
    final result = await ref
        .read(commuteCircleRepositoryProvider)
        .pauseParticipation(
          circles: state.circles,
          circleId: circleId,
          profileId: profileId,
          paused: paused,
        );
    if (result.hasError || result.value == null) {
      state = state.copyWith(
        errorMessage:
            result.errorMessage ?? 'Your circle participation was not updated.',
      );
      return;
    }
    await _setAndPersist(state.copyWith(circles: result.value));
  }

  Future<void> leaveCircle(String circleId) async {
    final profileId = state.profile?.id;
    if (profileId == null) return;
    final result = await ref
        .read(commuteCircleRepositoryProvider)
        .leaveCircle(
          circles: state.circles,
          circleId: circleId,
          profileId: profileId,
        );
    if (result.hasError || result.value == null) {
      state = state.copyWith(
        errorMessage: result.errorMessage ?? 'You could not leave this circle.',
      );
      return;
    }
    await _setAndPersist(
      state.copyWith(
        circles: result.value,
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
    final selectedJourney = state.journeys
        .where((item) => item.id == journeyId)
        .firstOrNull;
    if (selectedJourney == null) return;
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
    final next = await _withNotification(
      state.copyWith(journeys: journeys),
      type: CommuteNotificationType.journeyConfirmation,
      title: 'Journey response saved',
      body: 'Your attendance response has been recorded for the next commute.',
      priority: status == JourneyAttendanceStatus.undecided
          ? CommuteNotificationPriority.normal
          : CommuteNotificationPriority.actionRequired,
      contextRoute: '/circles/${selectedJourney.circleId}',
    );
    await _setAndPersist(next);
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
    final next = await _withNotification(
      state.copyWith(
        journeys: journeys,
        cancellationHistory: [...state.cancellationHistory, cancellation],
      ),
      type: CommuteNotificationType.cancellation,
      title: 'Journey cancelled',
      body:
          '${cancellation.affectedProfileIds.length} circle members are affected.',
      priority: CommuteNotificationPriority.urgent,
      contextRoute: '/circles/${journey.circleId}',
    );
    await _setAndPersist(next);
  }

  Future<void> selectBackupDriver(String journeyId, String profileId) async {
    final selectedJourney = state.journeys
        .where((item) => item.id == journeyId)
        .firstOrNull;
    if (selectedJourney == null) return;
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
    final next = await _withNotification(
      state.copyWith(journeys: journeys),
      type: CommuteNotificationType.backupDriver,
      title: 'Backup driver selected',
      body: 'A replacement driver has been selected for the commute.',
      priority: CommuteNotificationPriority.actionRequired,
      contextRoute: '/circles/${selectedJourney.circleId}',
    );
    await _setAndPersist(next);
  }

  Future<String?> openCircleThread(String circleId) async {
    final profileId = state.profile?.id;
    if (profileId == null) return null;
    final circle = state.circles
        .where((item) => item.id == circleId)
        .firstOrNull;
    if (circle == null) return null;
    final result = await ref
        .read(messagingRepositoryProvider)
        .getOrCreateCircleThread(
          threads: state.messageThreads,
          circle: circle,
          requesterProfileId: profileId,
        );
    if (result.hasError || result.value == null) {
      state = state.copyWith(
        errorMessage:
            result.errorMessage ?? 'Secure messaging is not available yet.',
      );
      return null;
    }
    final thread = result.value!;
    final threads = [
      ...state.messageThreads.where((item) => item.id != thread.id),
      thread,
    ];
    await _setAndPersist(state.copyWith(messageThreads: threads));
    return thread.id;
  }

  Future<bool> sendThreadMessage(String threadId, String body) async {
    final profileId = state.profile?.id;
    if (profileId == null) return false;
    final thread = state.messageThreads
        .where((item) => item.id == threadId)
        .firstOrNull;
    if (thread == null) return false;
    final result = await ref
        .read(messagingRepositoryProvider)
        .sendMessage(thread: thread, senderProfileId: profileId, body: body);
    if (result.hasError || result.value == null) {
      state = state.copyWith(
        errorMessage: result.errorMessage ?? 'Your message was not saved.',
      );
      return false;
    }
    final threads = state.messageThreads
        .map((item) => item.id == threadId ? result.value! : item)
        .toList();
    final next = await _withNotification(
      state.copyWith(messageThreads: threads),
      type: CommuteNotificationType.message,
      title: 'Message saved',
      body: 'Your secure circle message has been stored locally.',
      priority: CommuteNotificationPriority.normal,
      contextRoute: '/messages/$threadId',
    );
    await _setAndPersist(next);
    return true;
  }

  Future<void> markNotificationRead(String notificationId) async {
    final result = await ref
        .read(notificationRepositoryProvider)
        .markRead(
          notifications: state.notifications,
          notificationId: notificationId,
        );
    if (!result.hasError && result.value != null) {
      await _setAndPersist(state.copyWith(notifications: result.value));
    }
  }

  Future<void> markAllNotificationsRead() async {
    final result = await ref
        .read(notificationRepositoryProvider)
        .markAllRead(notifications: state.notifications);
    if (!result.hasError && result.value != null) {
      await _setAndPersist(state.copyWith(notifications: result.value));
    }
  }

  Future<bool> reportThreadMessage({
    required String threadId,
    required String messageId,
    required String reason,
  }) async {
    final profileId = state.profile?.id;
    if (profileId == null) return false;
    final thread = state.messageThreads
        .where((item) => item.id == threadId)
        .firstOrNull;
    final message = thread?.messages
        .where((item) => item.id == messageId)
        .firstOrNull;
    if (thread == null || message == null) return false;
    final result = await ref
        .read(messagingRepositoryProvider)
        .reportMessage(
          thread: thread,
          message: message,
          reporterProfileId: profileId,
          reason: reason,
        );
    if (result.hasError || result.value == null) {
      state = state.copyWith(
        errorMessage: result.errorMessage ?? 'The report was not submitted.',
      );
      return false;
    }
    await _setAndPersist(
      state.copyWith(messageReports: [...state.messageReports, result.value!]),
    );
    return true;
  }

  Future<void> setTheme(AppThemePreference preference) =>
      _setAndPersist(state.copyWith(themePreference: preference));

  Future<void> selectTab(int index) =>
      _setAndPersist(state.copyWith(selectedTab: index));

  Future<void> reset() async {
    await ref.read(commuteRepositoryProvider).clearState();
    state = const AppState();
  }

  Future<Map<String, dynamic>?> exportAccountData() async {
    if (!ref.read(backendModeEnabledProvider)) return null;
    final result = await ref.read(authRepositoryProvider).exportAccountData();
    if (result.hasError) {
      state = state.copyWith(
        errorMessage: result.errorMessage ?? 'Your data export could not be prepared.',
      );
      return null;
    }
    return result.data;
  }

  Future<bool> deleteAccount() async {
    if (!ref.read(backendModeEnabledProvider)) return false;
    final result = await ref.read(authRepositoryProvider).deleteAccount();
    if (result.hasError) {
      state = state.copyWith(
        errorMessage: result.errorMessage ?? 'Your account could not be deleted.',
      );
      return false;
    }
    await reset();
    return true;
  }

  void dismissError() => state = state.copyWith(clearError: true);
}
