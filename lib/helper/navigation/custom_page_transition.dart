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
        // 1. Background Effect (Applied to the PREVIOUS route when THIS route is pushing/popping)
        // Note: In GetX CustomTransition, we only control the 'child' (the new page).
        // We cannot directly transform the previous page here. 
        // However, 'secondaryAnimation' controls how THIS page behaves when ANOTHER page is pushed on top.
        // So this logic handles THIS page becoming the background.
        if (secondaryAnimation.status != AnimationStatus.dismissed)
          AnimatedBuilder(
            animation: secondaryAnimation,
            builder: (context, child) {
              final p = secondaryAnimation.value;
              // Scale: 1.0 -> 0.96
              final scale = lerpDouble(1.0, 0.96, p)!;
              // Radius: 0 -> 16 (approx)
              final radius = lerpDouble(0.0, 16.0, p)!;
              // Dim: 0 -> 0.25
              final dimAlpha = lerpDouble(0.0, 0.25, p)!;

              // Apply perspective to background too for consistency
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
                  // Dim overlay
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
          // 2. Foreground Effect (Entrance/Exit of THIS page)
          AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              final p = animation.value;
              final size = MediaQuery.of(context).size;
              final width = size.width;

              // --- Parameters ---
              const double startTranslateXRatio = 1.1; // Starts fully off-screen to the right (1.1 to be safe)
              const double startScale = 0.92;
              const double startYAngle = 8.0 * pi / 180; // 8 degrees
              const double startZAngle = 1.5 * pi / 180; // 1.5 degrees
              const double overshootScale = 1.03;

              // --- Logic ---
              
              // Use standard curves for smoother motion
              // easeOutQuad for translation/rotation (slower start than Cubic, less "jumpy")
              final double smoothP = Curves.easeOutQuad.transform(p);
              
              // easeOutBack for scale (spring overshoot)
              final double scaleP = Curves.easeOutBack.transform(p);

              final double translateX = width * startTranslateXRatio * (1.0 - smoothP);
              final double yAngle = startYAngle * (1.0 - smoothP);
              final double zAngle = startZAngle * (1.0 - smoothP);

              // Scale: 0.92 -> 1.0 (with overshoot via easeOutBack)
              final double currentScale = startScale + (1.0 - startScale) * scaleP;

              // Corner Radius: 24 -> 0
              final double cornerRadius = 24.0 * (1.0 - smoothP);

              // --- Matrix Construction ---
              // Order: Perspective * Translate * Scale * Rotate
              final Matrix4 matrix = Matrix4.identity()
                ..setEntry(3, 2, 0.001); // Perspective

              // Translate
              matrix.translate(translateX, 0.0, 0.0);

              // Scale
              matrix.scale(currentScale, currentScale, 1.0);

              // Rotate (Y then Z)
              matrix.rotateY(yAngle); // Positive Y moves right side away (in Flutter's coord system with perspective)
              matrix.rotateZ(zAngle);

              return Transform(
                transform: matrix,
                alignment: Alignment.center, // Rotate around center
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(cornerRadius),
                  child: child,
                ),
              );
            },
            child: child,
          ),
      ],
    );
  }
}
