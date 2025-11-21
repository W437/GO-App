import 'dart:ui';
import 'package:godelivery_user/features/cart/controllers/cart_controller.dart';
import 'package:godelivery_user/features/restaurant/controllers/restaurant_controller.dart';
import 'package:godelivery_user/helper/converters/price_converter.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Bottom cart widget displaying cart summary and checkout button
/// Shows cart item count, total price, and navigation to cart screen

class BottomCartWidget extends StatelessWidget {
  final int? restaurantId;
  final bool fromDineIn;
  const BottomCartWidget({super.key, this.restaurantId, this.fromDineIn = false});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CartController>(builder: (cartController) {
        double deliveryCharge = Get.find<RestaurantController>().restaurant?.deliveryFee ?? 0;

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
                                    // Shopping bag icon with badge
                                    SizedBox(
                                      width: 32,
                                      height: 32,
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          // Bag icon - centered
                                          Center(
                                            child: Icon(
                                              Icons.shopping_bag,
                                              color: Colors.white,
                                              size: 26,
                                            ),
                                          ),
                                          // Badge with count
                                          Positioned(
                                            right: -4,
                                            top: -4,
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context).primaryColor,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Text(
                                                '${cartController.cartList.length}',
                                                style: robotoBold.copyWith(
                                                  fontSize: 9,
                                                  color: Colors.white,
                                                  height: 1,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(width: Dimensions.paddingSizeDefault),

                                    // Total price
                                    Text(
                                      PriceConverter.convertPrice(cartController.calculationCart()),
                                      style: robotoBold.copyWith(
                                        fontSize: Dimensions.fontSizeLarge,
                                        color: Colors.white,
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
