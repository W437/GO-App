import 'package:flutter/material.dart';

class CircularBackButtonWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    if (!showText) {
      return Center(
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: backgroundColor ?? Theme.of(context).disabledColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed ?? () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(22),
              splashFactory: InkRipple.splashFactory,
              child: Center(
                child: Icon(
                  Icons.arrow_back_ios_rounded,
                  size: 24,
                  color: iconColor ?? Theme.of(context).textTheme.bodyLarge!.color,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Center(
      child: Material(
        color: backgroundColor ?? Theme.of(context).disabledColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onPressed ?? () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(22),
          splashFactory: InkRipple.splashFactory,
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.arrow_back_ios_rounded,
                  size: 20,
                  color: iconColor ?? Theme.of(context).textTheme.bodyLarge!.color,
                ),
                const SizedBox(width: 4),
                Text(
                  'Back',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: iconColor ?? Theme.of(context).textTheme.bodyLarge!.color,
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
