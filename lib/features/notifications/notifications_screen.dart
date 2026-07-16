import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../data/models/notification_record.dart';
import '../state/providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(appControllerProvider).notifications;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: notifications.isEmpty
                ? null
                : () => ref
                      .read(appControllerProvider.notifier)
                      .markAllNotificationsRead(),
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppConstants.maxContentWidth,
          ),
          child: notifications.isEmpty
              ? const _EmptyNotifications()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(14),
                        leading: Icon(notification.type.icon),
                        title: Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight: notification.read
                                ? FontWeight.w600
                                : FontWeight.w800,
                          ),
                        ),
                        subtitle: Text(notification.body),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (!notification.read)
                              const Icon(Icons.circle, size: 10),
                            const SizedBox(height: 6),
                            Text(notification.priority.label),
                          ],
                        ),
                        onTap: () async {
                          await ref
                              .read(appControllerProvider.notifier)
                              .markNotificationRead(notification.id);
                          if (context.mounted &&
                              notification.contextRoute != null) {
                            context.push(notification.contextRoute!);
                          }
                        },
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(24),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.notifications_none_rounded, size: 44),
        SizedBox(height: 12),
        Text(
          'In-app notifications for confirmations, requests, cancellations and messages will appear here.',
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

extension on CommuteNotificationType {
  IconData get icon => switch (this) {
    CommuteNotificationType.journeyConfirmation => Icons.fact_check_outlined,
    CommuteNotificationType.joinRequest => Icons.group_add_outlined,
    CommuteNotificationType.cancellation => Icons.cancel_outlined,
    CommuteNotificationType.backupDriver => Icons.alt_route_rounded,
    CommuteNotificationType.message => Icons.lock_outline_rounded,
  };
}

extension on CommuteNotificationPriority {
  String get label => switch (this) {
    CommuteNotificationPriority.normal => 'Info',
    CommuteNotificationPriority.actionRequired => 'Action',
    CommuteNotificationPriority.urgent => 'Urgent',
  };
}
