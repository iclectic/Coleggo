import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/app_state.dart';
import '../../data/models/commuter_profile.dart';
import '../../data/models/match_result.dart';
import '../../data/repositories/backend_circle_repository.dart';
import '../../data/repositories/backend_domain_repositories.dart';
import '../../data/repositories/backend_journey_repository.dart';
import '../../data/repositories/backend_messaging_repository.dart';
import '../../data/repositories/backend_repositories.dart';
import '../../data/repositories/local_repositories.dart';
import '../../data/repositories/repository_interfaces.dart';
import '../../data/services/backend_api_client.dart';
import '../../data/services/local_storage_service.dart';
import '../../data/services/matching_service.dart';
import '../../data/services/token_storage_service.dart';
import 'app_controller.dart';

const _secureStorage = FlutterSecureStorage();
const _useBackend = bool.fromEnvironment('COLEGGO_USE_BACKEND');

final backendModeEnabledProvider = Provider<bool>((ref) => _useBackend);

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('SharedPreferences must be overridden'),
);

final storageServiceProvider = Provider(
  (ref) => LocalStorageService(ref.watch(sharedPreferencesProvider)),
);

final tokenStorageServiceProvider = Provider(
  (ref) => const TokenStorageService(_secureStorage),
);

final backendApiClientProvider = Provider(
  (ref) => BackendApiClient(
    tokenStorage: ref.watch(tokenStorageServiceProvider),
    baseUrl: const String.fromEnvironment('COLEGGO_API_BASE_URL', defaultValue: 'http://localhost:3000'),
  ),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => BackendAuthRepository(ref.watch(backendApiClientProvider)),
);

final workplaceRepositoryProvider = Provider<WorkplaceRepository>(
  (ref) => _useBackend
      ? BackendWorkplaceRepository(ref.watch(backendApiClientProvider))
      : MockWorkplaceRepository(),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => MockProfileRepository(),
);

final matchingServiceProvider = Provider((ref) => const MatchingService());

final commuteRepositoryProvider = Provider<CommuteRepository>(
  (ref) => LocalCommuteRepository(ref.watch(storageServiceProvider)),
);

final matchRepositoryProvider = Provider<MatchRepository>(
  (ref) => _useBackend
      ? BackendMatchRepository(ref.watch(backendApiClientProvider))
      : MockMatchRepository(ref.watch(matchingServiceProvider)),
);

final rideRequestRepositoryProvider = Provider<RideRequestRepository>(
  (ref) => MockRideRequestRepository(),
);

final commuteCircleRepositoryProvider = Provider<CommuteCircleRepository>(
  (ref) => _useBackend
      ? BackendCommuteCircleRepository(ref.watch(backendApiClientProvider))
      : MockCommuteCircleRepository(),
);

final journeyRepositoryProvider = Provider<JourneyRepository>(
  (ref) => _useBackend
      ? BackendJourneyRepository(ref.watch(backendApiClientProvider))
      : MockJourneyRepository(),
);

final reliabilityRepositoryProvider = Provider<ReliabilityRepository>(
  (ref) => _useBackend
      ? BackendReliabilityRepository(ref.watch(backendApiClientProvider))
      : MockReliabilityRepository(),
);

final workplaceVerificationRepositoryProvider =
    Provider<WorkplaceVerificationRepository>(
      (ref) => _useBackend
          ? BackendWorkplaceVerificationRepository(
              ref.watch(backendApiClientProvider),
            )
          : MockWorkplaceVerificationRepository(),
    );

final commuteRequestRepositoryProvider = Provider<CommuteRequestRepository>(
  (ref) => MockCommuteRequestRepository(),
);

final messagingRepositoryProvider = Provider<MessagingRepository>(
  (ref) => _useBackend
      ? BackendMessagingRepository(ref.watch(backendApiClientProvider))
      : MockMessagingRepository(),
);

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => _useBackend
      ? BackendNotificationRepository(ref.watch(backendApiClientProvider))
      : MockNotificationRepository(),
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
