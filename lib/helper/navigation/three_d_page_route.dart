import 'dart:math';
import 'package:flutter/material.dart';

/// A reusable 3D page route that animates only the incoming page and leaves the
/// previous route stationary behind it. Marked non-opaque so the underlying
/// screen remains visible during the transition/interactive drag.
class ThreeDPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  ThreeDPageRoute({
    required this.page,
    Duration duration = const Duration(milliseconds: 450),
  }) : super(
          opaque: false,
          barrierColor: Colors.transparent,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Use Curves.easeOutCubic for a smooth transform.
            final double curvedValue = Curves.easeOutCubic.transform(animation.value);

            // Parameters for 3D effect.
            const double startTranslateXRatio = 1.1;
            const double startScale = 0.92;
            const double startYAngle = 8.0 * pi / 180;
            const double startZAngle = 1.5 * pi / 180;

            final size = MediaQuery.of(context).size;
            final width = size.width;

            // Translate from right to left.
            final double animationTranslateX = width * startTranslateXRatio * (1.0 - curvedValue);
            final double totalTranslateX = animationTranslateX;

            // Progress for rotation/scale.
            final double totalProgress = (totalTranslateX / (width * startTranslateXRatio)).clamp(0.0, 1.0);
            final double effectiveProgress = 1.0 - totalProgress;

            final double yAngle = startYAngle * totalProgress;
            final double zAngle = startZAngle * totalProgress;

            // Scale logic.
            final double scaleValue = animation.status == AnimationStatus.reverse
                ? curvedValue
                : const Cubic(0.175, 0.885, 0.32, 1.2).transform(animation.value);
            final double currentScale = startScale + (1.0 - startScale) * scaleValue * effectiveProgress;

            // Corner Radius.
            final double cornerRadius = 24.0 * totalProgress;

            // Shadow Opacity.
            final double shadowOpacity = (effectiveProgress * 0.5).clamp(0.0, 0.3);

            Widget transformedChild = child;
            if (cornerRadius > 0.5) {
              transformedChild = ClipRRect(
                borderRadius: BorderRadius.circular(cornerRadius),
                child: transformedChild,
              );
            }

            final Matrix4 matrix = Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..translate(totalTranslateX, 0.0, 0.0)
              ..scale(currentScale, currentScale, 1.0)
              ..rotateY(yAngle)
              ..rotateZ(zAngle);

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
                      offset: const Offset(-10, 10),
                    ),
                  ],
                ),
                child: transformedChild,
              ),
            );
          },
        );
}
