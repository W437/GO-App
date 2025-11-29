import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/common/widgets/shared/text/animated_text_transition.dart';
import 'package:godelivery_user/features/cart/controllers/cart_controller.dart';
import 'package:godelivery_user/features/cart/domain/models/cart_model.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';

/// Expandable Quantity Badge
/// Collapsed: Shows quantity circle (e.g. "3x")
/// Expanded: Shows [Delete] [- qty +] with product title on right
class ExpandableQuantityBadge extends StatefulWidget {
  final CartModel cart;
  final int cartIndex;
  final ValueChanged<bool>? onExpandedChanged;

  const ExpandableQuantityBadge({
    super.key,
    required this.cart,
    required this.cartIndex,
    this.onExpandedChanged,
  });

  @override
  State<ExpandableQuantityBadge> createState() => ExpandableQuantityBadgeState();
}

class ExpandableQuantityBadgeState extends State<ExpandableQuantityBadge>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  Timer? _autoCollapseTimer;

  static const double _badgeSize = 36;
  static const double _buttonSize = 32;

  bool get isExpanded => _isExpanded;

  @override
  void didUpdateWidget(ExpandableQuantityBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset expanded state if cart item changed
    if (oldWidget.cart.product?.id != widget.cart.product?.id ||
        oldWidget.cartIndex != widget.cartIndex) {
      _autoCollapseTimer?.cancel();
      _isExpanded = false;
    }
  }

  @override
  void dispose() {
    _autoCollapseTimer?.cancel();
    super.dispose();
  }

  void toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _startAutoCollapseTimer();
      } else {
        _autoCollapseTimer?.cancel();
      }
    });
    widget.onExpandedChanged?.call(_isExpanded);
  }

  void collapse() {
    if (_isExpanded) {
      setState(() {
        _isExpanded = false;
        _autoCollapseTimer?.cancel();
      });
      widget.onExpandedChanged?.call(false);
    }
  }

  void _startAutoCollapseTimer() {
    _autoCollapseTimer?.cancel();
    _autoCollapseTimer = Timer(const Duration(milliseconds: 3000), () {
      if (_isExpanded && mounted) {
        collapse();
      }
    });
  }

  void _resetAutoCollapseTimer() {
    if (_isExpanded) {
      _startAutoCollapseTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CartController>(
      builder: (cartController) {
        final quantity = widget.cart.quantity ?? 1;
        final theme = Theme.of(context);

        return AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          alignment: Alignment.centerLeft,
          child: _isExpanded
              ? _buildExpandedControls(context, cartController, quantity, theme)
              : _buildCollapsedBadge(context, quantity, theme),
        );
      },
    );
  }

  Widget _buildCollapsedBadge(BuildContext context, int quantity, ThemeData theme) {
    return GestureDetector(
      onTap: toggle,
      child: Container(
        width: _badgeSize,
        height: _badgeSize,
        decoration: BoxDecoration(
          color: theme.disabledColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(_badgeSize / 2),
        ),
        child: Center(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$quantity',
                  style: robotoBold.copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                    color: theme.primaryColor,
                  ),
                ),
                TextSpan(
                  text: 'x',
                  style: robotoBold.copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                    color: theme.hintColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedControls(
    BuildContext context,
    CartController cartController,
    int quantity,
    ThemeData theme,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Delete button
        GestureDetector(
          onTap: () {
            cartController.removeFromCart(widget.cartIndex);
          },
          child: Container(
            width: _buttonSize,
            height: _buttonSize,
            decoration: BoxDecoration(
              color: theme.colorScheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(_buttonSize / 2),
            ),
            child: Icon(
              Icons.delete_outline,
              size: 18,
              color: theme.colorScheme.error,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Quantity controls: [- qty +]
        Container(
          height: _buttonSize,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: theme.disabledColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(_buttonSize / 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Minus
              GestureDetector(
                onTap: quantity > 1
                    ? () {
                        _resetAutoCollapseTimer();
                        cartController.setQuantity(
                          false,
                          widget.cart,
                          cartIndex: widget.cartIndex,
                        );
                      }
                    : null,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.remove,
                    size: 16,
                    color: quantity > 1
                        ? theme.primaryColor
                        : theme.disabledColor,
                  ),
                ),
              ),
              // Quantity with animated text
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: AnimatedTextTransition(
                  value: quantity,
                  style: robotoBold.copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                    color: theme.primaryColor,
                  ),
                ),
              ),
              // Plus
              GestureDetector(
                onTap: () {
                  _resetAutoCollapseTimer();
                  cartController.setQuantity(
                    true,
                    widget.cart,
                    cartIndex: widget.cartIndex,
                  );
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.add,
                    size: 16,
                    color: theme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
