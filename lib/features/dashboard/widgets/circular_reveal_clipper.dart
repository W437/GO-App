import 'dart:math';
import 'package:flutter/material.dart';

class CircularRevealClipper extends CustomClipper<Path> {
  final double fraction;
  final Offset? centerOffset;
  final double? minRadius;
  final double? maxRadius;

  CircularRevealClipper({
    required this.fraction,
    this.centerOffset,
    this.minRadius,
    this.maxRadius,
  });

  @override
  Path getClip(Size size) {
    final center = centerOffset ?? Offset(size.width / 2, size.height / 2);
    final minR = minRadius ?? 0;
    final maxR = maxRadius ?? calcMaxRadius(size, center);

    return Path()
      ..addOval(
        Rect.fromCircle(
          center: center,
          radius: lerpDouble(minR, maxR, fraction),
        ),
      );
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;

  static double calcMaxRadius(Size size, Offset center) {
    final w = max(center.dx, size.width - center.dx);
    final h = max(center.dy, size.height - center.dy);
    return sqrt(w * w + h * h);
  }

  static double lerpDouble(double a, double b, double t) {
    return a * (1.0 - t) + b * t;
  }
}
