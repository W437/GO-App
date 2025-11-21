import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Custom page transition for GO App
///
/// Provides smooth, premium transitions between screens.
/// Easily customizable through parameters.
class CustomPageTransition extends CustomTransition {
  @override
  Widget buildTransition(
    BuildContext context,
    Curve? curve,
    Alignment? alignment,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // You can combine multiple animations here!
    // Current implementation: Slide from right + Fade + Slight scale

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1.0, 0.0), // Start from right
        end: Offset.zero, // End at normal position
      ).animate(CurvedAnimation(
        parent: animation,
        curve: curve ?? Curves.easeOutCubic, // Smooth deceleration
      )),
      child: FadeTransition(
        opacity: Tween<double>(
          begin: 0.0, // Start invisible
          end: 1.0,   // End fully visible
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeIn, // Quick fade-in
        )),
        child: ScaleTransition(
          scale: Tween<double>(
            begin: 0.95, // Start slightly smaller
            end: 1.0,    // End at normal size
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        ),
      ),
    );
  }
}

/// Alternative transition variations you can use:

/// Smooth fade transition (simple and elegant)
class FadePageTransition extends CustomTransition {
  @override
  Widget buildTransition(
    BuildContext context,
    Curve? curve,
    Alignment? alignment,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }
}

/// Scale from center (dynamic and engaging)
class ScalePageTransition extends CustomTransition {
  @override
  Widget buildTransition(
    BuildContext context,
    Curve? curve,
    Alignment? alignment,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return ScaleTransition(
      scale: Tween<double>(
        begin: 0.8,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: curve ?? Curves.easeOutCubic,
      )),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }
}

/// Slide from bottom (great for modals)
class SlideUpPageTransition extends CustomTransition {
  @override
  Widget buildTransition(
    BuildContext context,
    Curve? curve,
    Alignment? alignment,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.0, 1.0), // Start from bottom
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: curve ?? Curves.easeOutCubic,
      )),
      child: child,
    );
  }
}

/// Rotation + Scale (playful and eye-catching)
class RotateScalePageTransition extends CustomTransition {
  @override
  Widget buildTransition(
    BuildContext context,
    Curve? curve,
    Alignment? alignment,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return RotationTransition(
      turns: Tween<double>(
        begin: 0.05, // Slight rotation
        end: 0.0,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: curve ?? Curves.easeOut,
      )),
      child: ScaleTransition(
        scale: Tween<double>(
          begin: 0.9,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: curve ?? Curves.easeOutCubic,
        )),
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      ),
    );
  }
}
