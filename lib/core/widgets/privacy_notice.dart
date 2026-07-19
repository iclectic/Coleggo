import 'package:flutter/material.dart';

class PrivacyNotice extends StatelessWidget {
  const PrivacyNotice({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) => Semantics(
    label:
        'Privacy notice. Exact home addresses and precise locations are hidden before mutual acceptance.',
    child: Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.privacy_tip_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              compact
                  ? 'Exact addresses stay hidden. Use public meeting points.'
                  : 'Exact home addresses, private contact details and precise locations are not shown before mutual acceptance. Coleggo encourages public meeting points such as station entrances, recognised landmarks and workplace shuttle stops.',
            ),
          ),
        ],
      ),
    ),
  );
}
