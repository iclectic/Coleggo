import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../data/mock/mock_data.dart';
import '../../data/models/commute_circle.dart';
import '../state/providers.dart';

class CirclesScreen extends ConsumerWidget {
  const CirclesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final circles = state.circles;
    return Scaffold(
      appBar: AppBar(title: const Text('Commute Circles')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppConstants.maxContentWidth,
          ),
          child: circles.isEmpty
              ? const _EmptyCircles()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [
                    const Text(
                      'Private workplace groups for recurring journeys with verified colleagues.',
                    ),
                    const SizedBox(height: 16),
                    for (final circle in circles)
                      _CircleCard(
                        circle: circle,
                        currentProfileId: state.profile?.id,
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _CircleCard extends StatelessWidget {
  const _CircleCard({required this.circle, required this.currentProfileId});

  final CommuteCircle circle;
  final String? currentProfileId;

  @override
  Widget build(BuildContext context) {
    final worksite = MockData.worksite(circle.worksiteId);
    final isMember = circle.members.any(
      (member) => member.profileId == currentProfileId,
    );
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push('/circles/${circle.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      circle.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _CircleStateChip(state: circle.state),
                ],
              ),
              const SizedBox(height: 8),
              Text(worksite.name),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(
                    icon: Icons.calendar_month_outlined,
                    label: formatDays(circle.days),
                  ),
                  _InfoChip(
                    icon: Icons.schedule_rounded,
                    label:
                        '${formatMinutes(circle.departureWindowStartMinutes)} to ${formatMinutes(circle.departureWindowEndMinutes)}',
                  ),
                  _InfoChip(
                    icon: Icons.event_seat_outlined,
                    label: '${circle.availableSeats} seats',
                  ),
                  if (circle.hasBackupDriver)
                    const _InfoChip(
                      icon: Icons.alt_route_rounded,
                      label: 'Backup driver',
                    ),
                  if (isMember)
                    const _InfoChip(
                      icon: Icons.check_circle_outline_rounded,
                      label: 'Your circle',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleStateChip extends StatelessWidget {
  const _CircleStateChip({required this.state});
  final CommuteCircleState state;

  @override
  Widget build(BuildContext context) => Chip(
    visualDensity: VisualDensity.compact,
    label: Text(switch (state) {
      CommuteCircleState.forming => 'Forming',
      CommuteCircleState.active => 'Active',
      CommuteCircleState.full => 'Full',
      CommuteCircleState.paused => 'Paused',
      CommuteCircleState.archived => 'Archived',
    }),
  );
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Chip(
    avatar: Icon(icon, size: 18),
    label: Text(label),
    visualDensity: VisualDensity.compact,
  );
}

class _EmptyCircles extends StatelessWidget {
  const _EmptyCircles();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(24),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.groups_2_outlined, size: 44),
        SizedBox(height: 12),
        Text(
          'You are not part of a Commute Circle yet. Start with one of your strongest colleague matches.',
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}
