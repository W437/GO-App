import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';

class AnimatedBottomNav extends StatefulWidget {
  final Widget child;
  final bool isVisible;
  final Duration duration;

  const AnimatedBottomNav({
    super.key,
    required this.child,
    required this.isVisible,
    this.duration = const Duration(milliseconds: 400),
  });

  @override
  State<AnimatedBottomNav> createState() => _AnimatedBottomNavState();
}

class _AnimatedBottomNavState extends State<AnimatedBottomNav>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _blurAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    // Start at shown state (value = 0 means visible, value = 1 means hidden)
    _controller.value = widget.isVisible ? 0.0 : 1.0;

    _setupAnimations();
  }

  void _setupAnimations() {
    // Slide: 0 -> shifts down outside screen (using percentage of height)
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.5, // 150% of widget height to ensure it's fully off screen
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    ));

    // Scale: 1.0 -> 0.6
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.6,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    ));

    // Blur: 0 -> 4
    _blurAnimation = Tween<double>(
      begin: 0.0,
      end: 4.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    ));

    // Rotate: 0 -> 15 degrees (converted to radians)
    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 15.0 * math.pi / 180, // 15 degrees in radians
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    ));
  }

  @override
  void didUpdateWidget(AnimatedBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isVisible != widget.isVisible) {
      if (widget.isVisible) {
        _controller.reverse(); // Animate to visible (value -> 0)
      } else {
        _controller.forward(); // Animate to hidden (value -> 1)
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Don't render at all when fully hidden to save resources
        if (_controller.value == 1.0) {
          return const SizedBox.shrink();
        }

        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 100), // Slide down
          child: Transform.scale(
            scale: _scaleAnimation.value,
            alignment: Alignment.bottomCenter,
            child: Transform.rotate(
              angle: _rotateAnimation.value,
              alignment: Alignment.bottomCenter,
              child: _blurAnimation.value > 0.01
                  ? ImageFiltered(
                      imageFilter: ImageFilter.blur(
                        sigmaX: _blurAnimation.value,
                        sigmaY: _blurAnimation.value,
                      ),
                      child: child,
                    )
                  : child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}
