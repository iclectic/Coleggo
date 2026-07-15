import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/compatibility_indicator.dart';
import '../../core/widgets/privacy_notice.dart';
import '../../core/widgets/profile_avatar.dart';
import '../../core/widgets/workplace_badge.dart';
import '../../data/mock/mock_data.dart';
import '../../data/models/ride_request.dart';
import '../state/providers.dart';

class MatchDetailsScreen extends ConsumerWidget {
  const MatchDetailsScreen({required this.profileId, super.key});
  final String profileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appControllerProvider).profile!;
    final match = ref.watch(matchRepositoryProvider).getMatch(user, profileId);
    final profile = match.profile;
    final requestKind = user.role.canRide && profile.role.canDrive
        ? RequestKind.seat
        : RequestKind.lift;
    final worksite = MockData.worksite(profile.worksiteId);
    return Scaffold(
      appBar: AppBar(title: const Text('Match profile')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: () =>
                context.push('/matches/$profileId/confirm', extra: requestKind),
            icon: Icon(
              requestKind == RequestKind.seat
                  ? Icons.event_seat_rounded
                  : Icons.directions_car_rounded,
            ),
            label: Text(requestKind.actionLabel),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Row(
            children: [
              ProfileAvatar(initials: profile.initials, radius: 38),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.firstName,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    const WorkplaceBadge(),
                  ],
                ),
              ),
              CompatibilityIndicator(score: match.score, size: 70),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Why this is a ${match.level.label.toLowerCase()}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${match.score}% estimated compatibility. Broad areas and route corridors are approximate.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  for (final reason in match.positiveReasons)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(reason.message)),
                        ],
                      ),
                    ),
                  if (match.limitations.isNotEmpty) ...[
                    const Divider(height: 26),
                    Text(
                      'Things to consider',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final limitation in match.limitations)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, size: 20),
                            const SizedBox(width: 10),
                            Expanded(child: Text(limitation.message)),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Commute overview',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _Detail(
                    icon: Icons.near_me_outlined,
                    label: 'Approximate starting area',
                    value: profile.homeArea,
                  ),
                  _Detail(
                    icon: Icons.alt_route_rounded,
                    label: 'Broad corridor',
                    value: profile.corridor,
                  ),
                  _Detail(
                    icon: Icons.apartment_rounded,
                    label: 'Worksite',
                    value: worksite.name,
                  ),
                  _Detail(
                    icon: Icons.calendar_month_outlined,
                    label: 'Commuting days',
                    value: formatDays(profile.days),
                  ),
                  _Detail(
                    icon: Icons.schedule_rounded,
                    label: 'Departure window',
                    value: 'Around ${formatMinutes(profile.departureMinutes)}',
                  ),
                  if (profile.vehicleSummary != null)
                    _Detail(
                      icon: Icons.directions_car_outlined,
                      label: 'Vehicle',
                      value: profile.vehicleSummary!,
                    ),
                  if (profile.role.canDrive)
                    _Detail(
                      icon: Icons.event_seat_outlined,
                      label: 'Available seats',
                      value: '${profile.availableSeats}',
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const PrivacyNotice(),
        ],
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      children: [
        Icon(icon, size: 21),
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
