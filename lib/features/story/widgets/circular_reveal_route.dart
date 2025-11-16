import 'package:flutter/material.dart';
import 'package:godelivery_user/features/story/widgets/circular_clipper.dart';

/// Custom page route with circular reveal animation
/// Opens with a circular reveal from the click position, closes by shrinking back
class CircularRevealRoute<T> extends PageRoute<T> {
  final Widget child;
  final Offset clickPosition;
  final double initialRadius;

  CircularRevealRoute({
    required this.child,
    required this.clickPosition,
    this.initialRadius = 35.0, // Default to story circle radius
    RouteSettings? settings,
  }) : super(settings: settings);

  @override
  Color? get barrierColor => Colors.black.withOpacity(0.5);

  @override
  String? get barrierLabel => null;

  @override
  bool get opaque => false;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 400);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 300);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return child;
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final screenSize = MediaQuery.of(context).size;
    final maxRadius = calculateMaxRadius(screenSize, clickPosition);

    // Use a curved animation for smoother effect
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOut,
      reverseCurve: Curves.easeInOut,
    );

    return AnimatedBuilder(
      animation: curvedAnimation,
      builder: (context, child) {
        // Interpolate radius from initial (story circle) to max (full screen)
        final radius = initialRadius + (maxRadius - initialRadius) * curvedAnimation.value;

        return ClipPath(
          clipper: CircularClipper(
            center: clickPosition,
            radius: radius,
          ),
          child: child,
        );
      },
      child: child,
    );
  }
}
