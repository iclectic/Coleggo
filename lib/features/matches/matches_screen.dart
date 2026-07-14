import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/widgets/compatibility_indicator.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/profile_avatar.dart';
import '../../core/widgets/workplace_badge.dart';
import '../../data/models/commuter_profile.dart';
import '../state/providers.dart';

class MatchesScreen extends ConsumerStatefulWidget {
  const MatchesScreen({super.key});
  @override
  ConsumerState<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends ConsumerState<MatchesScreen> {
  CommuteRole? _filter;
  @override
  Widget build(BuildContext context) {
    final all = ref.watch(matchesProvider);
    final matches = _filter == null
        ? all
        : all.where((item) => item.profile.role == _filter).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Matches')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppConstants.maxContentWidth,
          ),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Estimated compatibility uses broad areas, preferred times, worksite, days, and role. It is not a measured route.',
                      ),
                      const SizedBox(height: 14),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ChoiceChip(
                              label: const Text('All'),
                              selected: _filter == null,
                              onSelected: (_) => setState(() => _filter = null),
                            ),
                            const SizedBox(width: 8),
                            ...CommuteRole.values.map(
                              (role) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(role.label),
                                  selected: _filter == role,
                                  onSelected: (_) =>
                                      setState(() => _filter = role),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (matches.isEmpty)
                const SliverFillRemaining(
                  child: EmptyState(
                    icon: Icons.person_search_rounded,
                    title: 'No matches in this filter',
                    message:
                        'Try showing all roles or update your commuting days.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  sliver: SliverList.builder(
                    itemCount: matches.length,
                    itemBuilder: (context, index) {
                      final match = matches[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () =>
                              context.push('/matches/${match.profile.id}'),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ProfileAvatar(initials: match.profile.initials),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            match.profile.firstName,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Flexible(
                                            child: WorkplaceBadge(
                                              compact: true,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        '${match.profile.role.label} · ${match.profile.homeArea}',
                                      ),
                                      const SizedBox(height: 9),
                                      for (final reason in match.reasons.take(
                                        3,
                                      ))
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 3,
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.check_rounded,
                                                size: 16,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                              ),
                                              const SizedBox(width: 5),
                                              Expanded(
                                                child: Text(
                                                  reason,
                                                  style: Theme.of(
                                                    context,
                                                  ).textTheme.bodySmall,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                CompatibilityIndicator(score: match.score),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
