import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/common/widgets/shared/buttons/custom_button_widget.dart';
import 'package:godelivery_user/common/widgets/shared/feedback/custom_toast_widget.dart';
import 'package:godelivery_user/common/widgets/shared/sheets/custom_full_sheet.dart';
import 'package:godelivery_user/common/widgets/shared/text/animated_text_transition.dart';
import 'package:godelivery_user/features/cart/controllers/cart_controller.dart';
import 'package:godelivery_user/features/cart/domain/models/cart_model.dart';
import 'package:godelivery_user/features/checkout/controllers/checkout_controller.dart';
import 'package:godelivery_user/features/checkout/screens/checkout_screen.dart';
import 'package:godelivery_user/features/coupon/controllers/coupon_controller.dart';
import 'package:godelivery_user/features/restaurant/controllers/restaurant_controller.dart';
import 'package:godelivery_user/features/splash/controllers/splash_controller.dart';
import 'package:godelivery_user/helper/converters/price_converter.dart';
import 'package:godelivery_user/helper/ui/responsive_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/images.dart';
import 'package:godelivery_user/util/styles.dart';

class CheckoutButtonWidget extends StatelessWidget {
  final CartController cartController;
  final List<bool> availableList;
  final bool isRestaurantOpen;
  final bool fromDineIn;
  final String restaurantName;
  final int restaurantId;
  final List<CartModel> cartItems;
  final double subtotal;

  const CheckoutButtonWidget({
    super.key,
    required this.cartController,
    required this.availableList,
    required this.isRestaurantOpen,
    required this.restaurantName,
    required this.restaurantId,
    required this.cartItems,
    required this.subtotal,
    this.fromDineIn = false,
  });

  @override
  Widget build(BuildContext context) {
    double percentage = 0;
    bool isDesktop = ResponsiveHelper.isDesktop(context);

    return Container(
      width: isDesktop ? Dimensions.webMaxWidth : null,
      padding:  const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall, horizontal: Dimensions.paddingSizeDefault),
      child: SafeArea(
        child: GetBuilder<RestaurantController>(builder: (restaurantController) {
          if(restaurantController.restaurant != null && restaurantController.restaurant!.freeDelivery != null && !restaurantController.restaurant!.freeDelivery!
           && (Get.find<SplashController>().configModel?.adminFreeDelivery?.status == true && (Get.find<SplashController>().configModel?.adminFreeDelivery?.type != null && Get.find<SplashController>().configModel?.adminFreeDelivery?.type == 'free_delivery_by_specific_criteria') && (Get.find<SplashController>().configModel!.adminFreeDelivery?.freeDeliveryOver != null))){
            percentage = subtotal/Get.find<SplashController>().configModel!.adminFreeDelivery!.freeDeliveryOver!;
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
                    Get.find<SplashController>().configModel!.adminFreeDelivery!.freeDeliveryOver! - subtotal,
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


            !isDesktop ? Container(
              margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'subtotal'.tr,
                    style: robotoBold.copyWith(
                      color: Theme.of(context).textTheme.bodyLarge!.color,
                      fontSize: Dimensions.fontSizeLarge,
                    ),
                  ),
                  AnimatedTextTransition(
                    value: PriceConverter.convertPrice(subtotal),
                    style: robotoBold.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontSize: Dimensions.fontSizeExtraLarge,
                    ),
                  ),
                ],
              ),
            ) : const SizedBox(),

            SizedBox(
              width: double.infinity,
              child: GetBuilder<CartController>(
                builder: (cartController) {
                  return CustomButtonWidget(
                    expand: false,
                    radius: Dimensions.radiusDefault,
                    buttonText: 'confirm_delivery_details'.tr,
                    height: 56,
                    onPressed: cartController.isLoading || restaurantController.restaurant == null ? null : () {
                      Get.find<CheckoutController>().updateFirstTime();
                      _processToCheckoutButtonPressed(context, restaurantController);
                    },
                  );
                },
              ),
            ),
            SizedBox(height: isDesktop ? Dimensions.paddingSizeExtraLarge : 0),
          ]);
        }),
      ),
    );
  }

  void _processToCheckoutButtonPressed(BuildContext context, RestaurantController restaurantController) {
    if(!cartItems.first.product!.scheduleOrder! && cartController.availableList.contains(false)) {
      showCustomSnackBar('one_or_more_product_unavailable'.tr);
    } else if(restaurantController.restaurant!.freeDelivery == null || restaurantController.restaurant!.cutlery == null) {
      showCustomSnackBar('restaurant_is_unavailable'.tr);
    }/* else if(!isRestaurantOpen) {
      showCustomSnackBar('restaurant_is_close_now'.tr);
    } */else {
      Get.find<CouponController>().removeCouponData(false);

      // Navigate within sheet using CustomFullSheetNavigator
      CustomFullSheetNavigator.push(
        context,
        CustomFullSheetPage(
          title: restaurantName,
          subtitle: 'Checkout',
          child: CheckoutScreen(
            fromCart: true,
            cartList: cartItems,
            fromDineInPage: fromDineIn,
            showAppBar: false, // No AppBar - using CustomFullSheetNavigator's top bar
          ),
        ),
      );
    }
  }

}
