import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/common/widgets/shared/text/animated_text_transition.dart';
import 'package:godelivery_user/features/cart/controllers/cart_controller.dart';
import 'package:godelivery_user/features/cart/domain/models/cart_model.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';

/// Expandable Quantity Badge
/// Collapsed: Shows just the quantity number
/// Expanded: Shows [- button] [quantity] [+ button]
/// Smoothly animates between states
class ExpandableQuantityBadge extends StatefulWidget {
  final CartModel cart;
  final int cartIndex;

  const ExpandableQuantityBadge({
    super.key,
    required this.cart,
    required this.cartIndex,
  });

  @override
  State<ExpandableQuantityBadge> createState() => _ExpandableQuantityBadgeState();
}

class _ExpandableQuantityBadgeState extends State<ExpandableQuantityBadge>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  Timer? _autoCollapseTimer;

  static const double _badgeSize = 36;

  @override
  void dispose() {
    _autoCollapseTimer?.cancel();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _startAutoCollapseTimer();
      } else {
        _autoCollapseTimer?.cancel();
      }
    });
  }

  void _startAutoCollapseTimer() {
    _autoCollapseTimer?.cancel();
    _autoCollapseTimer = Timer(const Duration(milliseconds: 1500), () {
      if (_isExpanded && mounted) {
        setState(() {
          _isExpanded = false;
        });
      }
    });
  }

  void _onQuantityChanged() {
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

        return GestureDetector(
          onTap: _isExpanded ? null : _toggle,
          child: Container(
            width: _badgeSize,
            height: _badgeSize,
            decoration: BoxDecoration(
              color: theme.disabledColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(_badgeSize / 2),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _isExpanded
                  ? Column(
                      key: const ValueKey('expanded'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Plus button (top)
                        _buildCompactButton(
                          icon: Icons.add,
                          enabled: true,
                          onTap: () {
                            _onQuantityChanged();
                            cartController.setQuantity(
                              true,
                              widget.cart,
                              cartIndex: widget.cartIndex,
                            );
                          },
                          color: theme.primaryColor,
                        ),
                        // Quantity
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1),
                          child: Text(
                            '$quantity',
                            style: robotoBold.copyWith(
                              fontSize: 10,
                              color: theme.primaryColor,
                            ),
                          ),
                        ),
                        // Minus button (bottom)
                        _buildCompactButton(
                          icon: Icons.remove,
                          enabled: quantity > 1,
                          onTap: quantity > 1
                              ? () {
                                  _onQuantityChanged();
                                  cartController.setQuantity(
                                    false,
                                    widget.cart,
                                    cartIndex: widget.cartIndex,
                                  );
                                }
                              : null,
                          color: theme.primaryColor,
                        ),
                      ],
                    )
                  : Center(
                      key: const ValueKey('collapsed'),
                      child: Text(
                        '${quantity}x',
                        style: robotoBold.copyWith(
                          fontSize: Dimensions.fontSizeDefault,
                          color: theme.primaryColor,
                        ),
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback? onTap,
    required Color color,
  }) {
    final Color baseColor = enabled ? color : color.withValues(alpha: 0.3);

    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Icon(
        icon,
        size: 12,
        color: baseColor,
      ),
    );
  }
}
