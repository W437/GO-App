/// Circular back button widget with optional text label and press effects
/// Provides iOS-style circular or pill-shaped back navigation button

import 'package:flutter/material.dart';

class CircularBackButtonWidget extends StatefulWidget {
  final VoidCallback? onPressed;
  final Color? iconColor;
  final Color? backgroundColor;
  final bool showText;

  const CircularBackButtonWidget({
    super.key,
    this.onPressed,
    this.iconColor,
    this.backgroundColor,
    this.showText = false,
  });

  @override
  State<CircularBackButtonWidget> createState() => _CircularBackButtonWidgetState();
}

class _CircularBackButtonWidgetState extends State<CircularBackButtonWidget> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.showText) {
      final baseColor = widget.backgroundColor ?? Theme.of(context).disabledColor.withOpacity(0.1);
      return Center(
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onPressed ?? () => Navigator.pop(context),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _isPressed ? Color.lerp(baseColor, Colors.black, 0.1) : baseColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                Icons.arrow_back_ios_rounded,
                size: 24,
                color: widget.iconColor ?? Theme.of(context).textTheme.bodyLarge!.color,
              ),
            ),
          ),
        ),
      );
    }

    final baseColor = widget.backgroundColor ?? Theme.of(context).disabledColor.withOpacity(0.1);
    return Center(
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onPressed ?? () => Navigator.pop(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: _isPressed ? Color.lerp(baseColor, Colors.black, 0.1) : baseColor,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.arrow_back_ios_rounded,
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
    );
  }
}
