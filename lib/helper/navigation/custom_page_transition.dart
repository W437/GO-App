import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Custom page transition mimicking the Wolt app's 3D card effect.
///
/// Features:
/// - 3D Perspective & Rotation
/// - Spring-based overshoot on entry
/// - Background scaling and dimming
/// - Interactive swipe-to-close support (via standard Get/Navigator gestures)
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
    return Stack(
      children: [
        // 1. Background Effect
        if (secondaryAnimation.status != AnimationStatus.dismissed)
          AnimatedBuilder(
            animation: secondaryAnimation,
            builder: (context, child) {
              final p = secondaryAnimation.value;
              final scale = lerpDouble(1.0, 0.96, p)!;
              final radius = lerpDouble(0.0, 16.0, p)!;
              final dimAlpha = lerpDouble(0.0, 0.4, p)!; // Increased dimming for better contrast

              final Matrix4 matrix = Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..scale(scale, scale, 1.0);

              return Stack(
                children: [
                  Transform(
                    transform: matrix,
                    alignment: Alignment.center,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(radius),
                      child: child,
                    ),
                  ),
                  IgnorePointer(
                    child: Container(
                      color: Colors.black.withOpacity(dimAlpha),
                    ),
                  ),
                ],
              );
            },
            child: child,
          )
        else
          // 2. Foreground Effect
          AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              // Custom Curves
              // Use a very smooth, natural curve for both open and close.
              final double curvedValue = Curves.easeOutQuart.transform(animation.value);

              // Spring for scale
              // We use a custom Cubic with a higher overshoot value (1.5) to make the bounce visible
              // since we are only scaling from 0.92 to 1.0 (a small delta).
              // Standard easeOutBack (1.275) only gives ~0.8% overshoot on this delta.
              // This custom curve gives ~4% overshoot (1.04).
              final double scaleValue = animation.status == AnimationStatus.reverse
                  ? curvedValue // No overshoot on close
                  : const Cubic(0.175, 0.885, 0.32, 1.5).transform(animation.value);

              final size = MediaQuery.of(context).size;
              final width = size.width;

              // --- Parameters ---
              const double startTranslateXRatio = 1.1;
              const double startScale = 0.92;
              const double startYAngle = 8.0 * pi / 180;
              const double startZAngle = 1.5 * pi / 180;

              // --- Logic ---
              final double translateX = width * startTranslateXRatio * (1.0 - curvedValue);
              final double yAngle = startYAngle * (1.0 - curvedValue);
              final double zAngle = startZAngle * (1.0 - curvedValue);

              // Scale logic
              final double currentScale = startScale + (1.0 - startScale) * scaleValue;

              // Corner Radius
              final double cornerRadius = 24.0 * (1.0 - curvedValue);

              // Shadow Opacity (fade in/out)
              final double shadowOpacity = (curvedValue * 0.5).clamp(0.0, 0.3);

              // --- Matrix ---
              final Matrix4 matrix = Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..translate(translateX, 0.0, 0.0)
                ..scale(currentScale, currentScale, 1.0)
                ..rotateY(yAngle)
                ..rotateZ(zAngle);

              Widget transformedChild = child ?? const SizedBox();

              // Apply ClipRRect if needed
              if (cornerRadius > 0.5) {
                transformedChild = ClipRRect(
                  borderRadius: BorderRadius.circular(cornerRadius),
                  child: transformedChild,
                );
              }

              // Wrap in Container for Shadow
              // We apply the shadow *outside* the clip if possible, or to a container wrapping the clip.
              // Since the clip clips the child, we need the shadow on the container *before* clipping? 
              // No, shadow is usually on the "card" shape.
              // If we clip the child, we lose the shadow if it's drawn by the child.
              // So we wrap the clipped child in a container that has the shadow? 
              // But the container needs to match the clip shape.
              // Actually, physical model or DecoratedBox with borderRadius matches.
              
              return Transform(
                transform: matrix,
                alignment: Alignment.center,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(cornerRadius),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(shadowOpacity),
                        blurRadius: 30,
                        spreadRadius: 5,
                        offset: const Offset(-10, 10), // Shadow to the left/bottom
                      ),
                    ],
                  ),
                  child: transformedChild,
                ),
              );
            },
            child: RepaintBoundary(child: child),
          ),
      ],
    );
  }
}
