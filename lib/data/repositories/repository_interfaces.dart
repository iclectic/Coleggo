import '../models/app_state.dart';
import '../models/commute.dart';
import '../models/commute_circle.dart';
import '../models/commute_request.dart';
import '../models/commuter_profile.dart';
import '../models/journey.dart';
import '../models/match_result.dart';
import '../models/reliability_profile.dart';
import '../models/ride_request.dart';
import '../models/workplace.dart';

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
}

abstract interface class JourneyRepository {
  Future<RepositoryResult<List<JourneyOccurrence>>> getJourneys();
}

abstract interface class ReliabilityRepository {
  Future<RepositoryResult<CommuteReliabilityProfile>> getForProfile(String id);
}

abstract interface class WorkplaceVerificationRepository {
  Future<RepositoryResult<bool>> verify({
    required String email,
    required String code,
  });
}

abstract interface class CommuteRequestRepository {
  Future<RepositoryResult<List<CommuteRequest>>> getRequests();
}
