import '../models/app_state.dart';
import '../models/commute.dart';
import '../models/commute_circle.dart';
import '../models/commute_request.dart';
import '../models/commuter_profile.dart';
import '../models/journey.dart';
import '../models/message_thread.dart';
import '../models/notification_record.dart';
import '../models/match_result.dart';
import '../models/reliability_profile.dart';
import '../models/ride_request.dart';
import '../models/workplace.dart';
import '../models/workplace_verification.dart';

class RepositoryResult<T> {
  const RepositoryResult.data(this.value) : errorMessage = null;
  const RepositoryResult.failure(this.errorMessage) : value = null;

  final T? value;
  final String? errorMessage;

  bool get hasError => errorMessage != null;
}

abstract interface class WorkplaceRepository {
  List<Workplace> getWorkplaces();
}

abstract interface class ProfileRepository {
  List<CommuterProfile> getCommuters();
  CommuterProfile getById(String id);
}

abstract interface class CommuteRepository {
  Future<AppState> loadState();
  Future<void> saveState(AppState state);
  Future<void> clearState();
  Commute createFor(CommuterProfile profile);
}

abstract interface class MatchRepository {
  List<MatchResult> getMatches(CommuterProfile profile);
  MatchResult getMatch(CommuterProfile profile, String candidateId);
}

abstract interface class RideRequestRepository {
  List<RideRequest> seededRequests();
}

abstract interface class CommuteCircleRepository {
  Future<RepositoryResult<List<CommuteCircle>>> getCircles();
  Future<RepositoryResult<CommuteCircle>> getCircle(String id);
  Future<RepositoryResult<CommuteRequest>> requestToJoin({
    required List<CommuteRequest> currentRequests,
    required String requesterProfileId,
    required String circleId,
    required Commute commute,
    required CommuterProfile profile,
  });
  Future<RepositoryResult<List<CommuteCircle>>> applyMembershipDecision({
    required List<CommuteCircle> circles,
    required CommuteRequest request,
    required CommuteRequestStatus status,
  });
  Future<RepositoryResult<List<CommuteCircle>>> pauseParticipation({
    required List<CommuteCircle> circles,
    required String circleId,
    required String profileId,
    required bool paused,
  });
  Future<RepositoryResult<List<CommuteCircle>>> leaveCircle({
    required List<CommuteCircle> circles,
    required String circleId,
    required String profileId,
  });
}

abstract interface class JourneyRepository {
  Future<RepositoryResult<List<JourneyOccurrence>>> getJourneys();
}

abstract interface class ReliabilityRepository {
  Future<RepositoryResult<CommuteReliabilityProfile>> getForProfile(String id);
}

abstract interface class WorkplaceVerificationRepository {
  Future<RepositoryResult<WorkplaceVerificationSession>> start({
    required String workplaceId,
    required String worksiteId,
    required String email,
  });
  Future<RepositoryResult<bool>> verify({
    required String workplaceId,
    required String worksiteId,
    required String email,
    required String code,
  });
}

abstract interface class CommuteRequestRepository {
  Future<RepositoryResult<List<CommuteRequest>>> getRequests();
}

abstract interface class MessagingRepository {
  Future<RepositoryResult<MessageThread>> getOrCreateCircleThread({
    required List<MessageThread> threads,
    required CommuteCircle circle,
    required String requesterProfileId,
  });
  Future<RepositoryResult<MessageThread>> sendMessage({
    required MessageThread thread,
    required String senderProfileId,
    required String body,
  });
  Future<RepositoryResult<MessageModerationReport>> reportMessage({
    required MessageThread thread,
    required CommuteMessage message,
    required String reporterProfileId,
    required String reason,
  });
}

abstract interface class NotificationRepository {
  Future<RepositoryResult<CommuteNotification>> create({
    required CommuteNotificationType type,
    required String title,
    required String body,
    required CommuteNotificationPriority priority,
    String? contextRoute,
  });
  Future<RepositoryResult<List<CommuteNotification>>> markRead({
    required List<CommuteNotification> notifications,
    required String notificationId,
  });
  Future<RepositoryResult<List<CommuteNotification>>> markAllRead({
    required List<CommuteNotification> notifications,
  });
}
