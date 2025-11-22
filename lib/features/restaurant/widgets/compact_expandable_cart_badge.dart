import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/common/widgets/shared/text/animated_text_transition.dart';
import 'package:godelivery_user/features/cart/controllers/cart_controller.dart';
import 'package:godelivery_user/features/cart/domain/models/cart_model.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';

/// Compact Expandable Cart Badge for Product Cards
/// Shows quantity in a compact badge that expands to show +/- controls
class CompactExpandableCartBadge extends StatefulWidget {
  final int productId;

  const CompactExpandableCartBadge({
    super.key,
    required this.productId,
  });

  @override
  State<CompactExpandableCartBadge> createState() => _CompactExpandableCartBadgeState();
}

class _CompactExpandableCartBadgeState extends State<CompactExpandableCartBadge> {
  bool _isExpanded = false;
  Timer? _autoCollapseTimer;

  static const double _badgeHeight = 36;
  static const double _buttonSize = 26;
  static const double _cornerRadius = Dimensions.radiusDefault;

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
    _autoCollapseTimer = Timer(const Duration(milliseconds: 2000), () {
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
        // Find all cart items for this product and sum quantities
        final cartItems = cartController.cartList.where((item) => item.product?.id == widget.productId).toList();

        if (cartItems.isEmpty) return const SizedBox();

        final int totalQuantity = cartItems.fold(0, (sum, item) => sum + (item.quantity ?? 0));

        if (totalQuantity == 0) return const SizedBox();

        final theme = Theme.of(context);

        return GestureDetector(
          onTap: _isExpanded ? null : _toggle,
          onTapDown: (_) {}, // Absorb tap down
          onTapUp: (_) {}, // Absorb tap up
          onTapCancel: () {}, // Absorb tap cancel
          onLongPress: () {}, // Absorb long press
          onLongPressStart: (_) {}, // Absorb long press start
          onLongPressEnd: (_) {}, // Absorb long press end
          behavior: HitTestBehavior.opaque, // Prevent all gestures from passing through
          child: AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            alignment: Alignment.centerRight,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              scale: _isExpanded ? 1.2 : 1.0,
              alignment: Alignment.centerRight,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                height: _badgeHeight,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _isExpanded
                      ? theme.disabledColor.withOpacity(0.15)
                      : theme.primaryColor,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(_cornerRadius),
                    bottomLeft: Radius.circular(_cornerRadius),
                  ),
                ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Minus button (slides in from left)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    width: _isExpanded ? _buttonSize : 0,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 150),
                      opacity: _isExpanded ? 1 : 0,
                      child: IgnorePointer(
                        ignoring: !_isExpanded,
                        child: _buildCircleButton(
                          icon: Icons.remove,
                          onTap: () {
                            _onQuantityChanged();
                            // Get the first cart item to decrement or remove
                            if (cartItems.isNotEmpty) {
                              final firstItem = cartItems.first;
                              final index = cartController.cartList.indexOf(firstItem);

                              // If quantity is 1, remove from cart completely
                              if ((firstItem.quantity ?? 0) <= 1) {
                                cartController.removeFromCart(index);
                              } else {
                                // Otherwise just decrement
                                cartController.setQuantity(false, firstItem, cartIndex: index);
                              }
                            }
                          },
                          color: theme.primaryColor,
                          iconColor: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  // Spacing
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    child: SizedBox(width: _isExpanded ? 6 : 0),
                  ),

                  // Quantity
                  AnimatedTextTransition(
                    value: totalQuantity,
                    style: robotoBold.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: _isExpanded
                          ? theme.textTheme.bodyLarge?.color
                          : Colors.white,
                    ),
                  ),

                  // Spacing
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    child: SizedBox(width: _isExpanded ? 6 : 0),
                  ),

                  // Plus button (slides in from right)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    width: _isExpanded ? _buttonSize : 0,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 150),
                      opacity: _isExpanded ? 1 : 0,
                      child: IgnorePointer(
                        ignoring: !_isExpanded,
                        child: _buildCircleButton(
                          icon: Icons.add,
                          onTap: () {
                            _onQuantityChanged();
                            // Get the first cart item to increment
                            if (cartItems.isNotEmpty) {
                              final firstItem = cartItems.first;
                              final index = cartController.cartList.indexOf(firstItem);
                              cartController.setQuantity(true, firstItem, cartIndex: index);
                            }
                          },
                          color: theme.primaryColor,
                          iconColor: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
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
    required VoidCallback onTap,
    required Color color,
    required Color iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: _buttonSize,
        height: _buttonSize,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 14,
          color: iconColor,
        ),
      ),
    );
  }
}
