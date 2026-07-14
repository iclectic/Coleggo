import 'package:flutter/material.dart';

class CompatibilityIndicator extends StatelessWidget {
  const CompatibilityIndicator({
    required this.score,
    this.size = 58,
    super.key,
  });
  final int score;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Estimated compatibility $score per cent',
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.square(
              dimension: size,
              child: CircularProgressIndicator(
                value: score / 100,
                strokeWidth: 6,
                strokeCap: StrokeCap.round,
                backgroundColor: scheme.surfaceContainerHighest,
              ),
            ),
            Text('$score', style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}
