import 'package:godelivery_user/common/widgets/custom_button_widget.dart';
import 'package:godelivery_user/common/widgets/custom_snackbar_widget.dart';
import 'package:godelivery_user/features/cart/controllers/cart_controller.dart';
import 'package:godelivery_user/features/checkout/controllers/checkout_controller.dart';
import 'package:godelivery_user/features/coupon/controllers/coupon_controller.dart';
import 'package:godelivery_user/features/restaurant/controllers/restaurant_controller.dart';
import 'package:godelivery_user/features/splash/controllers/splash_controller.dart';
import 'package:godelivery_user/helper/converters/price_converter.dart';
import 'package:godelivery_user/helper/ui/responsive_helper.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/images.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CheckoutButtonWidget extends StatelessWidget {
  final CartController cartController;
  final List<bool> availableList;
  final bool isRestaurantOpen;
  final bool fromDineIn;
  const CheckoutButtonWidget({super.key, required this.cartController, required this.availableList, required this.isRestaurantOpen, this.fromDineIn = false});

  @override
  Widget build(BuildContext context) {
    double percentage = 0;
    bool isDesktop = ResponsiveHelper.isDesktop(context);

    return Container(
      width: Dimensions.webMaxWidth,
      padding:  const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall, horizontal: Dimensions.paddingSizeDefault),
      decoration: isDesktop ? null : BoxDecoration(
        color: Theme.of(context).cardColor,
      ),
      child: SafeArea(
        child: GetBuilder<RestaurantController>(builder: (restaurantController) {
          if(restaurantController.restaurant != null && restaurantController.restaurant!.freeDelivery != null && !restaurantController.restaurant!.freeDelivery!
           && (Get.find<SplashController>().configModel?.adminFreeDelivery?.status == true && (Get.find<SplashController>().configModel?.adminFreeDelivery?.type != null && Get.find<SplashController>().configModel?.adminFreeDelivery?.type == 'free_delivery_by_specific_criteria') && (Get.find<SplashController>().configModel!.adminFreeDelivery?.freeDeliveryOver != null))){
            percentage = cartController.subTotal/Get.find<SplashController>().configModel!.adminFreeDelivery!.freeDeliveryOver!;
          }
          return Column(mainAxisSize: MainAxisSize.min, children: [
            (restaurantController.restaurant != null && restaurantController.restaurant!.freeDelivery != null && !restaurantController.restaurant!.freeDelivery!
             && (Get.find<SplashController>().configModel?.adminFreeDelivery?.status == true && (Get.find<SplashController>().configModel?.adminFreeDelivery?.type != null && Get.find<SplashController>().configModel?.adminFreeDelivery?.type == 'free_delivery_by_specific_criteria') && (Get.find<SplashController>().configModel!.adminFreeDelivery?.freeDeliveryOver != null)) && percentage < 1)
            ? Padding(
              padding: EdgeInsets.only(bottom: isDesktop ? Dimensions.paddingSizeLarge : 0),
              child: Column(children: [
                Row(children: [
                  Image.asset(Images.percentTag, height: 20, width: 20),
                  const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                  PriceConverter.convertAnimationPrice(
                    Get.find<SplashController>().configModel!.adminFreeDelivery!.freeDeliveryOver! - cartController.subTotal,
                    textStyle: robotoMedium.copyWith(color: Theme.of(context).primaryColor),
                  ),
                  const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                  Text('more_for_free_delivery'.tr, style: robotoMedium.copyWith(color: Theme.of(context).disabledColor)),
                ]),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                LinearProgressIndicator(
                  backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                  value: percentage,
                ),
              ]),
            ) : const SizedBox(),


            !isDesktop ? Padding(
              padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('subtotal'.tr, style: robotoMedium.copyWith(color: Theme.of(context).primaryColor)),
                  PriceConverter.convertAnimationPrice(cartController.subTotal, textStyle: robotoRegular.copyWith(color: Theme.of(context).primaryColor)),
                ],
              ),
            ) : const SizedBox(),

            GetBuilder<CartController>(
              builder: (cartController) {
                return CustomButtonWidget(
                  radius: 10,
                  buttonText: 'confirm_delivery_details'.tr,
                  onPressed: cartController.isLoading || restaurantController.restaurant == null ? null : () {
                    Get.find<CheckoutController>().updateFirstTime();
                    _processToCheckoutButtonPressed(restaurantController);
                  },
                );
              }
            ),
            SizedBox(height: isDesktop ? Dimensions.paddingSizeExtraLarge : 0),
          ]);
        }),
      ),
    );
  }

  void _processToCheckoutButtonPressed(RestaurantController restaurantController) {
    if(!cartController.cartList.first.product!.scheduleOrder! && cartController.availableList.contains(false)) {
      showCustomSnackBar('one_or_more_product_unavailable'.tr);
    } else if(restaurantController.restaurant!.freeDelivery == null || restaurantController.restaurant!.cutlery == null) {
      showCustomSnackBar('restaurant_is_unavailable'.tr);
    }/* else if(!isRestaurantOpen) {
      showCustomSnackBar('restaurant_is_close_now'.tr);
    } */else {
      Get.find<CouponController>().removeCouponData(false);
      Get.toNamed(RouteHelper.getCheckoutRoute('cart', fromDineIn: fromDineIn));
    }
  }

}