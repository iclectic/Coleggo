import 'package:coleggo/data/models/app_state.dart';
import 'package:coleggo/data/models/commuter_profile.dart';
import 'package:coleggo/data/repositories/backend_repositories.dart';
import 'package:coleggo/data/services/backend_api_client.dart';
import 'package:coleggo/data/services/token_storage_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BackendAuthRepository migration', () {
    test('returns failure when local state has no profile', () async {
      final client = BackendApiClient(
        tokenStorage: const TokenStorageService(FlutterSecureStorage()),
      );
      final repository = BackendAuthRepository(client);

      final result = await repository.migrateLocalState(const AppState());

      expect(result.hasError, isTrue);
      expect(result.errorMessage, contains('No local profile'));
    });

    test('returns failure when local state has no commute', () async {
      final client = BackendApiClient(
        tokenStorage: const TokenStorageService(FlutterSecureStorage()),
      );
      final repository = BackendAuthRepository(client);

      final result = await repository.migrateLocalState(
        const AppState(
          profile: CommuterProfile(
            id: 'p1',
            firstName: 'Alex',
            initials: 'AL',
            role: CommuteRole.passenger,
            workplaceId: 'northstar',
            worksiteId: 'central_exchange',
            homeArea: 'Bearwood',
            corridor: 'West Birmingham to city centre',
            days: {1, 3, 5},
            arrivalMinutes: 510,
            departureMinutes: 1050,
          ),
        ),
      );

      expect(result.hasError, isTrue);
      expect(result.errorMessage, contains('No local profile'));
    });
  });
}
