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
    with TickerProviderStateMixin {
  late AnimationController _hideController;
  late AnimationController _springController;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _blurAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _springAnimation;

  @override
  void initState() {
    super.initState();

    _hideController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Start at shown state (value = 0 means visible, value = 1 means hidden)
    _hideController.value = widget.isVisible ? 0.0 : 1.0;
    // Spring starts "completed" so multiply doesn't affect initial state
    _springController.value = 1.0;

    _setupAnimations();
  }

  void _setupAnimations() {
    // Slide: 0 -> shifts down outside screen
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.5,
    ).animate(CurvedAnimation(
      parent: _hideController,
      curve: Curves.easeInOutCubic,
    ));

    // Scale: 1.0 -> 0.6 (for hiding)
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.6,
    ).animate(CurvedAnimation(
      parent: _hideController,
      curve: Curves.easeInOutCubic,
    ));

    // Blur: 0 -> 4
    _blurAnimation = Tween<double>(
      begin: 0.0,
      end: 4.0,
    ).animate(CurvedAnimation(
      parent: _hideController,
      curve: Curves.easeInOutCubic,
    ));

    // Rotate: 0 -> 15 degrees
    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 15.0 * math.pi / 180,
    ).animate(CurvedAnimation(
      parent: _hideController,
      curve: Curves.easeInOutCubic,
    ));

    // Opacity: 1.0 -> 0.7
    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.7,
    ).animate(CurvedAnimation(
      parent: _hideController,
      curve: Curves.easeInOutCubic,
    ));

    // Spring bounce: overshoot then settle back to 1.0 (only for showing)
    _springAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.04),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.04, end: 0.98)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.98, end: 1.01)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.01, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 25,
      ),
    ]).animate(_springController);
  }

  @override
  void didUpdateWidget(AnimatedBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isVisible != widget.isVisible) {
      if (widget.isVisible) {
        // Showing: reverse hide animation, start spring at 300ms
        _hideController.reverse();
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _springController.forward(from: 0.0);
          }
        });
      } else {
        // Hiding: just run hide animation
        _hideController.forward();
      }
    }
  }

  @override
  void dispose() {
    _hideController.dispose();
    _springController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_hideController, _springController]),
      builder: (context, child) {
        // Don't render at all when fully hidden
        if (_hideController.value == 1.0) {
          return const SizedBox.shrink();
        }

        // Combine scale from hide animation with spring bounce
        final scaleValue = _scaleAnimation.value * _springAnimation.value;

        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value * 100),
            child: Transform.scale(
              scale: scaleValue,
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
          ),
        );
      },
      child: widget.child,
    );
  }
}

