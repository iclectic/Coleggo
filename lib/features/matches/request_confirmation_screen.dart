import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/profile_avatar.dart';
import '../../data/models/ride_request.dart';
import '../state/providers.dart';

class RequestConfirmationScreen extends ConsumerStatefulWidget {
  const RequestConfirmationScreen({
    required this.profileId,
    required this.kind,
    super.key,
  });
  final String profileId;
  final RequestKind kind;
  @override
  ConsumerState<RequestConfirmationScreen> createState() =>
      _RequestConfirmationScreenState();
}

class _RequestConfirmationScreenState
    extends ConsumerState<RequestConfirmationScreen> {
  bool _sending = false;
  Future<void> _send() async {
    setState(() => _sending = true);
    final sent = await ref
        .read(appControllerProvider.notifier)
        .sendRequest(widget.profileId, widget.kind);
    if (!mounted) return;
    if (sent) {
      context.go('/requests');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request sent. It is now pending.')),
      );
    } else {
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You already have an active request with this colleague.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(commuterProvider(widget.profileId));
    final days = ref
        .watch(appControllerProvider)
        .profile!
        .days
        .intersection(profile.days);
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm request')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  child: ProfileAvatar(initials: profile.initials, radius: 42),
                ),
                const SizedBox(height: 18),
                Text(
                  '${widget.kind.actionLabel} with ${profile.firstName}?',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'This will send a local mock request for ${formatDays(days)}.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.route_outlined),
                          title: const Text('Broad corridor only'),
                          subtitle: Text(profile.corridor),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.schedule_outlined),
                          title: const Text('Preferred departure'),
                          subtitle: Text(
                            'Around ${formatMinutes(profile.departureMinutes)}',
                          ),
                        ),
                        const ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.lock_outline_rounded),
                          title: Text('Private details stay private'),
                          subtitle: Text(
                            'No phone number, email or exact home address is shared.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _sending ? null : _send,
                  icon: const Icon(Icons.send_rounded),
                  label: Text(_sending ? 'Sending…' : 'Send request'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('Not now'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
