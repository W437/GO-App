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
/// - Interactive swipe-to-dismiss from left edge
class CustomPageTransition extends CustomTransition {
  /// Threshold (0.0 - 1.0) of screen width to trigger dismiss
  static const double dismissThreshold = 0.3;

  /// Width of the left edge that accepts swipe gestures (0.0 - 1.0)
  static const double swipeEdgeWidth = 0.15;
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
          // 2. Foreground Effect with Interactive Swipe
          _InteractiveDismissibleWrapper(
            animation: animation,
            child: child,
          ),
      ],
    );
  }
}

/// Interactive wrapper that handles swipe-to-dismiss gesture
class _InteractiveDismissibleWrapper extends StatefulWidget {
  final Animation<double> animation;
  final Widget child;

  const _InteractiveDismissibleWrapper({
    required this.animation,
    required this.child,
  });

  @override
  State<_InteractiveDismissibleWrapper> createState() =>
      _InteractiveDismissibleWrapperState();
}

class _InteractiveDismissibleWrapperState
    extends State<_InteractiveDismissibleWrapper>
    with SingleTickerProviderStateMixin {
  double _dragOffset = 0.0;
  bool _isDragging = false;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _bounceAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _bounceController,
        curve: Curves.easeOutCubic,
      ),
    )..addListener(() {
        setState(() {
          _dragOffset = _bounceAnimation.value;
        });
      });
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details) {
    final size = MediaQuery.of(context).size;
    final edgeWidth = size.width * CustomPageTransition.swipeEdgeWidth;

    // Only allow drag if it starts from the left edge
    if (details.globalPosition.dx > edgeWidth) {
      return;
    }

    _isDragging = true;
    _bounceController.stop();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;

    setState(() {
      // Only allow dragging to the right (positive offset)
      _dragOffset = (_dragOffset + details.delta.dx).clamp(0.0, double.infinity);
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!_isDragging) return;
    _isDragging = false;

    final size = MediaQuery.of(context).size;
    final threshold = size.width * CustomPageTransition.dismissThreshold;

    if (_dragOffset > threshold) {
      // Dismiss the page
      Get.back();
    } else {
      // Bounce back to original position
      _bounceAnimation = Tween<double>(
        begin: _dragOffset,
        end: 0.0,
      ).animate(
        CurvedAnimation(
          parent: _bounceController,
          curve: Curves.easeOutCubic,
        ),
      );
      _bounceController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: _handleDragStart,
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: _handleDragEnd,
      child: AnimatedBuilder(
        animation: widget.animation,
        builder: (context, child) {
          // Custom Curves
          // Use a smooth, gentle curve for both open and close.
          final double curvedValue = Curves.easeOutCubic.transform(widget.animation.value);

          // Spring for scale
          // We use a custom Cubic with a subtle overshoot value (1.2) for a gentle bounce
          // since we are only scaling from 0.92 to 1.0 (a small delta).
          // This gives a smooth, natural feel without being too aggressive.
          final double scaleValue = widget.animation.status == AnimationStatus.reverse
              ? curvedValue // No overshoot on close
              : const Cubic(0.175, 0.885, 0.32, 1.2).transform(widget.animation.value);

          final size = MediaQuery.of(context).size;
          final width = size.width;

          // --- Parameters ---
          const double startTranslateXRatio = 1.1;
          const double startScale = 0.92;
          const double startYAngle = 8.0 * pi / 180;
          const double startZAngle = 1.5 * pi / 180;

          // --- Logic ---
          // Combine animation offset with drag offset
          final double animationTranslateX = width * startTranslateXRatio * (1.0 - curvedValue);
          final double totalTranslateX = animationTranslateX + _dragOffset;

          // Calculate progress based on combined offset (for rotation/scale)
          final double totalProgress = (totalTranslateX / (width * startTranslateXRatio)).clamp(0.0, 1.0);
          final double effectiveProgress = 1.0 - totalProgress;

          final double yAngle = startYAngle * totalProgress;
          final double zAngle = startZAngle * totalProgress;

          // Scale logic - use the animation's scale value but adjust if dragging
          final double currentScale = startScale + (1.0 - startScale) * scaleValue * effectiveProgress;

          // Corner Radius
          final double cornerRadius = 24.0 * totalProgress;

          // Shadow Opacity (fade in/out)
          final double shadowOpacity = (effectiveProgress * 0.5).clamp(0.0, 0.3);

          // --- Matrix ---
          final Matrix4 matrix = Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..translate(totalTranslateX, 0.0, 0.0)
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
        child: RepaintBoundary(child: widget.child),
      ),
    );
  }
}
