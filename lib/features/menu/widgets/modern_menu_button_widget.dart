import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';

/// Modern standalone menu button with rounded background
/// Designed to match contemporary mobile app UI patterns
class ModernMenuButtonWidget extends StatefulWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final Color iconBackgroundColor;
  final Color? iconColor;
  final Widget? trailing;
  final String? badge;
  final bool showChevron;
  final String? subtitle;

  const ModernMenuButtonWidget({
    super.key,
    required this.icon,
    required this.title,
    this.onTap,
    required this.iconBackgroundColor,
    this.iconColor,
    this.trailing,
    this.badge,
    this.showChevron = true,
    this.subtitle,
  });

  @override
  State<ModernMenuButtonWidget> createState() => _ModernMenuButtonWidgetState();
}

class _ModernMenuButtonWidgetState extends State<ModernMenuButtonWidget> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Pressed state overlay
    final pressedColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.03);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
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
          decoration: BoxDecoration(
            color: _isPressed ? pressedColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 0,
            vertical: 12,
          ),
          child: Row(
            children: [
              // Icon with rounded background
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: widget.iconBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.icon,
                  size: 24,
                  color: widget.iconColor ?? Colors.white,
                ),
              ),
              const SizedBox(width: 16),

              // Title and subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: robotoMedium.copyWith(
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
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
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
                  size: 24,
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withValues(alpha: 0.4),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
