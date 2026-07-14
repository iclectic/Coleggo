import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/profile_avatar.dart';
import '../../core/widgets/workplace_badge.dart';
import '../../data/mock/mock_data.dart';
import '../state/providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final profile = state.profile!;
    final workplace = MockData.workplace(profile.workplaceId);
    final worksite = MockData.worksite(profile.worksiteId);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppConstants.maxFormWidth,
          ),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Center(
                child: Column(
                  children: [
                    ProfileAvatar(initials: profile.initials, radius: 45),
                    const SizedBox(height: 14),
                    Text(
                      profile.firstName,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    const WorkplaceBadge(),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      _Item(
                        Icons.apartment_rounded,
                        'Workplace',
                        '${workplace.name} · ${worksite.name}',
                      ),
                      _Item(
                        Icons.near_me_outlined,
                        'Approximate area',
                        profile.homeArea,
                      ),
                      _Item(
                        Icons.swap_horiz_rounded,
                        'Commute role',
                        profile.role.label,
                      ),
                      _Item(
                        Icons.calendar_month_outlined,
                        'Commuting days',
                        formatDays(profile.days),
                      ),
                      _Item(
                        Icons.schedule_rounded,
                        'Preferred times',
                        '${formatMinutes(profile.arrivalMinutes)} arrival · ${formatMinutes(profile.departureMinutes)} departure',
                      ),
                      if (profile.vehicleSummary != null)
                        _Item(
                          Icons.directions_car_outlined,
                          'Vehicle summary',
                          profile.vehicleSummary!,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: () => context.push('/setup'),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit profile and commute'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => context.push('/safety'),
                icon: const Icon(Icons.health_and_safety_outlined),
                label: const Text('Safety and privacy information'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item(this.icon, this.label, this.value);
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
