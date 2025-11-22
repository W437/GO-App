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
  const BottomCartWidget({super.key, this.restaurantId, this.fromDineIn = false});

  @override
  State<BottomCartWidget> createState() => _BottomCartWidgetState();
}

class _BottomCartWidgetState extends State<BottomCartWidget> with TickerProviderStateMixin {
  late AnimationController _iconBounceController;
  late AnimationController _priceBounceController;
  late Animation<double> _iconBounceAnimation;
  late Animation<double> _priceBounceAnimation;
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

    // Initialize previous cart count
    final cartController = Get.find<CartController>();
    _previousCartCount = cartController.cartList.length;
  }

  @override
  void dispose() {
    _iconBounceController.dispose();
    _priceBounceController.dispose();
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

          // Price bounces at 1500ms
          Timer(const Duration(milliseconds: 1500), () {
            if (mounted) {
              _priceBounceController.forward(from: 0.0);
            }
          });

          // Icon bounces at 1750ms (250ms later)
          _updateBounceTimer = Timer(const Duration(milliseconds: 1750), () {
            if (mounted) {
              _iconBounceController.forward(from: 0.0);
            }
          });
        }

        _previousCartCount = currentCartCount;

        return Stack(
          children: [
            // Fade overlay gradient
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 150,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.5, 1.0],
                    colors: [
                      Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0),
                      Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.7),
                      Theme.of(context).scaffoldBackgroundColor,
                    ],
                  ),
                ),
              ),
            ),

            // Cart widget content
            Container(
              padding: const EdgeInsets.only(
                left: Dimensions.paddingSizeDefault,
                right: Dimensions.paddingSizeDefault,
                top: Dimensions.paddingSizeDefault,
                bottom: Dimensions.paddingSizeExtraSmall,
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Main cart container with blur
                    ClipRRect(
                      borderRadius: BorderRadius.circular(Dimensions.radiusLarge), // Rounded rect shape
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4), // Match search bar opacity
                            borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                            boxShadow: const [
                              BoxShadow(
                                color: Color.fromRGBO(0, 0, 0, 0.1),
                                blurRadius: 6,
                                spreadRadius: -1,
                                offset: Offset(0, 4),
                              ),
                              BoxShadow(
                                color: Color.fromRGBO(0, 0, 0, 0.06),
                                blurRadius: 4,
                                spreadRadius: -1,
                                offset: Offset(0, 2),
                              )
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Top section: Cart info and button
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: Dimensions.paddingSizeLarge,
                                  vertical: 12,
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
                                      child: Icon(
                                        Icons.shopping_bag,
                                        color: Colors.white,
                                        size: 26,
                                      ),
                                    ),

                                    // Item count badge - no bounce (only text transition), overlaps icon
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
                                        delay: const Duration(milliseconds: 1500),
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
                                        delay: const Duration(milliseconds: 1500),
                                        style: robotoBold.copyWith(
                                          fontSize: Dimensions.fontSizeLarge,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),

                                    const Spacer(),

                                    // View Cart button
                                    InkWell(
                                      onTap: () {
                                        RouteHelper.showCartModal(context);
                                      },
                                      borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: Dimensions.paddingSizeDefault,
                                          vertical: Dimensions.paddingSizeExtraSmall,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).primaryColor,
                                          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
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

                              // Separator and delivery fee
                              if (deliveryCharge > 0) ...[
                                Container(
                                  height: 1,
                                  margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: Dimensions.paddingSizeLarge,
                                    vertical: Dimensions.paddingSizeSmall,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '${'estimated_service_delivery_fees'.tr} ${PriceConverter.convertPrice(deliveryCharge)}',
                                        style: robotoRegular.copyWith(
                                          fontSize: Dimensions.fontSizeSmall,
                                          color: Colors.white.withValues(alpha: 0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
    });
  }
}
