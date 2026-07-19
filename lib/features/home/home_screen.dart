import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/compatibility_indicator.dart';
import '../../core/widgets/profile_avatar.dart';
import '../../data/mock/mock_data.dart';
import '../../data/models/commute_circle.dart';
import '../../data/models/commute_request.dart';
import '../../data/models/journey.dart';
import '../../data/models/ride_request.dart';
import '../state/providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final profile = state.profile!;
    final commute = state.commute!;
    final worksite = MockData.worksite(commute.worksiteId);
    final matches = ref.watch(matchesProvider);
    final activeCircle = state.circles
        .where((circle) => circle.id == state.activeCircleId)
        .firstOrNull;
    final nextJourney = activeCircle == null
        ? null
        : state.journeys
              .where((journey) => journey.circleId == activeCircle.id)
              .firstOrNull;
    final reliability = state.reliabilityProfiles.firstOrNull;
    final accepted = state.requests
        .where((item) => item.status == RequestStatus.accepted)
        .length;
    final pendingIncoming = state.requests
        .where(
          (item) =>
              item.direction == RequestDirection.incoming &&
              item.status == RequestStatus.pending,
        )
        .length;
    final circleJoinRequests = state.commuteRequests
        .where(
          (request) =>
              request.type == CommuteRequestType.joinCircle &&
              request.status == CommuteRequestStatus.pending &&
              request.isActive,
        )
        .length;
    final unreadNotifications = state.notifications
        .where((notification) => !notification.read)
        .length;
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppConstants.appName,
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            Text(
              AppConstants.tagline,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => context.push('/notifications'),
            icon: Badge.count(
              count: unreadNotifications,
              isLabelVisible: unreadNotifications > 0,
              child: const Icon(Icons.notifications_outlined),
            ),
            tooltip: 'Notifications',
          ),
          IconButton(
            onPressed: () => context.push('/safety'),
            icon: const Icon(Icons.shield_outlined),
            tooltip: 'Safety information',
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppConstants.maxContentWidth,
          ),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Text(
                'Hello, ${profile.firstName}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              const Text('Your private workplace commute network.'),
              const SizedBox(height: 20),
              _NextJourneyCard(
                circle: activeCircle,
                journey: nextJourney,
                worksiteName: worksite.name,
                fallback:
                    '${profile.homeArea} to ${worksite.name} · ${formatDays(commute.days)}',
              ),
              const SizedBox(height: 16),
              _ActionCentre(
                pendingIncoming: pendingIncoming,
                circleJoinRequests: circleJoinRequests,
                journey: nextJourney,
              ),
              const SizedBox(height: 16),
              if (activeCircle != null)
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: const CircleAvatar(
                      child: Icon(Icons.groups_2_outlined),
                    ),
                    title: Text(activeCircle.name),
                    subtitle: Text(
                      '${formatDays(activeCircle.days)} · ${activeCircle.availableSeats} seat remaining',
                    ),
                    trailing: const Icon(Icons.arrow_forward_rounded),
                    onTap: () => context.push('/circles/${activeCircle.id}'),
                  ),
                )
              else
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: const CircleAvatar(
                      child: Icon(Icons.groups_2_outlined),
                    ),
                    title: const Text('No active Commute Circle yet'),
                    subtitle: const Text(
                      'Start with one of your strongest colleague matches.',
                    ),
                    trailing: const Icon(Icons.arrow_forward_rounded),
                    onTap: () => context.go('/circles'),
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.auto_awesome_rounded,
                      value: '${matches.length}',
                      label: 'compatible colleagues',
                      onTap: () => context.go('/matches'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.mark_email_unread_outlined,
                      value: '${pendingIncoming + circleJoinRequests}',
                      label: 'requests to review',
                      onTap: () => context.go('/requests'),
                    ),
                  ),
                ],
              ),
              if (accepted > 0) ...[
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: const CircleAvatar(
                      child: Icon(Icons.handshake_rounded),
                    ),
                    title: Text(
                      '$accepted accepted recurring ${accepted == 1 ? 'commute' : 'commutes'}',
                    ),
                    subtitle: const Text(
                      'View agreed days and public meeting-point guidance',
                    ),
                    trailing: const Icon(Icons.arrow_forward_rounded),
                    onTap: () => context.push('/accepted'),
                  ),
                ),
              ],
              const SizedBox(height: 26),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Top matches',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/matches'),
                    child: const Text('See all'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              for (final match in matches.take(3))
                Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(14),
                    leading: ProfileAvatar(initials: match.profile.initials),
                    title: Text(
                      match.profile.firstName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '${match.profile.homeArea} · ${match.reasons.take(2).join(' · ')}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: CompatibilityIndicator(
                      score: match.score,
                      size: 52,
                    ),
                    onTap: () => context.push('/matches/${match.profile.id}'),
                  ),
                ),
              const SizedBox(height: 16),
              if (reliability != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your reliability summary',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 10),
                        for (final signal in reliability.positives.take(3))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                const Icon(Icons.check_rounded, size: 18),
                                const SizedBox(width: 8),
                                Expanded(child: Text(signal.label)),
                              ],
                            ),
                          ),
                        const SizedBox(height: 6),
                        const Text(
                          'Workplace verification does not confirm driving ability, insurance, criminal history or personal character.',
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NextJourneyCard extends StatelessWidget {
  const _NextJourneyCard({
    required this.circle,
    required this.journey,
    required this.worksiteName,
    required this.fallback,
  });

  final CommuteCircle? circle;
  final JourneyOccurrence? journey;
  final String worksiteName;
  final String fallback;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event_available_outlined),
              const SizedBox(width: 8),
              Text(
                'Next journey',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            circle?.name ?? fallback,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            journey == null
                ? worksiteName
                : '${formatMinutes(journey!.departureWindowStartMinutes)} to ${formatMinutes(journey!.departureWindowEndMinutes)} · $worksiteName',
          ),
          if (journey != null) ...[
            const SizedBox(height: 8),
            Text(
              '${journey!.confirmedCount} of ${journey!.memberIds.length} members confirmed for tomorrow',
            ),
          ],
        ],
      ),
    ),
  );
}

class _ActionCentre extends ConsumerWidget {
  const _ActionCentre({
    required this.pendingIncoming,
    required this.circleJoinRequests,
    required this.journey,
  });

  final int pendingIncoming;
  final int circleJoinRequests;
  final JourneyOccurrence? journey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final needsConfirmation =
        journey?.attendance.any(
          (item) =>
              item.profileId == ref.watch(appControllerProvider).profile?.id &&
              item.status == JourneyAttendanceStatus.confirmed,
        ) ==
        false;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Action centre',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            if (journey != null && needsConfirmation)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.fact_check_outlined),
                title: const Text('Confirm tomorrow’s journey'),
                trailing: FilledButton(
                  onPressed: () => ref
                      .read(appControllerProvider.notifier)
                      .setJourneyAttendance(
                        journey!.id,
                        JourneyAttendanceStatus.confirmed,
                      ),
                  child: const Text('Confirm'),
                ),
              ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.inbox_outlined),
              title: Text(
                pendingIncoming + circleJoinRequests == 0
                    ? 'No requests waiting'
                    : 'Respond to ${pendingIncoming + circleJoinRequests} requests',
              ),
              onTap: () => context.go('/requests'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.edit_calendar_outlined),
              title: const Text('Keep your Friday schedule up to date'),
              onTap: () => context.push('/commute/edit'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String value;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 18),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(label, maxLines: 2),
          ],
        ),
      ),
    ),
  );
}
