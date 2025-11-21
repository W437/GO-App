/// Bottom cart widget displaying cart summary and checkout button
/// Shows cart item count, total price, and navigation to cart screen

import 'package:godelivery_user/features/cart/controllers/cart_controller.dart';
import 'package:godelivery_user/features/restaurant/controllers/restaurant_controller.dart';
import 'package:godelivery_user/common/models/restaurant_model.dart';
import 'package:godelivery_user/helper/converters/price_converter.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:godelivery_user/common/widgets/shared/buttons/custom_button_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BottomCartWidget extends StatelessWidget {
  final int? restaurantId;
  final bool fromDineIn;
  const BottomCartWidget({super.key, this.restaurantId, this.fromDineIn = false});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CartController>(builder: (cartController) {
        double deliveryCharge = Get.find<RestaurantController>().restaurant?.deliveryFee ?? 0;

        return Container(
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Floating button
                InkWell(
                  onTap: () async {
                    await Get.toNamed(RouteHelper.getCartRoute(fromDineIn: fromDineIn));
                    Get.find<RestaurantController>().makeEmptyRestaurant();
                    if(restaurantId != null) {
                      Get.find<RestaurantController>().getRestaurantDetails(Restaurant(id: restaurantId));
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeDefault,
                      vertical: Dimensions.paddingSizeDefault,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
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
                    child: Row(
                      children: [
                        // Item count badge
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${cartController.cartList.length}',
                            style: robotoBold.copyWith(
                              fontSize: Dimensions.fontSizeDefault,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: Dimensions.paddingSizeDefault),

                        // "Show items" text
                        Expanded(
                          child: Text(
                            'show_items'.tr,
                            style: robotoBold.copyWith(
                              fontSize: Dimensions.fontSizeLarge,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        // Total price
                        Text(
                          PriceConverter.convertPrice(cartController.calculationCart()),
                          style: robotoBold.copyWith(
                            fontSize: Dimensions.fontSizeLarge,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Delivery fee text
                if (deliveryCharge > 0) ...[
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                  Text(
                    '${'estimated_service_delivery_fees'.tr} ${PriceConverter.convertPrice(deliveryCharge)}',
                    style: robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeDefault,
                      color: Theme.of(context).hintColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        );
      });
  }
}
