import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/profile_avatar.dart';
import '../../data/mock/mock_data.dart';
import '../../data/models/commute_circle.dart';
import '../../data/models/commute_request.dart';
import '../../data/models/journey.dart';
import '../state/providers.dart';

class CircleDetailsScreen extends ConsumerWidget {
  const CircleDetailsScreen({required this.circleId, super.key});
  final String circleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final circle = state.circles
        .where((item) => item.id == circleId)
        .firstOrNull;
    if (circle == null) {
      return const Scaffold(body: Center(child: Text('Circle not found.')));
    }
    final profileId = state.profile?.id;
    final membership = circle.members
        .where((member) => member.profileId == profileId)
        .firstOrNull;
    final isMember = membership != null;
    final pendingJoin = state.commuteRequests.any(
      (request) =>
          request.circleId == circle.id &&
          request.requesterProfileId == profileId &&
          request.type == CommuteRequestType.joinCircle &&
          request.isActive,
    );
    final journey = state.journeys
        .where((item) => item.circleId == circle.id)
        .firstOrNull;
    final worksite = MockData.worksite(circle.worksiteId);
    return Scaffold(
      appBar: AppBar(title: const Text('Commute Circle')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppConstants.maxContentWidth,
          ),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Text(
                circle.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text('${worksite.name} · ${circle.meetingPointArea}'),
              const SizedBox(height: 16),
              _SummaryPanel(circle: circle),
              const SizedBox(height: 16),
              if (journey != null) _JourneyConfirmation(journey: journey),
              if (journey != null) const SizedBox(height: 16),
              if (journey != null) _BackupPlan(journey: journey),
              if (journey != null) const SizedBox(height: 16),
              _Section(
                title: 'Members',
                child: Column(
                  children: [
                    for (final member in circle.members)
                      _MemberRow(member: member, currentProfileId: profileId),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _Section(
                title: 'Circle rules',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final rule in circle.rules)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_rounded, size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text(rule)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _Section(
                title: 'Messaging',
                child: const Text(
                  'Circle messaging will be introduced later. For this prototype, Coleggo shows the agreed schedule, confirmations and activity without pretending that live chat is available.',
                ),
              ),
              const SizedBox(height: 16),
              _Section(
                title: 'Recent activity',
                child: Column(
                  children: [
                    for (final activity in circle.activity)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.history_rounded),
                        title: Text(activity.label),
                        subtitle: Text(
                          '${activity.createdAt.day}/${activity.createdAt.month}/${activity.createdAt.year}',
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (!isMember)
                FilledButton.icon(
                  onPressed: pendingJoin
                      ? null
                      : () => ref
                            .read(appControllerProvider.notifier)
                            .requestToJoinCircle(circle.id),
                  icon: const Icon(Icons.group_add_outlined),
                  label: Text(
                    pendingJoin ? 'Join request sent' : 'Request to join',
                  ),
                )
              else ...[
                FilledButton.tonalIcon(
                  onPressed: () => ref
                      .read(appControllerProvider.notifier)
                      .pauseCircleParticipation(
                        circle.id,
                        membership.status == CircleParticipationStatus.active,
                      ),
                  icon: Icon(
                    membership.status == CircleParticipationStatus.active
                        ? Icons.pause_circle_outline_rounded
                        : Icons.play_circle_outline_rounded,
                  ),
                  label: Text(
                    membership.status == CircleParticipationStatus.active
                        ? 'Pause participation'
                        : 'Resume participation',
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => ref
                      .read(appControllerProvider.notifier)
                      .leaveCircle(circle.id),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Leave circle'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({required this.circle});
  final CommuteCircle circle;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _DetailChip(
            icon: Icons.calendar_month_outlined,
            label: formatDays(circle.days),
          ),
          _DetailChip(
            icon: Icons.schedule_rounded,
            label:
                '${formatMinutes(circle.departureWindowStartMinutes)} to ${formatMinutes(circle.departureWindowEndMinutes)}',
          ),
          _DetailChip(
            icon: Icons.flag_outlined,
            label: 'Arrive by ${formatMinutes(circle.arrivalTargetMinutes)}',
          ),
          _DetailChip(
            icon: Icons.event_seat_outlined,
            label: '${circle.availableSeats} seat remaining',
          ),
          _DetailChip(
            icon: Icons.work_outline_rounded,
            label: circle.state.name,
          ),
        ],
      ),
    ),
  );
}

class _JourneyConfirmation extends ConsumerWidget {
  const _JourneyConfirmation({required this.journey});
  final JourneyOccurrence journey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final profileId = state.profile?.id;
    final attendance = journey.attendance
        .where((item) => item.profileId == profileId)
        .firstOrNull;
    final summary =
        '${journey.confirmedCount} of ${journey.memberIds.length} members confirmed for tomorrow.';
    return _Section(
      title: 'Next journey',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(summary, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            '${formatMinutes(journey.departureWindowStartMinutes)} to ${formatMinutes(journey.departureWindowEndMinutes)} · ${journey.status.label}',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('I am travelling'),
                selected:
                    attendance?.status == JourneyAttendanceStatus.confirmed,
                onSelected: (_) => ref
                    .read(appControllerProvider.notifier)
                    .setJourneyAttendance(
                      journey.id,
                      JourneyAttendanceStatus.confirmed,
                    ),
              ),
              ChoiceChip(
                label: const Text('Not travelling'),
                selected:
                    attendance?.status == JourneyAttendanceStatus.notTravelling,
                onSelected: (_) => ref
                    .read(appControllerProvider.notifier)
                    .setJourneyAttendance(
                      journey.id,
                      JourneyAttendanceStatus.notTravelling,
                    ),
              ),
              ChoiceChip(
                label: const Text('Unsure'),
                selected:
                    attendance?.status == JourneyAttendanceStatus.undecided,
                onSelected: (_) => ref
                    .read(appControllerProvider.notifier)
                    .setJourneyAttendance(
                      journey.id,
                      JourneyAttendanceStatus.undecided,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BackupPlan extends ConsumerWidget {
  const _BackupPlan({required this.journey});
  final JourneyOccurrence journey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primary = MockData.commuter(journey.backupPlan.primaryDriverId);
    final backupId = journey.backupPlan.backupDriverId;
    final backup = backupId == null ? null : MockData.commuter(backupId);
    final cancelled = journey.status == JourneyStatus.cancelled;
    return _Section(
      title: 'Backup plan',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DriverLine(label: 'Primary driver', name: primary.firstName),
          _DriverLine(
            label: 'Backup driver',
            name: backup?.firstName ?? 'Not chosen yet',
          ),
          if (journey.backupPlan.cancellationDeadline case final deadline?) ...[
            const SizedBox(height: 8),
            Text(
              'Cancellation deadline: ${formatMinutes(deadline.hour * 60 + deadline.minute)}',
            ),
          ],
          const SizedBox(height: 10),
          Text(
            journey.backupPlan.publicTransportNote ??
                'Public transport alternatives will be added later.',
          ),
          if (!cancelled) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () => ref
                  .read(appControllerProvider.notifier)
                  .cancelJourney(journey.id),
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Emergency cancellation'),
            ),
          ] else ...[
            const SizedBox(height: 14),
            Text(
              'Cancelled. ${journey.cancellation?.affectedProfileIds.length ?? 0} passengers affected.',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              'Suggested compatible backup drivers',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            for (final candidateId in journey.backupPlan.alternativeMatchIds)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: ProfileAvatar(
                  initials: MockData.commuter(candidateId).initials,
                ),
                title: Text(MockData.commuter(candidateId).firstName),
                trailing: FilledButton(
                  onPressed: () => ref
                      .read(appControllerProvider.notifier)
                      .selectBackupDriver(journey.id, candidateId),
                  child: const Text('Choose'),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _DriverLine extends StatelessWidget {
  const _DriverLine({required this.label, required this.name});
  final String label;
  final String name;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        const Icon(Icons.person_pin_circle_outlined, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label: $name',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member, required this.currentProfileId});
  final CircleMember member;
  final String? currentProfileId;

  @override
  Widget build(BuildContext context) {
    final isCurrentUser = member.profileId == currentProfileId;
    final profile = isCurrentUser ? null : MockData.commuter(member.profileId);
    final name = isCurrentUser ? 'You' : profile!.firstName;
    final initials = isCurrentUser ? 'YO' : profile!.initials;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: ProfileAvatar(initials: initials),
      title: Text(name),
      subtitle: Text('${member.role.label} · ${member.status.label}'),
      trailing: member.role == CircleMemberRole.backupDriver
          ? const Tooltip(
              message: 'Backup driver for disruption',
              child: Icon(Icons.alt_route_rounded),
            )
          : null,
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Chip(
    avatar: Icon(icon, size: 18),
    label: Text(label),
    visualDensity: VisualDensity.compact,
  );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    ),
  );
}

extension on JourneyStatus {
  String get label => switch (this) {
    JourneyStatus.scheduled => 'Scheduled',
    JourneyStatus.awaitingConfirmation => 'Awaiting confirmation',
    JourneyStatus.confirmed => 'Confirmed',
    JourneyStatus.completed => 'Completed',
    JourneyStatus.cancelled => 'Cancelled',
    JourneyStatus.missed => 'Missed',
    JourneyStatus.archived => 'Archived',
  };
}

extension on CircleMemberRole {
  String get label => switch (this) {
    CircleMemberRole.primaryDriver => 'Primary driver',
    CircleMemberRole.backupDriver => 'Backup driver',
    CircleMemberRole.passenger => 'Passenger',
  };
}

extension on CircleParticipationStatus {
  String get label => switch (this) {
    CircleParticipationStatus.active => 'Active',
    CircleParticipationStatus.paused => 'Paused',
  };
}
