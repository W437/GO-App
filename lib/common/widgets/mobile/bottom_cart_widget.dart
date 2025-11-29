import 'dart:ui';
import 'dart:async';
import 'package:godelivery_user/features/cart/controllers/cart_controller.dart';
import 'package:godelivery_user/features/restaurant/controllers/restaurant_controller.dart';
import 'package:godelivery_user/helper/converters/price_converter.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:godelivery_user/common/widgets/shared/text/animated_text_transition.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Bottom cart widget displaying cart summary and checkout button
/// Shows cart item count, total price, and navigation to cart screen

class BottomCartWidget extends StatefulWidget {
  final int? restaurantId;
  final bool fromDineIn;
  final VoidCallback? onTap;
  const BottomCartWidget({super.key, this.restaurantId, this.fromDineIn = false, this.onTap});

  @override
  State<BottomCartWidget> createState() => _BottomCartWidgetState();
}

class _BottomCartWidgetState extends State<BottomCartWidget> with TickerProviderStateMixin {
  late AnimationController _iconBounceController;
  late AnimationController _priceBounceController;
  late Animation<double> _iconBounceAnimation;
  late Animation<double> _priceBounceAnimation;

  // Widget-level press and bounce animations
  late AnimationController _pressController;
  late Animation<double> _pressAnimation;
  late AnimationController _widgetBounceController;
  late Animation<double> _widgetBounceAnimation;

  Timer? _updateBounceTimer;
  int _previousCartCount = 0;

  @override
  void initState() {
    super.initState();

    // Initialize icon bounce animation
    _iconBounceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _iconBounceAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.08)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.08, end: 0.98)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.98, end: 1.02)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.02, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 25,
      ),
    ]).animate(_iconBounceController);

    // Initialize price bounce animation (same as icon)
    _priceBounceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _priceBounceAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.08)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.08, end: 0.98)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.98, end: 1.02)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.02, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 25,
      ),
    ]).animate(_priceBounceController);

    // Initialize press animation for widget tap
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _pressAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(
      CurvedAnimation(
        parent: _pressController,
        curve: Curves.easeOut,
      ),
    );

    // Initialize bounce animation for widget tap
    _widgetBounceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _widgetBounceAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.05)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.05, end: 0.98)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.98, end: 1.02)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.02, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 25,
      ),
    ]).animate(_widgetBounceController);

    // Initialize previous cart count
    final cartController = Get.find<CartController>();
    _previousCartCount = cartController.cartList.length;
  }

  @override
  void dispose() {
    _iconBounceController.dispose();
    _priceBounceController.dispose();
    _pressController.dispose();
    _widgetBounceController.dispose();
    _updateBounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CartController>(builder: (cartController) {
        double deliveryCharge = Get.find<RestaurantController>().restaurant?.deliveryFee ?? 0;
        final currentCartCount = cartController.cartList.length;

        // Detect cart updates (count changed and cart is not empty)
        if (currentCartCount > 0 && _previousCartCount > 0 && currentCartCount != _previousCartCount) {
          // Cart was updated (item added or removed)
          _updateBounceTimer?.cancel();

          // Price bounces at 500ms
          Timer(const Duration(milliseconds: 500), () {
            if (mounted) {
              _priceBounceController.forward(from: 0.0);
            }
          });

          // Icon bounces at 750ms (250ms later)
          _updateBounceTimer = Timer(const Duration(milliseconds: 750), () {
            if (mounted) {
              _iconBounceController.forward(from: 0.0);
            }
          });
        }

        _previousCartCount = currentCartCount;

        return Padding(
          padding: EdgeInsets.only(
            left: Dimensions.paddingSizeDefault,
            right: Dimensions.paddingSizeDefault,
            bottom: MediaQuery.of(context).padding.bottom + Dimensions.paddingSizeSmall,
          ),
          child: GestureDetector(
            onTapDown: (_) => _pressController.forward(),
            onTapUp: (_) {
              _pressController.reverse();
              // Only trigger bounce if not already animating
              if (!_widgetBounceController.isAnimating) {
                _widgetBounceController.forward(from: 0.0);
              }
            },
            onTapCancel: () => _pressController.reverse(),
            onTap: widget.onTap,
            child: AnimatedBuilder(
              animation: Listenable.merge([_pressAnimation, _widgetBounceAnimation]),
              builder: (context, child) {
                return Transform.scale(
                  scale: _pressAnimation.value * _widgetBounceAnimation.value,
                  child: child,
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeLarge,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.15),
                          blurRadius: 10,
                          spreadRadius: 0,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Shopping bag icon - animated
                        AnimatedBuilder(
                          animation: _iconBounceAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _iconBounceAnimation.value,
                              child: child,
                            );
                          },
                          child: const Icon(
                            Icons.shopping_bag,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),

                        // Item count badge - overlaps icon
                        Transform.translate(
                          offset: const Offset(-6, 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: AnimatedTextTransition(
                              value: cartController.cartList.length,
                              delay: const Duration(milliseconds: 500),
                              style: robotoBold.copyWith(
                                fontSize: 11,
                                color: Colors.white,
                                height: 1,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: Dimensions.paddingSizeSmall),

                        // Total price - animated with bounce
                        AnimatedBuilder(
                          animation: _priceBounceAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _priceBounceAnimation.value,
                              child: child,
                            );
                          },
                          child: AnimatedTextTransition(
                            value: PriceConverter.convertPrice(cartController.calculationCart()),
                            delay: const Duration(milliseconds: 500),
                            style: robotoBold.copyWith(
                              fontSize: Dimensions.fontSizeLarge,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        // Delivery charge inline
                        if (deliveryCharge > 0) ...[
                          const SizedBox(width: Dimensions.paddingSizeSmall),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.delivery_dining,
                                  size: 18,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  PriceConverter.convertPrice(deliveryCharge),
                                  style: robotoMedium.copyWith(
                                    fontSize: Dimensions.fontSizeSmall,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const Spacer(),

                        // View Cart button
                        InkWell(
                          onTap: () {
                            RouteHelper.showCartModal(context);
                          },
                          borderRadius: BorderRadius.circular(100),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Dimensions.paddingSizeLarge,
                              vertical: Dimensions.paddingSizeSmall,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              'show_items'.tr,
                              style: robotoBold.copyWith(
                                fontSize: Dimensions.fontSizeDefault,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
    });
  }
}
