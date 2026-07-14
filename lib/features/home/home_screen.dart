import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/compatibility_indicator.dart';
import '../../core/widgets/profile_avatar.dart';
import '../../data/mock/mock_data.dart';
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
              const Text('Here is how your work week is coming together.'),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: .76),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.repeat_rounded, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'YOUR RECURRING COMMUTE',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .7,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Text(
                      '${profile.homeArea}  →  ${worksite.name}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${formatDays(commute.days)} · Arrive ${formatMinutes(commute.arrivalMinutes)} · Leave ${formatMinutes(commute.departureMinutes)}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.tonalIcon(
                      onPressed: () => context.push('/commute/edit'),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit commute'),
                    ),
                  ],
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
                      value: '$pendingIncoming',
                      label: 'incoming requests',
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
            ],
          ),
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
