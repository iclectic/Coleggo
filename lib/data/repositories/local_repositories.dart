import '../mock/mock_data.dart';
import '../models/app_state.dart';
import '../models/commute.dart';
import '../models/commuter_profile.dart';
import '../models/match_result.dart';
import '../models/ride_request.dart';
import '../models/workplace.dart';
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
