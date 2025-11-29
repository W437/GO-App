import 'package:flutter/material.dart';
import 'package:godelivery_user/util/styles.dart';

/// A reusable primary-colored badge widget for displaying counts or values
/// with an optional leading icon. Text color is always black for contrast.
class PrimaryBadgeWidget extends StatelessWidget {
  final dynamic value;
  final IconData? icon;
  final double? iconSize;
  final double fontSize;
  final EdgeInsetsGeometry? padding;

  const PrimaryBadgeWidget({
    super.key,
    required this.value,
    this.icon,
    this.iconSize,
    this.fontSize = 12,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: iconSize ?? fontSize + 2,
              color: Colors.black,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            '$value',
            style: robotoMedium.copyWith(
              fontSize: fontSize,
              color: Colors.black,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
