import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({required this.initials, this.radius = 26, super.key});

  final String initials;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final hue =
        initials.codeUnits.fold<int>(0, (sum, item) => sum + item) % 360;
    final start = HSLColor.fromAHSL(1, hue.toDouble(), 0.55, 0.45).toColor();
    final end = HSLColor.fromAHSL(1, (hue + 38) % 360, 0.62, 0.58).toColor();
    return Semantics(
      label: 'Profile initials $initials',
      child: Container(
        width: radius * 2,
        height: radius * 2,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: [start, end]),
        ),
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: radius * .56,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
