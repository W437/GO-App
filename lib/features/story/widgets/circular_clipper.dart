import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Custom clipper for circular reveal animation
/// Creates a circular clip path that can grow or shrink from a center point
class CircularClipper extends CustomClipper<Path> {
  final Offset center;
  final double radius;

  CircularClipper({
    required this.center,
    required this.radius,
  });

  @override
  Path getClip(Size size) {
    final path = Path();

    // Create a circular path centered at the given position
    path.addOval(Rect.fromCircle(
      center: center,
      radius: radius,
    ));

    return path;
  }

  @override
  bool shouldReclip(CircularClipper oldClipper) {
    // Reclip if center or radius has changed
    return oldClipper.center != center || oldClipper.radius != radius;
  }
}

/// Helper to calculate the maximum radius needed to cover the entire screen
/// from a given center point
double calculateMaxRadius(Size screenSize, Offset center) {
  // Calculate distance to each corner
  final topLeft = (center - Offset.zero).distance;
  final topRight = (center - Offset(screenSize.width, 0)).distance;
  final bottomLeft = (center - Offset(0, screenSize.height)).distance;
  final bottomRight = (center - Offset(screenSize.width, screenSize.height)).distance;

  // Return the maximum distance (to ensure full coverage)
  return math.max(
    math.max(topLeft, topRight),
    math.max(bottomLeft, bottomRight),
  );
}
