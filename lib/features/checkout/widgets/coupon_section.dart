import 'package:godelivery_user/features/checkout/controllers/checkout_controller.dart';
import 'package:godelivery_user/features/checkout/widgets/checkout_section_card.dart';
import 'package:godelivery_user/common/widgets/shared/buttons/custom_button_widget.dart';
import 'package:godelivery_user/features/checkout/widgets/coupon_bottom_sheet.dart';
import 'package:godelivery_user/features/coupon/controllers/coupon_controller.dart';
import 'package:godelivery_user/helper/ui/responsive_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/images.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
class CouponSection extends StatelessWidget {
  final CheckoutController checkoutController;
  final double price;
  final double discount;
  final double addOns;
  final double deliveryCharge;
  final double charge;
  final double total;
  const CouponSection({super.key, required this.checkoutController, required this.price, required this.discount, required this.addOns, required this.deliveryCharge, required this.total, required this.charge});

  @override
  Widget build(BuildContext context) {
    bool isDesktop = ResponsiveHelper.isDesktop(context);
    return GetBuilder<CouponController>(
      builder: (couponController) {
        return CheckoutSectionCard(
          title: 'coupon'.tr,
          margin: EdgeInsets.symmetric(horizontal: isDesktop ? Dimensions.paddingSizeLarge : Dimensions.paddingSizeDefault),
          child: (couponController.discount! <= 0 && !couponController.freeDelivery) ? Row(children: [
            Expanded(
              child: Row(children: [
                Image.asset(Images.couponIcon1, height: 20, width: 20),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                Text('add_coupon'.tr, style: robotoRegular),
              ]),
            ),

            CustomButtonWidget(
              expand: false,
              height: 42,
              radius: Dimensions.radiusLarge,
              color: Theme.of(context).primaryColor,
              icon: Icons.add,
              iconSize: 18,
              buttonText: 'add'.tr,
              fontSize: Dimensions.fontSizeSmall,
              onPressed: () {
                if(ResponsiveHelper.isDesktop(context)){
                  Get.dialog(Dialog(child: CouponBottomSheet(checkoutController: checkoutController, price: price, discount: discount, addOns: addOns, deliveryCharge: deliveryCharge, charge: charge, total: total))).then((value) {
                    if(value != null) {
                      checkoutController.couponController.text = value.toString();
                    }
                  });
                }else{
                  Get.bottomSheet(
                    CouponBottomSheet(checkoutController: checkoutController, price: price, discount: discount, addOns: addOns, deliveryCharge: deliveryCharge, charge: charge, total: total),
                    backgroundColor: Colors.transparent, isScrollControlled: true,
                  );
                }
              },
            ),
          ]) : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.check_circle_rounded, size: 16, color: Colors.green),
              const SizedBox(width: Dimensions.paddingSizeSmall),

              Text('${'coupon_applied'.tr}!', style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall)),
            ]),
            const SizedBox(height: Dimensions.paddingSizeSmall),

            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                border: Border.all(color: Theme.of(context).disabledColor, width: 0.6),
                color: Colors.white,
              ),
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeExtraSmall),
              child: Row(
                children: [
                  Expanded(
                    child: Row(children: [
                      Image.asset(Images.couponIcon1, height: 20, width: 20),
                      const SizedBox(width: Dimensions.paddingSizeSmall),
                      Text(checkoutController.couponController.text, style: robotoRegular),
                    ]),
                  ),

                  CustomButtonWidget(
                    isCircular: true,
                    expand: false,
                    height: 42,
                    width: 42,
                    color: Theme.of(context).colorScheme.error.withValues(alpha: 0.08),
                    icon: Icons.clear,
                    iconColor: Theme.of(context).colorScheme.error,
                    onPressed: () {
                      couponController.removeCouponData(true);
                      checkoutController.couponController.text = '';
                      if(checkoutController.isPartialPay || checkoutController.paymentMethodIndex == 1){
                        checkoutController.checkBalanceStatus((total + charge));
                      }
                    },
                  )
                ],
              ),
            )
          ]),
        );
      },
    );
  }
}
