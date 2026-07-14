import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/profile_avatar.dart';
import '../../core/widgets/status_chip.dart';
import '../../data/models/ride_request.dart';
import '../state/providers.dart';

class RequestsScreen extends ConsumerWidget {
  const RequestsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(appControllerProvider).requests;
    final incoming = requests
        .where(
          (item) =>
              item.direction == RequestDirection.incoming &&
              item.status == RequestStatus.pending,
        )
        .toList();
    final outgoing = requests
        .where(
          (item) =>
              item.direction == RequestDirection.outgoing &&
              item.status == RequestStatus.pending,
        )
        .toList();
    final history = requests
        .where((item) => item.status != RequestStatus.pending)
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Requests')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppConstants.maxContentWidth,
          ),
          child: requests.isEmpty
              ? const EmptyState(
                  icon: Icons.inbox_outlined,
                  title: 'No requests yet',
                  message:
                      'When you request a seat or offer a lift, it will appear here.',
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                  children: [
                    if (incoming.isNotEmpty) ...[
                      _Heading('Incoming', '${incoming.length} waiting'),
                      for (final request in incoming)
                        _RequestCard(request: request),
                    ],
                    if (outgoing.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      _Heading('Outgoing', '${outgoing.length} pending'),
                      for (final request in outgoing)
                        _RequestCard(request: request),
                    ],
                    if (history.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      _Heading('History', '${history.length} requests'),
                      for (final request in history)
                        _RequestCard(request: request),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.title, this.trailing);
  final String title;
  final String trailing;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 10, 2, 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        Text(trailing, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
}

class _RequestCard extends ConsumerWidget {
  const _RequestCard({required this.request});
  final RideRequest request;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(commuterProvider(request.profileId));
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Row(
              children: [
                ProfileAvatar(initials: profile.initials),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.firstName,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '${request.kind == RequestKind.seat ? 'Seat request' : 'Lift offer'} · ${formatDays(request.recurringDays)}',
                      ),
                    ],
                  ),
                ),
                StatusChip(request.status),
              ],
            ),
            if (request.direction == RequestDirection.incoming &&
                request.status == RequestStatus.pending) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => ref
                          .read(appControllerProvider.notifier)
                          .updateRequest(request.id, RequestStatus.declined),
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        await ref
                            .read(appControllerProvider.notifier)
                            .updateRequest(request.id, RequestStatus.accepted);
                        if (context.mounted) {
                          context.push('/accepted', extra: request.id);
                        }
                      },
                      child: const Text('Accept'),
                    ),
                  ),
                ],
              ),
            ],
            if (request.direction == RequestDirection.outgoing &&
                request.status == RequestStatus.pending) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => ref
                      .read(appControllerProvider.notifier)
                      .updateRequest(request.id, RequestStatus.cancelled),
                  child: const Text('Cancel request'),
                ),
              ),
            ],
            if (request.status == RequestStatus.accepted) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => context.push('/accepted', extra: request.id),
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('View commute'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
