import 'package:flutter/material.dart';

import '../../data/models/ride_request.dart';

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});
  final RequestStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (icon, colour) = switch (status) {
      RequestStatus.pending => (Icons.schedule_rounded, scheme.tertiary),
      RequestStatus.accepted => (Icons.check_circle_rounded, Colors.green),
      RequestStatus.declined => (Icons.cancel_rounded, scheme.error),
      RequestStatus.cancelled => (Icons.remove_circle_outline, scheme.outline),
    };
    return Chip(
      avatar: Icon(icon, size: 17, color: colour),
      label: Text(status.label),
      visualDensity: VisualDensity.compact,
    );
  }
}
