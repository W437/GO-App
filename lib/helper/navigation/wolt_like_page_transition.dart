import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Wolt-like transition that animates both foreground (animation) and background (secondaryAnimation).
/// Foreground: slides in from right with slight Y-rotation.
/// Background: scales down and shifts slightly left as new page comes in.
class WoltLikePageTransitionsBuilder extends PageTransitionsBuilder {
  const WoltLikePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Skip initial route transition
    if (route.settings.name == Navigator.defaultRouteName) {
      return child;
    }

    final Size size = MediaQuery.of(context).size;

    // Determine if this route is underneath another animating route
    final bool isBelowTop =
        secondaryAnimation.status != AnimationStatus.dismissed ||
        secondaryAnimation.value != 0.0;

    if (isBelowTop) {
      // BACKGROUND PARALLAX/SCALE
      return AnimatedBuilder(
        animation: secondaryAnimation,
        builder: (context, _) {
          final double t = Curves.easeOut.transform(secondaryAnimation.value);
          final double dx = -size.width * 0.12 * t; // stronger left shift
          final double scale = 1.0 - 0.08 * t;       // stronger scale down
          return Transform.translate(
            offset: Offset(dx, 0),
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.center,
              child: child,
            ),
          );
        },
      );
    } else {
      // FOREGROUND 3D SLIDE
      return AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final double t = Curves.easeOutCubic.transform(animation.value);
          final double dx = (1.0 - t) * size.width;
          const double maxAngle = 0.10; // ~6 deg
          final double angle = (1.0 - t) * maxAngle;
          final Matrix4 transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..translate(dx)
            ..rotateY(-angle);
          return Transform(
            alignment: Alignment.centerLeft,
            transform: transform,
            child: child,
          );
        },
      );
    }
  }
}
