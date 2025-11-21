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
              const double startTranslateXRatio = 0.35; // Starts 35% to the right
              const double startScale = 0.92;
              const double startYAngle = 8.0 * pi / 180; // 8 degrees
              const double startZAngle = 1.5 * pi / 180; // 1.5 degrees
              const double overshootScale = 1.03;

              // --- Logic ---
              
              // 1) Slide & Un-tilt (0 -> 0.7)
              // We map p=[0, 0.7] to linear=[0, 1]
              final double linear = (p / 0.7).clamp(0.0, 1.0);
              
              final double translateX = width * startTranslateXRatio * (1.0 - linear);
              final double yAngle = startYAngle * (1.0 - linear);
              final double zAngle = startZAngle * (1.0 - linear);

              // 2) Overshoot Scale (0.7 -> 1.0)
              // We map p=[0.7, 1.0] to overshootPhase=[0, 1]
              final double overshootPhase = ((p - 0.7) / 0.3).clamp(0.0, 1.0);
              
              // Base scale goes from startScale -> 1.0 linearly over the whole 0->1? 
              // Or does it reach 1.0 at 0.7 and then bulge?
              // User spec: "Scale goes from ~0.92 -> overshoot 1.03 -> settle at 1.0"
              // Let's model it:
              // At p=0: 0.92
              // At p=0.7: 1.0 (approx)
              // At p=0.85: 1.03
              // At p=1.0: 1.0
              
              double currentScale;
              if (p <= 0.7) {
                // 0.92 -> 1.0
                currentScale = lerpDouble(startScale, 1.0, linear)!;
              } else {
                // 1.0 -> 1.03 -> 1.0
                // Sine wave for the bump
                // sin(0) = 0, sin(pi) = 0. 
                // We want sin(phase * pi).
                final bump = sin(overshootPhase * pi); 
                // But we want it to go up to 1.03.
                // Actually user formula: lerp(1.0, overshootScale, sin(overshootPhase * pi * 0.5)) ?
                // No, sin(pi*0.5) is 1 (peak). 
                // If we want peak at middle of 0.7->1.0, we use sin(phase * pi).
                currentScale = 1.0 + (overshootScale - 1.0) * sin(overshootPhase * pi);
              }

              // Corner Radius: 24 -> 0
              // Should probably vanish around p=0.8 or 1.0
              final double cornerRadius = 24.0 * (1.0 - p);

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
