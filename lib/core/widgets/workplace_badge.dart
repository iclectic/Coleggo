import 'package:flutter/material.dart';

class WorkplaceBadge extends StatelessWidget {
  const WorkplaceBadge({this.compact = false, super.key});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message:
          'Confirms access to a workplace email or invitation, not a person’s character.',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 4 : 6,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.domain_verification_rounded, size: compact ? 15 : 17),
            const SizedBox(width: 5),
            Text(
              'Workplace verified',
              style: TextStyle(
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
