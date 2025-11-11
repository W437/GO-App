import 'package:flutter/material.dart';

/// Reusable rounded icon button with iOS-style press effect
/// Used for close buttons, action buttons, etc.
class RoundedIconButtonWidget extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final double size;
  final double iconSize;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? pressedColor;

  const RoundedIconButtonWidget({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 44,
    this.iconSize = 24,
    this.backgroundColor,
    this.iconColor,
    this.pressedColor,
  });

  @override
  State<RoundedIconButtonWidget> createState() => _RoundedIconButtonWidgetState();
}

class _RoundedIconButtonWidgetState extends State<RoundedIconButtonWidget> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.backgroundColor ?? Colors.grey.withOpacity(0.1);
    final pressedColor = widget.pressedColor ?? Colors.grey.withOpacity(0.25);
    final iconColor = widget.iconColor ?? Colors.black87;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) async {
        await Future.delayed(const Duration(milliseconds: 80));
        if (mounted) {
          setState(() => _isPressed = false);
          widget.onPressed();
        }
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: _isPressed ? pressedColor : backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            widget.icon,
            size: widget.iconSize,
            color: iconColor,
          ),
        ),
      ),
    );
  }
}
