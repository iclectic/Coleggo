import 'package:coleggo/data/mock/mock_data.dart';
import 'package:coleggo/data/models/message_thread.dart';
import 'package:coleggo/data/repositories/local_repositories.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('creates circle thread only for active members', () async {
    final repository = MockMessagingRepository();
    final circle = MockData.commuteCircles().first;

    final allowed = await repository.getOrCreateCircleThread(
      threads: const [],
      circle: circle,
      requesterProfileId: 'local-user',
    );
    final blocked = await repository.getOrCreateCircleThread(
      threads: const [],
      circle: circle,
      requesterProfileId: 'p18',
    );

    expect(allowed.value?.type, MessageThreadType.commuteCircle);
    expect(allowed.value?.canAccess('local-user'), isTrue);
    expect(blocked.hasError, isTrue);
  });

  test('stores messages and flags risky sharing language', () async {
    final repository = MockMessagingRepository();
    final thread = (await repository.getOrCreateCircleThread(
      threads: const [],
      circle: MockData.commuteCircles().first,
      requesterProfileId: 'local-user',
    )).value!;

    final sent = await repository.sendMessage(
      thread: thread,
      senderProfileId: 'local-user',
      body: 'Can we use the station entrance?',
    );
    final flagged = await repository.sendMessage(
      thread: sent.value!,
      senderProfileId: 'local-user',
      body: 'Here is my home address',
    );

    expect(sent.value?.messages.last.body, 'Can we use the station entrance?');
    expect(
      flagged.value?.messages.last.deliveryState,
      MessageDeliveryState.flagged,
    );
  });

  test('submits moderation reports for accessible messages', () async {
    final repository = MockMessagingRepository();
    final thread = (await repository.getOrCreateCircleThread(
      threads: const [],
      circle: MockData.commuteCircles().first,
      requesterProfileId: 'local-user',
    )).value!;

    final report = await repository.reportMessage(
      thread: thread,
      message: thread.messages.first,
      reporterProfileId: 'local-user',
      reason: 'Review wording',
    );

    expect(report.value?.status, ModerationReportStatus.submitted);
    expect(report.value?.reason, 'Review wording');
  });
}
