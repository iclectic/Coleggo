import 'package:coleggo/data/models/notification_record.dart';
import 'package:coleggo/data/repositories/local_repositories.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('creates and marks in-app notifications read', () async {
    final repository = MockNotificationRepository();

    final created = await repository.create(
      type: CommuteNotificationType.cancellation,
      title: 'Journey cancelled',
      body: 'Two members are affected.',
      priority: CommuteNotificationPriority.urgent,
      contextRoute: '/circles/circle-solihull-early',
    );
    final notification = created.value!;
    final read = await repository.markRead(
      notifications: [notification],
      notificationId: notification.id,
    );
    final allRead = await repository.markAllRead(
      notifications: [notification, notification.copyWith(read: false)],
    );

    expect(notification.read, isFalse);
    expect(read.value!.single.read, isTrue);
    expect(allRead.value!.every((item) => item.read), isTrue);
  });
}
