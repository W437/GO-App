/// Custom ink well widget with smooth spring-based press animations
/// Provides iOS-style bouncy feedback with natural physics

import 'package:flutter/material.dart';

class CustomInkWellWidget extends StatefulWidget {
  final double? radius;
  final EdgeInsetsGeometry? padding;
  final Widget child;
  final VoidCallback onTap;
  final Color? highlightColor;
  final bool enableScaleEffect;

  const CustomInkWellWidget({
    super.key,
    this.radius,
    required this.child,
    required this.onTap,
    this.highlightColor,
    this.padding = EdgeInsets.zero,
    this.enableScaleEffect = true,
  });

  @override
  State<CustomInkWellWidget> createState() => _CustomInkWellWidgetState();
}

class _CustomInkWellWidgetState extends State<CustomInkWellWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    // Initialize with default no-op animation
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animateDown() {
    setState(() => _isPressed = true);
    if (!widget.enableScaleEffect) return;
    _controller.duration = const Duration(milliseconds: 150);
    _controller.reset();
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.decelerate),
    );
    _controller.forward();
  }

  Future<void> _animateUp() async {
    setState(() => _isPressed = false);
    if (!widget.enableScaleEffect) return;

    // Wait for press animation to complete if it's still running
    if (_controller.isAnimating) {
      await _controller.forward();
    }

    // Now start the release animation
    _controller.duration = const Duration(milliseconds: 550);
    _controller.reset();
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _animateDown(),
      onTapUp: (_) {
        _animateUp();
        Future.delayed(const Duration(milliseconds: 50), widget.onTap);
      },
      onTapCancel: () => _animateUp(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.enableScaleEffect ? (_scaleAnimation.value) : 1.0,
            child: child,
          );
        },
        child: Stack(
          children: [
            Padding(
              padding: widget.padding!,
              child: widget.child,
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedOpacity(
                  curve: Curves.easeInOut,
                  duration: const Duration(milliseconds: 200),
                  opacity: _isPressed ? 1.0 : 0.0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.highlightColor ?? Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(widget.radius ?? 0),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
