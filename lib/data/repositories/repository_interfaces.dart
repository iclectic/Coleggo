import '../models/app_state.dart';
import '../models/commute.dart';
import '../models/commuter_profile.dart';
import '../models/match_result.dart';
import '../models/ride_request.dart';
import '../models/workplace.dart';

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
