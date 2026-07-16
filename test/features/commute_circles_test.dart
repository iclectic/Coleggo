import 'dart:convert';

import 'package:coleggo/app/app.dart';
import 'package:coleggo/data/mock/mock_data.dart';
import 'package:coleggo/data/models/app_state.dart';
import 'package:coleggo/data/models/commute.dart';
import 'package:coleggo/data/models/commuter_profile.dart';
import 'package:coleggo/data/services/local_storage_service.dart';
import 'package:coleggo/features/state/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('dashboard confirms tomorrow’s circle journey', (tester) async {
    await _pumpApp(tester, _state());

    expect(find.text('Next journey'), findsOneWidget);
    expect(find.text('3 of 4 members confirmed for tomorrow'), findsOneWidget);

    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(find.text('4 of 4 members confirmed for tomorrow'), findsOneWidget);
  });

  testWidgets('circle discovery sends a join request once', (tester) async {
    await _pumpApp(tester, _state(selectedTab: 2));

    await tester.tap(
      find
          .ancestor(
            of: find.text('Moseley Late Shift Circle'),
            matching: find.byType(InkWell),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Request to join'), 220);
    await tester.tap(find.text('Request to join'));
    await tester.pumpAndSettle();

    expect(find.text('Join request sent'), findsOneWidget);
  });

  testWidgets('request screen accepts a circle join request', (tester) async {
    await _pumpApp(tester, _state(selectedTab: 3));

    expect(find.text('Commute Circle requests'), findsOneWidget);
    expect(
      find.text('I can join Monday, Wednesday and Friday early shifts.'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(find.text('Accept').last, 220);
    await tester.tap(find.text('Accept').last);
    await tester.pumpAndSettle();

    expect(find.text('Accepted'), findsWidgets);
  });

  testWidgets('circle backup flow records cancellation and replacement', (
    tester,
  ) async {
    await _pumpApp(tester, _state(selectedTab: 2));

    await tester.tap(
      find
          .ancestor(
            of: find.text('Solihull Early Shift Circle'),
            matching: find.byType(InkWell),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Emergency cancellation'), 220);
    await tester.tap(find.text('Emergency cancellation'));
    await tester.pumpAndSettle();

    expect(find.text('Cancelled. 3 passengers affected.'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Choose').first, 220);
    await tester.tap(find.text('Choose').first);
    await tester.pumpAndSettle();

    expect(find.text('Backup driver: Asha'), findsOneWidget);
  });

  testWidgets('accepted circle members can open and send secure messages', (
    tester,
  ) async {
    await _pumpApp(tester, _state(selectedTab: 2));

    await tester.tap(
      find
          .ancestor(
            of: find.text('Solihull Early Shift Circle'),
            matching: find.byType(InkWell),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Open secure messages'), 220);
    await tester.tap(find.text('Open secure messages'));
    await tester.pumpAndSettle();

    expect(find.text('Secure messages'), findsOneWidget);
    await tester.enterText(
      find.byType(TextField),
      'Can we meet by the station entrance?',
    );
    await tester.tap(find.byTooltip('Send message'));
    await tester.pumpAndSettle();

    expect(find.text('Can we meet by the station entrance?'), findsOneWidget);
  });
}

Future<void> _pumpApp(WidgetTester tester, AppState state) async {
  tester.view.physicalSize = const Size(1000, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
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
}

AppState _state({int selectedTab = 0}) {
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
  return AppState(
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
    commuteRequests: MockData.commuteRequests(),
    circles: MockData.commuteCircles(),
    journeys: MockData.journeys(),
    reliabilityProfiles: [MockData.reliabilityFor('local-user')],
    activeCircleId: 'circle-solihull-early',
    selectedTab: selectedTab,
  );
}
