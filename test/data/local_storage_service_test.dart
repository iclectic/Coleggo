import 'package:coleggo/data/mock/mock_data.dart';
import 'package:coleggo/data/models/cancellation_record.dart';
import 'package:coleggo/data/models/app_state.dart';
import 'package:coleggo/data/models/journey.dart';
import 'package:coleggo/data/models/message_thread.dart';
import 'package:coleggo/data/services/local_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('returns fresh state when no local snapshot exists', () async {
    SharedPreferences.setMockInitialValues({});
    final service = LocalStorageService(await SharedPreferences.getInstance());

    final state = await service.load();

    expect(state.onboardingComplete, isFalse);
    expect(state.setupComplete, isFalse);
  });

  test('round-trips important prototype progress', () async {
    SharedPreferences.setMockInitialValues({});
    final service = LocalStorageService(await SharedPreferences.getInstance());
    const original = AppState(
      onboardingComplete: true,
      selectedWorkplaceId: 'northstar',
      selectedWorksiteId: 'central_exchange',
      workEmail: 'test@example.invalid',
      workplaceVerified: true,
      themePreference: AppThemePreference.dark,
      selectedTab: 2,
    );

    await service.save(original);
    final restored = await service.load();

    expect(restored.onboardingComplete, isTrue);
    expect(restored.selectedWorkplaceId, 'northstar');
    expect(restored.workplaceVerified, isTrue);
    expect(restored.themePreference, AppThemePreference.dark);
    expect(restored.selectedTab, 2);
  });

  test('malformed local state falls back safely', () async {
    SharedPreferences.setMockInitialValues({
      LocalStorageService.stateKey: '{not valid json',
    });
    final service = LocalStorageService(await SharedPreferences.getInstance());

    final state = await service.load();

    expect(state, isA<AppState>());
    expect(state.onboardingComplete, isFalse);
  });

  test('restores circles, attendance and cancellation history', () async {
    SharedPreferences.setMockInitialValues({});
    final service = LocalStorageService(await SharedPreferences.getInstance());
    final cancellation = CancellationRecord(
      id: 'cancel-test',
      journeyId: 'journey-solihull-2026-07-17',
      cancelledByProfileId: 'p09',
      actor: CancellationActor.driver,
      cancelledAt: DateTime(2026, 7, 16, 19),
      affectedProfileIds: const ['local-user'],
      reason: 'Test cancellation',
    );
    final journey = MockData.journeys().first.copyWith(
      status: JourneyStatus.cancelled,
      cancellation: cancellation,
    );
    final original = AppState(
      circles: MockData.commuteCircles(),
      journeys: [journey],
      commuteRequests: MockData.commuteRequests(),
      reliabilityProfiles: [MockData.reliabilityFor('local-user')],
      cancellationHistory: [cancellation],
      activeCircleId: 'circle-solihull-early',
    );

    await service.save(original);
    final restored = await service.load();

    expect(restored.circles.first.name, 'Solihull Early Shift Circle');
    expect(restored.journeys.single.status, JourneyStatus.cancelled);
    expect(restored.journeys.single.cancellation?.reason, 'Test cancellation');
    expect(restored.commuteRequests.length, 2);
    expect(restored.cancellationHistory.single.id, 'cancel-test');
    expect(restored.activeCircleId, 'circle-solihull-early');
  });

  test('restores secure message threads and moderation reports', () async {
    SharedPreferences.setMockInitialValues({});
    final service = LocalStorageService(await SharedPreferences.getInstance());
    final thread = MessageThread(
      id: 'thread-circle-solihull-early',
      type: MessageThreadType.commuteCircle,
      contextId: 'circle-solihull-early',
      participantProfileIds: const ['local-user', 'p09'],
      messages: [
        CommuteMessage(
          id: 'message-1',
          threadId: 'thread-circle-solihull-early',
          senderProfileId: 'local-user',
          body: 'Meet at the station entrance.',
          sentAt: DateTime(2026, 7, 16, 19),
        ),
      ],
      createdAt: DateTime(2026, 7, 16, 18),
    );
    final report = MessageModerationReport(
      id: 'report-1',
      threadId: thread.id,
      messageId: 'message-1',
      reporterProfileId: 'p09',
      reason: 'Review meeting point wording',
      createdAt: DateTime(2026, 7, 16, 20),
    );

    await service.save(
      AppState(messageThreads: [thread], messageReports: [report]),
    );
    final restored = await service.load();

    expect(
      restored.messageThreads.single.messages.single.body,
      contains('station'),
    );
    expect(
      restored.messageReports.single.status,
      ModerationReportStatus.submitted,
    );
  });
}
