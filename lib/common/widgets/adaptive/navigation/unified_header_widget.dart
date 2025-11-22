/// Unified header widget with consistent styling across app screens
/// Provides standardized app bar with back button, title, and actions

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:godelivery_user/common/widgets/adaptive/cart/cart_widget.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:godelivery_user/features/cart/screens/shopping_cart_sheet.dart';

class UnifiedHeaderWidget extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final bool showCart;
  final List<Widget>? actions;
  final bool centerTitle;
  final double? elevation;
  final Color? backgroundColor;
  final Color? titleColor;
  final bool showBorder;

  const UnifiedHeaderWidget({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.onBackPressed,
    this.showCart = false,
    this.actions,
    this.centerTitle = true,
    this.elevation,
    this.backgroundColor,
    this.titleColor,
    this.showBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).cardColor,
        border: showBorder
            ? Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                  width: 0.5,
                ),
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            offset: const Offset(0, 1),
            blurRadius: 3,
          ),
        ],
      ),
      child: AppBar(
        backgroundColor: backgroundColor ?? Theme.of(context).cardColor,
        surfaceTintColor: backgroundColor ?? Theme.of(context).cardColor,
        elevation: elevation ?? 0,
        centerTitle: centerTitle,
        automaticallyImplyLeading: false,
        leadingWidth: showBackButton ? 60 : null,
        leading: showBackButton
            ? Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Center(
                  child: _FlatBackButton(
                    onPressed: onBackPressed ?? () => Navigator.maybePop(context),
                    iconColor: titleColor ?? Theme.of(context).textTheme.bodyLarge!.color!,
                  ),
                ),
              )
            : null,
        title: Text(
          title,
          style: robotoBold.copyWith(
            fontSize: Dimensions.fontSizeLarge,
            color: titleColor ?? Theme.of(context).textTheme.bodyLarge!.color,
          ),
        ),
        actions: [
          if (showCart)
            IconButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  useSafeArea: true,
                  builder: (context) => Container(
                    height: MediaQuery.of(context).size.height,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: const ShoppingCartSheet(fromNav: false),
                  ),
                );
              },
              icon: CartWidget(
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
              padding: const EdgeInsets.all(12),
              constraints: const BoxConstraints(),
              splashRadius: 24,
            ),
          if (actions != null) ...actions!,
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}

/// Flat back button with color change on press (no ripple)
class _FlatBackButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Color iconColor;

  const _FlatBackButton({
    required this.onPressed,
    required this.iconColor,
  });

  @override
  State<_FlatBackButton> createState() => _FlatBackButtonState();
}

class _FlatBackButtonState extends State<_FlatBackButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _isPressed
              ? Theme.of(context).disabledColor.withValues(alpha: 0.15)
              : Theme.of(context).disabledColor.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 18,
          color: widget.iconColor,
        ),
      ),
    );
  }
}

/// Simplified back button for inline use
class SimpleBackButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Color? iconColor;
  final Color? backgroundColor;
  final double size;

  const SimpleBackButton({
    super.key,
    this.onPressed,
    this.iconColor,
    this.backgroundColor,
    this.size = 40,
  });

  @override
  State<SimpleBackButton> createState() => _SimpleBackButtonState();
}

class _SimpleBackButtonState extends State<SimpleBackButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.backgroundColor ?? Theme.of(context).disabledColor.withValues(alpha: 0.08);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        if (widget.onPressed != null) {
          widget.onPressed!();
        } else {
          Navigator.maybePop(context);
        }
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: _isPressed
              ? Theme.of(context).disabledColor.withValues(alpha: 0.15)
              : baseColor,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: widget.size * 0.45,
          color: widget.iconColor ?? Theme.of(context).textTheme.bodyLarge!.color,
        ),
      ),
    );
  }
}