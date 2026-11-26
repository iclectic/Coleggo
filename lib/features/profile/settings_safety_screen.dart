import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/app_state.dart';
import '../state/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preference = ref.watch(appControllerProvider).themePreference;
    final backendModeEnabled = ref.watch(backendModeEnabledProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Appearance',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SegmentedButton<AppThemePreference>(
                expandedInsets: EdgeInsets.zero,
                segments: const [
                  ButtonSegment(
                    value: AppThemePreference.system,
                    label: Text('System'),
                    icon: Icon(Icons.brightness_auto_rounded),
                  ),
                  ButtonSegment(
                    value: AppThemePreference.light,
                    label: Text('Light'),
                    icon: Icon(Icons.light_mode_outlined),
                  ),
                  ButtonSegment(
                    value: AppThemePreference.dark,
                    label: Text('Dark'),
                    icon: Icon(Icons.dark_mode_outlined),
                  ),
                ],
                selected: {preference},
                onSelectionChanged: (value) => ref
                    .read(appControllerProvider.notifier)
                    .setTheme(value.first),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Prototype',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.shield_outlined),
                  title: const Text('Safety and privacy'),
                  subtitle: const Text(
                    'Understand what Coleggo does and does not verify',
                  ),
                  trailing: const Icon(Icons.arrow_forward_rounded),
                  onTap: () => context.push('/safety'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.restart_alt_rounded,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(
                    'Reset prototype data',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  subtitle: const Text(
                    'Clear local progress and return to onboarding',
                  ),
                  onTap: () => _confirmReset(context, ref),
                ),
                if (backendModeEnabled) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.download_outlined),
                    title: const Text('Export my data'),
                    subtitle: const Text(
                      'Download a copy of your account, membership and audit data',
                    ),
                    onTap: () => _exportAccountData(context, ref),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(
                      Icons.delete_forever_outlined,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    title: Text(
                      'Delete account',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    subtitle: const Text(
                      'Permanently delete your server account and its data',
                    ),
                    onTap: () => _confirmAccountDeletion(context, ref),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final reset =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Reset Coleggo?'),
            content: const Text(
              'This clears your local prototype profile, commute and requests. It cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Keep my data'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Reset'),
              ),
            ],
          ),
        ) ??
        false;
    if (!reset) return;
    await ref.read(appControllerProvider.notifier).reset();
    if (context.mounted) context.go('/onboarding');
  }

  Future<void> _exportAccountData(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final exported = await ref
        .read(appControllerProvider.notifier)
        .exportAccountData();
    if (!context.mounted) return;
    if (exported == null) {
      final error = ref.read(appControllerProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Your data export could not be prepared.')),
      );
      return;
    }
    final membershipCount = (exported['memberships'] as List<dynamic>? ?? const []).length;
    final eventCount = (exported['auditEvents'] as List<dynamic>? ?? const []).length;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Data export ready'),
        content: Text(
          'Exported at ${exported['exportedAt'] ?? 'now'}. '
          'Includes $membershipCount membership${membershipCount == 1 ? '' : 's'} '
          'and $eventCount audit event${eventCount == 1 ? '' : 's'}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAccountDeletion(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final delete = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete your account?'),
            content: const Text(
              'This permanently deletes your server account, profile, memberships, requests, journeys and notifications. This cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete account'),
              ),
            ],
          ),
        ) ??
        false;
    if (!delete) return;

    final deleted = await ref
        .read(appControllerProvider.notifier)
        .deleteAccount();
    if (!context.mounted) return;
    if (deleted) {
      context.go('/onboarding');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your account has been deleted.')),
      );
      return;
    }
    final error = ref.read(appControllerProvider).errorMessage;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Your account could not be deleted.')),
    );
  }
}

class SafetyScreen extends StatelessWidget {
  const SafetyScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Safety and privacy')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.health_and_safety_rounded, size: 38),
              const SizedBox(height: 12),
              Text(
                'Travel thoughtfully',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Coleggo helps verified colleagues discover compatible commute patterns. It is not a taxi, identity or safeguarding service.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const _SafetyItem(
          Icons.domain_verification_outlined,
          'What workplace verification means',
          'It confirms access to a workplace email or invitation. It does not confirm a person’s character, identity documents or employment status.',
        ),
        const _SafetyItem(
          Icons.no_crash_outlined,
          'Driver responsibility',
          'Coleggo does not verify driving ability, licences, vehicle condition or insurance. Drivers remain responsible for their vehicle, licence and insurance.',
        ),
        const _SafetyItem(
          Icons.policy_outlined,
          'Prototype limitations',
          'Coleggo does not verify criminal history, identity documents, driving licences or insurance in this prototype.',
        ),
        const _SafetyItem(
          Icons.location_on_outlined,
          'Meet in public',
          'Choose a safe, well-lit public pickup point. Avoid sharing an exact home address until you are comfortable and it is genuinely necessary.',
        ),
        const _SafetyItem(
          Icons.visibility_off_outlined,
          'Private by default',
          'Before mutual acceptance, Coleggo shows broad areas and corridors only. Telephone numbers, private emails, precise coordinates and daily movement histories are not displayed.',
        ),
      ],
    ),
  );
}

class _SafetyItem extends StatelessWidget {
  const _SafetyItem(this.icon, this.title, this.body);
  final IconData icon;
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(body),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
