import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/app_state.dart';
import '../../data/models/commuter_profile.dart';
import '../../data/models/match_result.dart';
import '../../data/repositories/local_repositories.dart';
import '../../data/repositories/repository_interfaces.dart';
import '../../data/services/local_storage_service.dart';
import '../../data/services/matching_service.dart';
import 'app_controller.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('SharedPreferences must be overridden'),
);

final storageServiceProvider = Provider(
  (ref) => LocalStorageService(ref.watch(sharedPreferencesProvider)),
);

final workplaceRepositoryProvider = Provider<WorkplaceRepository>(
  (ref) => MockWorkplaceRepository(),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => MockProfileRepository(),
);

final matchingServiceProvider = Provider((ref) => const MatchingService());

final commuteRepositoryProvider = Provider<CommuteRepository>(
  (ref) => LocalCommuteRepository(ref.watch(storageServiceProvider)),
);

final matchRepositoryProvider = Provider<MatchRepository>(
  (ref) => MockMatchRepository(ref.watch(matchingServiceProvider)),
);

final rideRequestRepositoryProvider = Provider<RideRequestRepository>(
  (ref) => MockRideRequestRepository(),
);

final commuteCircleRepositoryProvider = Provider<CommuteCircleRepository>(
  (ref) => MockCommuteCircleRepository(),
);

final journeyRepositoryProvider = Provider<JourneyRepository>(
  (ref) => MockJourneyRepository(),
);

final reliabilityRepositoryProvider = Provider<ReliabilityRepository>(
  (ref) => MockReliabilityRepository(),
);

final workplaceVerificationRepositoryProvider =
    Provider<WorkplaceVerificationRepository>(
      (ref) => MockWorkplaceVerificationRepository(),
    );

final commuteRequestRepositoryProvider = Provider<CommuteRequestRepository>(
  (ref) => MockCommuteRequestRepository(),
);

final appControllerProvider = NotifierProvider<AppController, AppState>(
  AppController.new,
);

final matchesProvider = Provider<List<MatchResult>>((ref) {
  final profile = ref.watch(appControllerProvider).profile;
  if (profile == null) return const [];
  return ref.watch(matchRepositoryProvider).getMatches(profile);
});

final commuterProvider = Provider.family<CommuterProfile, String>(
  (ref, id) => ref.watch(profileRepositoryProvider).getById(id),
);
