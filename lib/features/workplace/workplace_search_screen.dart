import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../data/models/workplace.dart';
import '../state/providers.dart';

class WorkplaceSearchScreen extends ConsumerStatefulWidget {
  const WorkplaceSearchScreen({super.key});

  @override
  ConsumerState<WorkplaceSearchScreen> createState() =>
      _WorkplaceSearchScreenState();
}

class _WorkplaceSearchScreenState extends ConsumerState<WorkplaceSearchScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final workplaces = ref
        .watch(workplaceRepositoryProvider)
        .getWorkplaces()
        .where((item) => item.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.appName)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppConstants.maxFormWidth,
            ),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'Where do you work?',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose a fictional organisation to explore the Coleggo prototype.',
                ),
                const SizedBox(height: 20),
                TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search_rounded),
                    labelText: 'Search workplaces',
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.science_outlined),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'All organisations, worksites and people shown here are fictional prototype data.',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                for (final workplace in workplaces)
                  _WorkplaceCard(workplace: workplace),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkplaceCard extends ConsumerWidget {
  const _WorkplaceCard({required this.workplace});
  final Workplace workplace;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(child: Text(workplace.name.substring(0, 1))),
        title: Text(
          workplace.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${workplace.industry} · ${workplace.worksites.length} ${workplace.worksites.length == 1 ? 'worksite' : 'worksites'}',
        ),
        children: workplace.worksites
            .map(
              (site) => ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                leading: const Icon(Icons.location_city_rounded),
                title: Text(site.name),
                subtitle: Text(site.area),
                trailing: const Icon(Icons.arrow_forward_rounded),
                onTap: () async {
                  await ref
                      .read(appControllerProvider.notifier)
                      .selectWorkplace(workplace.id, site.id);
                  if (context.mounted) context.go('/verify');
                },
              ),
            )
            .toList(),
      ),
    );
  }
}
