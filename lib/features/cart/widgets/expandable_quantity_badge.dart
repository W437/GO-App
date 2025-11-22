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

  static const double _badgeHeight = 44;
  static const double _buttonSize = 26;
  static const double _borderRadiusCollapsed = 16;
  static const double _borderRadiusExpanded = 22;

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
          child: AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: Alignment.center,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              height: _badgeHeight,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(
                  _isExpanded
                      ? _borderRadiusExpanded
                      : _borderRadiusCollapsed,
                ),
                border: Border.all(
                  color: theme.disabledColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: ClipRect(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Minus button (slides in from left)
                    _AnimatedSideButton(
                      isVisible: _isExpanded,
                      child: _buildCircleButton(
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
                    ),

                    // Spacing left of quantity
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      child: SizedBox(width: _isExpanded ? 8 : 0),
                    ),

                    // Quantity (stays centered visually)
                    AnimatedTextTransition(
                      value: quantity,
                      style: robotoBold.copyWith(
                        fontSize: Dimensions.fontSizeDefault,
                        color: theme.primaryColor,
                      ),
                    ),

                    // Spacing right of quantity
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      child: SizedBox(width: _isExpanded ? 8 : 0),
                    ),

                    // Plus button (slides in from right)
                    _AnimatedSideButton(
                      isVisible: _isExpanded,
                      child: _buildCircleButton(
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
    required bool enabled,
    required VoidCallback? onTap,
    required Color color,
  }) {
    final Color baseColor = enabled ? color : color.withValues(alpha: 0.4);

    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: _buttonSize,
        height: _buttonSize,
        decoration: BoxDecoration(
          color: baseColor.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 14,
          color: baseColor,
        ),
      ),
    );
  }
}

/// Animates side buttons width + opacity so they "reveal" smoothly.
class _AnimatedSideButton extends StatelessWidget {
  final bool isVisible;
  final Widget child;

  const _AnimatedSideButton({
    required this.isVisible,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: isVisible ? _ExpandableQuantityBadgeState._buttonSize : 0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: isVisible ? 1 : 0,
        child: IgnorePointer(
          ignoring: !isVisible,
          child: child,
        ),
      ),
    );
  }
}
