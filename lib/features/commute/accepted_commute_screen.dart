import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/profile_avatar.dart';
import '../../core/widgets/workplace_badge.dart';
import '../../data/models/ride_request.dart';
import '../state/providers.dart';

class AcceptedCommuteScreen extends ConsumerWidget {
  const AcceptedCommuteScreen({this.requestId, super.key});
  final String? requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(appControllerProvider).requests;
    final accepted = requestId == null
        ? requests
              .where((item) => item.status == RequestStatus.accepted)
              .firstOrNull
        : requests
              .where(
                (item) =>
                    item.id == requestId &&
                    item.status == RequestStatus.accepted,
              )
              .firstOrNull;
    if (accepted == null) {
      return const Scaffold(
        body: Center(child: Text('No accepted recurring commute found.')),
      );
    }
    final profile = ref.watch(commuterProvider(accepted.profileId));
    return Scaffold(
      appBar: AppBar(title: const Text('Recurring commute')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.tertiary,
                ],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.handshake_rounded,
                  color: Colors.white,
                  size: 40,
                ),
                const SizedBox(height: 12),
                Text(
                  'You’re travelling together',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  formatDays(accepted.recurringDays),
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    children: [
                      ProfileAvatar(initials: profile.initials, radius: 30),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.firstName,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 5),
                            const WorkplaceBadge(compact: true),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  _Row(
                    Icons.alt_route_rounded,
                    'Broad corridor',
                    profile.corridor,
                  ),
                  _Row(
                    Icons.schedule_rounded,
                    'Departure window',
                    'Around ${formatMinutes(profile.departureMinutes)}',
                  ),
                  _Row(
                    Icons.pin_drop_outlined,
                    'Suggested meeting point',
                    '${profile.homeArea} public transport stop',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Before you travel',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('• Agree a well-lit public pickup point.'),
                  const SizedBox(height: 8),
                  const Text(
                    '• Confirm arrangements directly before each journey.',
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Drivers remain responsible for their vehicle, licence and insurance.',
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Coleggo does not verify driving ability or criminal history in this prototype.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.icon, this.label, this.value);
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: Row(
      children: [
        Icon(icon),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelMedium),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    ),
  );
}
