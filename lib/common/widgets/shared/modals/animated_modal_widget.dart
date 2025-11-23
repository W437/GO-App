import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

/// Animated modal widget with buttery-smooth scale, rotation, and opacity entrance
/// Shows messages, buttons, or forms with a satisfying bouncy animation
///
/// Usage:
/// ```dart
/// AnimatedModalWidget.show(
///   context: context,
///   child: YourContent(),
/// );
/// ```
class AnimatedModalWidget extends StatefulWidget {
  final Widget child;
  final bool barrierDismissible;
  final Color? barrierColor;

  const AnimatedModalWidget({
    super.key,
    required this.child,
    this.barrierDismissible = true,
    this.barrierColor,
  });

  /// Show the modal with animation
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    bool barrierDismissible = true,
    Color? barrierColor,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: barrierColor ?? Colors.black.withOpacity(0.15),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return AnimatedModalWidget(
          barrierDismissible: barrierDismissible,
          barrierColor: barrierColor,
          child: child,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return _AnimatedModalTransition(
          animation: animation,
          child: child,
        );
      },
    );
  }

  @override
  State<AnimatedModalWidget> createState() => _AnimatedModalWidgetState();
}

class _AnimatedModalWidgetState extends State<AnimatedModalWidget> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: widget.child,
      ),
    );
  }
}

/// Transition builder for the modal animation
class _AnimatedModalTransition extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const _AnimatedModalTransition({
    required this.animation,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final t = animation.value;

    // Smooth scale with gentle overshoot bounce
    final scale = _smoothBounceScale(t);

    // Rotation that completes early for clean settle
    final rotation = _smoothRotation(t);

    // Quick fade-in at start
    final opacity = _smoothOpacity(t);

    // Motion blur peaks during fastest movement (mid-animation)
    final blurAmount = lerpDouble(0, 1.5, 1 - (t * 2 - 1).abs()) ?? 0;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: opacity,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: blurAmount,
              sigmaY: blurAmount,
              tileMode: TileMode.decal,
            ),
            child: Transform.scale(
              scale: scale,
              child: Transform.rotate(
                angle: rotation,
                child: child,
              ),
            ),
          ),
        );
      },
      child: child,
    );
  }

  // Buttery smooth scale with gentle spring
  double _smoothBounceScale(double t) {
    final clamped = t.clamp(0.0, 1.0);
    // Use easeOutBack for subtle elastic bounce
    final eased = Curves.easeOutBack.transform(clamped);
    return 0.6 + (eased * 0.4); // 0.6 → 1.0 with gentle overshoot
  }

  // Rotation completes smoothly in first 70%
  double _smoothRotation(double t) {
    final clamped = t.clamp(0.0, 1.0);
    final progress = (clamped / 0.7).clamp(0.0, 1.0);
    final eased = Curves.easeOutCubic.transform(progress);
    return (1 - eased) * 15 * (math.pi / 180);
  }

  // Opacity fades in quickly at start
  double _smoothOpacity(double t) {
    final clamped = t.clamp(0.0, 1.0);
    final progress = (clamped / 0.5).clamp(0.0, 1.0);
    return Curves.easeOut.transform(progress);
  }
}
