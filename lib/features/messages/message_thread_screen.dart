import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../data/mock/mock_data.dart';
import '../../data/models/message_thread.dart';
import '../state/providers.dart';

class MessageThreadScreen extends ConsumerStatefulWidget {
  const MessageThreadScreen({required this.threadId, super.key});
  final String threadId;

  @override
  ConsumerState<MessageThreadScreen> createState() =>
      _MessageThreadScreenState();
}

class _MessageThreadScreenState extends ConsumerState<MessageThreadScreen> {
  final _message = TextEditingController();

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final sent = await ref
        .read(appControllerProvider.notifier)
        .sendThreadMessage(widget.threadId, _message.text);
    if (sent) _message.clear();
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appControllerProvider);
    final thread = appState.messageThreads
        .where((item) => item.id == widget.threadId)
        .firstOrNull;
    final profileId = appState.profile?.id;
    if (thread == null || profileId == null || !thread.canAccess(profileId)) {
      return const Scaffold(
        body: Center(child: Text('Message thread not available.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Secure messages')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppConstants.maxContentWidth,
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Prototype messages are stored locally and are not real-time chat. Do not share home addresses, private contact details or payment information here.',
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: thread.messages.length,
                  itemBuilder: (context, index) {
                    final message = thread.messages[index];
                    return _MessageBubble(
                      message: message,
                      mine: message.senderProfileId == profileId,
                      onReport: message.senderProfileId == 'system'
                          ? null
                          : () => ref
                                .read(appControllerProvider.notifier)
                                .reportThreadMessage(
                                  threadId: thread.id,
                                  messageId: message.id,
                                  reason:
                                      'Message needs review in prototype moderation queue.',
                                ),
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _message,
                          minLines: 1,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Message accepted circle members',
                            helperText: 'Asynchronous prototype message',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton.filled(
                        onPressed: _send,
                        icon: const Icon(Icons.send_rounded),
                        tooltip: 'Send message',
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

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.mine,
    required this.onReport,
  });

  final CommuteMessage message;
  final bool mine;
  final VoidCallback? onReport;

  @override
  Widget build(BuildContext context) {
    final sender = message.senderProfileId == 'system'
        ? 'Coleggo'
        : mine
        ? 'You'
        : MockData.commuter(message.senderProfileId).firstName;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: mine
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Text(sender, style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 5),
                Text(message.body),
                if (message.deliveryState == MessageDeliveryState.flagged) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Stored with moderation flag',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
                if (onReport != null) ...[
                  const SizedBox(height: 6),
                  TextButton.icon(
                    onPressed: onReport,
                    icon: const Icon(Icons.flag_outlined),
                    label: const Text('Report'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
