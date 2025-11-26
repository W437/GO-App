import 'package:flutter/material.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';

/// A tab item for [CustomTabbedButton].
class TabbedButtonItem {
  final String label;
  final IconData? icon;
  final bool showBadge;

  const TabbedButtonItem({
    required this.label,
    this.icon,
    this.showBadge = false,
  });
}

/// Style variant for the tabbed button.
enum TabbedButtonStyle {
  /// Light style - light background with card-colored active indicator.
  /// Best for light mode UI on white/light backgrounds.
  light,

  /// Dark style - dark semi-transparent background with accent-colored active indicator.
  /// Best for overlays on maps, images, or dark backgrounds.
  dark,
}

/// A reusable tabbed button widget with a sliding active indicator.
///
/// Supports two styles:
/// - [TabbedButtonStyle.light]: For use on light backgrounds (e.g., home screen sections)
/// - [TabbedButtonStyle.dark]: For use on dark backgrounds or overlays (e.g., map screens)
///
/// Example usage:
/// ```dart
/// CustomTabbedButton(
///   items: [
///     TabbedButtonItem(label: 'Categories'),
///     TabbedButtonItem(label: 'Cuisines'),
///   ],
///   selectedIndex: _selectedTab,
///   onTabChanged: (index) => setState(() => _selectedTab = index),
///   style: TabbedButtonStyle.light,
/// )
/// ```
class CustomTabbedButton extends StatelessWidget {
  /// The list of tab items to display.
  final List<TabbedButtonItem> items;

  /// The currently selected tab index.
  final int selectedIndex;

  /// Callback when a tab is selected.
  final ValueChanged<int> onTabChanged;

  /// The visual style of the button.
  final TabbedButtonStyle style;

  /// Optional fixed width for the entire button.
  /// If null, the button will size to its content.
  final double? width;

  /// Optional fixed height for the button.
  /// Defaults to 35.
  final double height;

  /// The color of the active indicator.
  /// If null, uses theme primary color for light style,
  /// or a cyan accent for dark style.
  final Color? activeColor;

  const CustomTabbedButton({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onTabChanged,
    this.style = TabbedButtonStyle.light,
    this.width,
    this.height = 35,
    this.activeColor,
  }) : assert(items.length >= 2, 'CustomTabbedButton requires at least 2 items');

  @override
  Widget build(BuildContext context) {
    final isDarkStyle = style == TabbedButtonStyle.dark;

    // Calculate colors based on style
    final backgroundColor = isDarkStyle
        ? Colors.grey[800]!.withValues(alpha: 0.9)
        : Theme.of(context).disabledColor.withValues(alpha: 0.1);

    final indicatorColor = activeColor ??
        (isDarkStyle
            ? const Color(0xFF00BCD4) // Cyan accent for dark style
            : Theme.of(context).cardColor);

    final selectedTextColor = isDarkStyle
        ? Colors.white
        : Theme.of(context).textTheme.bodyLarge!.color;

    final unselectedTextColor = isDarkStyle
        ? Colors.white60
        : Theme.of(context).hintColor;

    final indicatorShadow = isDarkStyle
        ? [
            BoxShadow(
              color: indicatorColor.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ]
        : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ];

    final containerShadow = isDarkStyle
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ]
        : <BoxShadow>[];

    // Calculate indicator width based on number of items
    final indicatorWidth = width != null
        ? (width! - (isDarkStyle ? 6 : 0)) / items.length
        : null;

    return Container(
      height: height,
      width: width,
      padding: isDarkStyle ? const EdgeInsets.all(3) : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(isDarkStyle ? 100 : Dimensions.radiusLarge),
        boxShadow: containerShadow,
      ),
      child: Stack(
        children: [
          // Sliding indicator
          AnimatedAlign(
            alignment: _getIndicatorAlignment(),
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            child: Container(
              width: indicatorWidth,
              height: isDarkStyle ? height - 6 : height,
              decoration: BoxDecoration(
                color: indicatorColor,
                borderRadius: BorderRadius.circular(isDarkStyle ? 100 : Dimensions.radiusLarge),
                boxShadow: indicatorShadow,
              ),
            ),
          ),
          // Tab Labels
          Row(
            children: List.generate(
              items.length,
              (index) => _buildTab(
                context: context,
                item: items[index],
                isSelected: selectedIndex == index,
                onTap: () => onTabChanged(index),
                selectedColor: selectedTextColor,
                unselectedColor: unselectedTextColor,
                showIcon: isDarkStyle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Alignment _getIndicatorAlignment() {
    if (items.length == 2) {
      return selectedIndex == 0 ? Alignment.centerLeft : Alignment.centerRight;
    }

    // For more than 2 items, calculate alignment
    final step = 2.0 / (items.length - 1);
    final x = -1.0 + (step * selectedIndex);
    return Alignment(x, 0);
  }

  Widget _buildTab({
    required BuildContext context,
    required TabbedButtonItem item,
    required bool isSelected,
    required VoidCallback onTap,
    required Color? selectedColor,
    required Color? unselectedColor,
    required bool showIcon,
  }) {
    final tabContent = showIcon && item.icon != null
        ? Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                item.icon,
                size: 14,
                color: isSelected ? selectedColor : unselectedColor,
              ),
              const SizedBox(width: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                style: robotoMedium.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: isSelected ? selectedColor : unselectedColor,
                ),
                child: Text(item.label),
              ),
            ],
          )
        : AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            style: robotoBold.copyWith(
              fontSize: Dimensions.fontSizeSmall,
              color: isSelected ? selectedColor : unselectedColor,
            ),
            child: Text(item.label),
          );

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              alignment: Alignment.center,
              child: tabContent,
            ),
            if (item.showBadge && !isSelected)
              const Positioned(
                top: -2,
                right: 4,
                child: _PulsingBadge(),
              ),
          ],
        ),
      ),
    );
  }
}

/// A pulsing red badge indicator widget
class _PulsingBadge extends StatefulWidget {
  const _PulsingBadge();

  @override
  State<_PulsingBadge> createState() => _PulsingBadgeState();
}

class _PulsingBadgeState extends State<_PulsingBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: _animation.value),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.red.withValues(alpha: _animation.value * 0.5),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        );
      },
    );
  }
}
