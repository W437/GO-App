/// Circular back button widget with optional text label and press effects
/// Provides iOS-style circular or pill-shaped back navigation button

import 'package:flutter/material.dart';

class CircularBackButtonWidget extends StatefulWidget {
  final VoidCallback? onPressed;
  final Color? iconColor;
  final Color? backgroundColor;
  final bool showText;
  final IconData? icon; // Custom icon (defaults to back arrow)
  final double? size; // Custom size (defaults to 44)
  final double? iconSize; // Custom icon size (defaults to 24)

  const CircularBackButtonWidget({
    super.key,
    this.onPressed,
    this.iconColor,
    this.backgroundColor,
    this.showText = false,
    this.icon,
    this.size,
    this.iconSize,
  });

  @override
  State<CircularBackButtonWidget> createState() => _CircularBackButtonWidgetState();
}

class _CircularBackButtonWidgetState extends State<CircularBackButtonWidget> with TickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _pressAnimation;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();

    // Press animation
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _pressAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(
      CurvedAnimation(
        parent: _pressController,
        curve: Curves.easeOut,
      ),
    );

    // Bounce animation
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.05)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.05, end: 0.98)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.98, end: 1.02)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.02, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 25,
      ),
    ]).animate(_bounceController);
  }

  @override
  void dispose() {
    _pressController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showText) {
      final baseColor = widget.backgroundColor ??
          Color.lerp(Theme.of(context).disabledColor.withOpacity(0.1), Colors.black, 0.1)!;
      final buttonSize = widget.size ?? 44;
      final buttonIconSize = widget.iconSize ?? 24;
      return Center(
        child: GestureDetector(
          onTapDown: (_) => _pressController.forward(),
          onTapUp: (_) {
            _pressController.reverse();
            _bounceController.forward(from: 0.0);
          },
          onTapCancel: () => _pressController.reverse(),
          onTap: widget.onPressed ?? () => Navigator.pop(context),
          child: AnimatedBuilder(
            animation: Listenable.merge([_pressAnimation, _bounceAnimation]),
            builder: (context, child) {
              return Transform.scale(
                scale: _pressAnimation.value * _bounceAnimation.value,
                child: child,
              );
            },
            child: Container(
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                color: baseColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  widget.icon ?? Icons.arrow_back_ios_rounded,
                  size: buttonIconSize,
                  color: widget.iconColor ?? Theme.of(context).textTheme.bodyLarge!.color,
                ),
              ),
            ),
          ),
        ),
      );
    }

    final baseColor = widget.backgroundColor ??
        Color.lerp(Theme.of(context).disabledColor.withOpacity(0.1), Colors.black, 0.1)!;
    return Center(
      child: GestureDetector(
        onTapDown: (_) => _pressController.forward(),
        onTapUp: (_) {
          _pressController.reverse();
          _bounceController.forward(from: 0.0);
        },
        onTapCancel: () => _pressController.reverse(),
        onTap: widget.onPressed ?? () => Navigator.pop(context),
        child: AnimatedBuilder(
          animation: Listenable.merge([_pressAnimation, _bounceAnimation]),
          builder: (context, child) {
            return Transform.scale(
              scale: _pressAnimation.value * _bounceAnimation.value,
              child: child,
            );
          },
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon ?? Icons.arrow_back_ios_rounded,
                  size: 20,
                  color: widget.iconColor ?? Theme.of(context).textTheme.bodyLarge!.color,
                ),
                const SizedBox(width: 4),
                Text(
                  'Back',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: widget.iconColor ?? Theme.of(context).textTheme.bodyLarge!.color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
