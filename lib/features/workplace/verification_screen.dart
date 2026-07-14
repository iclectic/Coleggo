import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../data/mock/mock_data.dart';
import '../state/providers.dart';

class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({super.key});

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _code = TextEditingController();
  bool _sent = false;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_sent) {
      setState(() => _sent = true);
      return;
    }
    setState(() => _busy = true);
    final verified = await ref
        .read(appControllerProvider.notifier)
        .verifyWorkEmail(_email.text.trim(), _code.text.trim());
    if (!mounted) return;
    setState(() => _busy = false);
    if (verified) {
      context.go('/setup');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'That code does not match. Use the prototype code 246810.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final workplace = MockData.workplace(
      state.selectedWorkplaceId ?? 'northstar',
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Verify workplace')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppConstants.maxFormWidth,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.mark_email_read_outlined,
                    size: 62,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Connect to ${workplace.name}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This simulated check confirms access to a workplace email, not a person’s identity or character.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !_sent,
                    decoration: const InputDecoration(
                      labelText: 'Work email address',
                      prefixIcon: Icon(Icons.alternate_email_rounded),
                    ),
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      if (!email.contains('@') || !email.contains('.')) {
                        return 'Enter a valid work email address';
                      }
                      return null;
                    },
                  ),
                  if (_sent) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _code,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Six-digit code',
                        prefixIcon: Icon(Icons.pin_outlined),
                        helperText: 'Prototype code: 246810',
                      ),
                      validator: (value) => value?.length == 6
                          ? null
                          : 'Enter the six-digit code',
                    ),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        'Simulated email sent. No message has left this device.',
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _busy ? null : _submit,
                    icon: Icon(
                      _sent ? Icons.verified_rounded : Icons.send_rounded,
                    ),
                    label: Text(
                      _sent ? 'Verify and continue' : 'Send mock code',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
