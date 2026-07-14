import 'dart:convert';

import 'package:coleggo/app/app.dart';
import 'package:coleggo/data/mock/mock_data.dart';
import 'package:coleggo/data/models/app_state.dart';
import 'package:coleggo/data/models/commute.dart';
import 'package:coleggo/data/models/commuter_profile.dart';
import 'package:coleggo/data/services/local_storage_service.dart';
import 'package:coleggo/features/state/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('accepting a seeded request opens a recurring commute', (
    tester,
  ) async {
    final profile = CommuterProfile(
      id: 'local-user',
      firstName: 'Alex',
      initials: 'AL',
      role: CommuteRole.passenger,
      workplaceId: 'northstar',
      worksiteId: 'central_exchange',
      homeArea: 'Bearwood',
      corridor: MockData.areaCorridors['Bearwood']!,
      days: const {1, 3, 5},
      arrivalMinutes: 510,
      departureMinutes: 1050,
    );
    final state = AppState(
      onboardingComplete: true,
      selectedWorkplaceId: 'northstar',
      selectedWorksiteId: 'central_exchange',
      workEmail: 'alex@example.invalid',
      workplaceVerified: true,
      profile: profile,
      commute: const Commute(
        id: 'local-commute',
        profileId: 'local-user',
        homeArea: 'Bearwood',
        worksiteId: 'central_exchange',
        days: {1, 3, 5},
        arrivalMinutes: 510,
        departureMinutes: 1050,
        recurring: true,
      ),
      requests: MockData.seededRequests(),
      selectedTab: 2,
    );
    SharedPreferences.setMockInitialValues({
      LocalStorageService.stateKey: jsonEncode(state.toJson()),
    });
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: const ColeggoApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Incoming'), findsOneWidget);
    await tester.tap(find.text('Accept').first);
    await tester.pumpAndSettle();

    expect(find.text('You’re travelling together'), findsOneWidget);
    expect(find.text('Before you travel'), findsOneWidget);
  });
}
