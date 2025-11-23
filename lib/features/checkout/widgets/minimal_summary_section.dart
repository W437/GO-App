import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/features/checkout/controllers/checkout_controller.dart';
import 'package:godelivery_user/features/coupon/controllers/coupon_controller.dart';
import 'package:godelivery_user/features/splash/controllers/splash_controller.dart';
import 'package:godelivery_user/helper/converters/price_converter.dart';
import 'package:godelivery_user/util/styles.dart';

class MinimalSummarySection extends StatelessWidget {
  final CheckoutController checkoutController;
  final double orderAmount;
  final double charge;
  final int subscriptionQty;

  const MinimalSummarySection({
    super.key,
    required this.checkoutController,
    required this.orderAmount,
    required this.charge,
    required this.subscriptionQty,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CheckoutController>(
      builder: (controller) {
        return GetBuilder<CouponController>(
          builder: (couponController) {
            final showTips = controller.orderType != 'take_away' &&
                             controller.orderType != 'dine_in';
            final deliveryCharge = _getDeliveryCharge(controller);
            final additionalCharge = Get.find<SplashController>()
                    .configModel
                    ?.additionalChargeStatus ==
                true
                ? (Get.find<SplashController>().configModel?.additionCharge ?? 0).toDouble()
                : 0.0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with "How fees work" link
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'summary'.tr,
                      style: robotoBold.copyWith(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // Show fees breakdown dialog or sheet
                      },
                      child: Text(
                        'how_fees_work'.tr,
                        style: robotoRegular.copyWith(
                          fontSize: 13,
                          color: const Color(0xFF00A8FF),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Line items
                _buildSummaryRow('subtotal'.tr, orderAmount),

                if (couponController.discount! > 0)
                  _buildSummaryRow(
                    'discount'.tr,
                    -couponController.discount!,
                    isDiscount: true,
                  ),

                if (controller.orderType == 'delivery')
                  _buildSummaryRow(
                    'delivery_fee'.tr,
                    deliveryCharge,
                    subtitle: controller.distance != null
                        ? '${controller.distance!.toStringAsFixed(1)} km'
                        : null,
                  ),

                if (additionalCharge > 0)
                  _buildSummaryRow(
                    'service_fee'.tr,
                    additionalCharge,
                  ),

                if (showTips && controller.tips > 0)
                  _buildSummaryRow(
                    'courier_tip'.tr,
                    controller.tips,
                  ),

                if (controller.orderTax != null && controller.orderTax! > 0)
                  _buildSummaryRow(
                    controller.taxIncluded == 1 ? 'vat_tax_inc'.tr : 'tax'.tr,
                    controller.orderTax!,
                  ),

                const SizedBox(height: 12),
                Container(
                  height: 1,
                  color: Colors.white.withOpacity(0.1),
                ),
                const SizedBox(height: 12),

                // Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'total'.tr,
                      style: robotoBold.copyWith(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      PriceConverter.convertPrice(
                        controller.viewTotalPrice ?? 0,
                      ),
                      style: robotoBold.copyWith(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),

                if (controller.taxIncluded == 1) ...[
                  const SizedBox(height: 4),
                  Text(
                    'includes_vat_tax'.tr,
                    style: robotoRegular.copyWith(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSummaryRow(
    String label,
    double amount, {
    String? subtitle,
    bool isDiscount = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: robotoRegular.copyWith(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: robotoRegular.copyWith(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            isDiscount
                ? '-${PriceConverter.convertPrice(amount.abs())}'
                : PriceConverter.convertPrice(amount),
            style: robotoMedium.copyWith(
              fontSize: 14,
              color: isDiscount
                  ? const Color(0xFF4CAF50)
                  : Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  double _getDeliveryCharge(CheckoutController controller) {
    if (controller.orderType == 'take_away' ||
        controller.orderType == 'dine_in' ||
        controller.restaurant?.freeDelivery == true) {
      return 0;
    }
    // This will be calculated from the parent widget's logic
    return charge;
  }
}
