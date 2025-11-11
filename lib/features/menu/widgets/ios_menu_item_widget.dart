import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';

class IosMenuItemWidget extends StatefulWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final Color iconBackgroundColor;
  final Color? iconColor;
  final Widget? trailing;
  final String? badge;
  final bool showChevron;
  final bool hideSeparator;
  final String? subtitle;

  const IosMenuItemWidget({
    super.key,
    required this.icon,
    required this.title,
    this.onTap,
    required this.iconBackgroundColor,
    this.iconColor,
    this.trailing,
    this.badge,
    this.showChevron = true,
    this.hideSeparator = false,
    this.subtitle,
  });

  @override
  State<IosMenuItemWidget> createState() => _IosMenuItemWidgetState();
}

class _IosMenuItemWidgetState extends State<IosMenuItemWidget> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pressedColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.04);

    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) {
        setState(() => _isPressed = true);
      } : null,
      onTapUp: widget.onTap != null ? (_) async {
        HapticFeedback.lightImpact();

        // Small delay to show pressed state
        await Future.delayed(const Duration(milliseconds: 80));

        if (mounted) {
          widget.onTap!();
          setState(() => _isPressed = false);
        }
      } : null,
      onTapCancel: () {
        if (mounted) {
          setState(() => _isPressed = false);
        }
      },
      child: Container(
        color: _isPressed ? pressedColor : Colors.transparent,
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        child: Column(
          children: [
            Row(
              children: [
                // iOS-style circular icon background
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: widget.iconBackgroundColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    widget.icon,
                    size: 18,
                    color: widget.iconColor ?? Colors.white,
                  ),
                ),
                const SizedBox(width: 12),

                // Title and subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: robotoRegular.copyWith(
                          fontSize: Dimensions.fontSizeDefault,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle!,
                          style: robotoRegular.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            color: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.color
                                ?.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Badge or trailing widget
                if (widget.badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.badge!,
                      style: robotoMedium.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  )
                else if (widget.trailing != null)
                  widget.trailing!,

                // Chevron arrow
                if (widget.showChevron && widget.onTap != null && widget.trailing == null) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withValues(alpha: 0.3),
                  ),
                ],
              ],
            ),

            // iOS-style separator with left inset
            if (!widget.hideSeparator)
              Container(
                margin: const EdgeInsets.only(left: 52, top: 12),
                height: 0.5,
                color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
              ),
          ],
        ),
      ),
    );
  }
}
