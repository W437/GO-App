import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
    // Reset timer when user interacts with +/- buttons
    if (_isExpanded) {
      _startAutoCollapseTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CartController>(
      builder: (cartController) {
        int quantity = widget.cart.quantity ?? 1;

        return GestureDetector(
          onTap: _isExpanded ? null : _toggle,
          child: AnimatedSize(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOut,
              height: 44,
              width: _isExpanded ? null : 44,
              constraints: _isExpanded
                  ? const BoxConstraints(minWidth: 120)
                  : null,
              decoration: BoxDecoration(
                color: _isExpanded
                    ? Theme.of(context).primaryColor.withValues(alpha: 0.15)
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(_isExpanded ? 22 : Dimensions.radiusSmall),
                border: _isExpanded
                    ? null
                    : Border.all(
                        color: Theme.of(context).disabledColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
                child: _isExpanded
                    ? Padding(
                        key: const ValueKey('expanded'),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Minus button
                            _buildCircleButton(
                              icon: Icons.remove,
                              onPressed: quantity > 1
                                  ? () {
                                      _onQuantityChanged();
                                      cartController.setQuantity(
                                        false,
                                        widget.cart,
                                        cartIndex: widget.cartIndex,
                                      );
                                    }
                                  : null,
                            ),
                            const SizedBox(width: 8),

                            // Quantity
                            Text(
                              '$quantity',
                              style: robotoBold.copyWith(
                                fontSize: Dimensions.fontSizeDefault,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Plus button
                            _buildCircleButton(
                              icon: Icons.add,
                              onPressed: () {
                                _onQuantityChanged();
                                cartController.setQuantity(
                                  true,
                                  widget.cart,
                                  cartIndex: widget.cartIndex,
                                );
                              },
                            ),
                          ],
                        ),
                      )
                    : Center(
                        key: const ValueKey('collapsed'),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            '$quantity',
                            style: robotoBold.copyWith(
                              fontSize: Dimensions.fontSizeDefault,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 14,
          color: Colors.blue,
        ),
      ),
    );
  }
}
