import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/features/checkout/controllers/checkout_controller.dart';
import 'package:godelivery_user/features/coupon/controllers/coupon_controller.dart';
import 'package:godelivery_user/features/checkout/widgets/coupon_bottom_sheet.dart';
import 'package:godelivery_user/helper/converters/price_converter.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:godelivery_user/features/checkout/widgets/payment_button_new.dart';

class CheckoutPaymentSection extends StatelessWidget {
  final CheckoutController checkoutController;
  final bool isCashOnDeliveryActive;
  final bool isDigitalPaymentActive;
  final bool isWalletActive;
  final bool isOfflinePaymentActive;
  final double price;
  final double discount;
  final double addOns;
  final double deliveryCharge;
  final double total;
  final double charge;

  const CheckoutPaymentSection({
    super.key,
    required this.checkoutController,
    required this.isCashOnDeliveryActive,
    required this.isDigitalPaymentActive,
    required this.isWalletActive,
    required this.isOfflinePaymentActive,
    required this.price,
    required this.discount,
    required this.addOns,
    required this.deliveryCharge,
    required this.total,
    required this.charge,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CheckoutController>(
      builder: (controller) {
        final paymentMethodName = _getPaymentMethodName(controller);
        final total = controller.viewTotalPrice ?? 0;

        return GetBuilder<CouponController>(
          builder: (couponController) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'payment'.tr,
                    style: robotoBold.copyWith(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Payment method card
                  GestureDetector(
                    onTap: () => _showPaymentMethodSheet(context, controller),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A2A2A),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _getPaymentIcon(controller),
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  paymentMethodName,
                                  style: robotoMedium.copyWith(
                                    fontSize: 15,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  PriceConverter.convertPrice(total),
                                  style: robotoRegular.copyWith(
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            size: 20,
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Redeem code row
                  GestureDetector(
                    onTap: () => _showCouponSheet(context),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.card_giftcard_outlined,
                            size: 22,
                            color: Colors.white.withOpacity(0.7),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              couponController.discount! > 0
                                  ? '${'coupon_applied'.tr}: ${couponController.coupon?.code ?? ''}'
                                  : 'redeem_code'.tr,
                              style: robotoMedium.copyWith(
                                fontSize: 15,
                                color: couponController.discount! > 0
                                    ? const Color(0xFF00A8FF)
                                    : Colors.white,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            size: 20,
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getPaymentMethodName(CheckoutController controller) {
    switch (controller.paymentMethodIndex) {
      case 0:
        return 'cash_on_delivery'.tr;
      case 1:
        return 'wallet'.tr;
      case 2:
        return controller.digitalPaymentName ?? 'digital_payment'.tr;
      case 3:
        return 'offline_payment'.tr;
      default:
        return 'select_payment_method'.tr;
    }
  }

  IconData _getPaymentIcon(CheckoutController controller) {
    switch (controller.paymentMethodIndex) {
      case 0:
        return Icons.money;
      case 1:
        return Icons.account_balance_wallet;
      case 2:
        return Icons.credit_card;
      case 3:
        return Icons.payment;
      default:
        return Icons.payment;
    }
  }

  void _showPaymentMethodSheet(BuildContext context, CheckoutController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'payment_method'.tr,
              style: robotoBold.copyWith(fontSize: 18, color: Colors.white),
            ),
            const SizedBox(height: 20),
            PaymentButtonNew(
              icon: Icons.money,
              title: 'cash_on_delivery'.tr,
              isSelected: controller.paymentMethodIndex == 0,
              onTap: () {
                controller.setPaymentMethod(0);
                Navigator.pop(ctx);
              },
            ),
            if (isWalletActive)
              PaymentButtonNew(
                icon: Icons.account_balance_wallet,
                title: 'wallet'.tr,
                isSelected: controller.paymentMethodIndex == 1,
                onTap: () {
                  controller.setPaymentMethod(1);
                  Navigator.pop(ctx);
                },
              ),
            if (isDigitalPaymentActive)
              PaymentButtonNew(
                icon: Icons.credit_card,
                title: 'digital_payment'.tr,
                isSelected: controller.paymentMethodIndex == 2,
                onTap: () {
                  controller.setPaymentMethod(2);
                  Navigator.pop(ctx);
                },
              ),
            if (isOfflinePaymentActive)
              PaymentButtonNew(
                icon: Icons.payment,
                title: 'offline_payment'.tr,
                isSelected: controller.paymentMethodIndex == 3,
                onTap: () {
                  controller.setPaymentMethod(3);
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showCouponSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CouponBottomSheet(
        checkoutController: checkoutController,
        price: price,
        discount: discount,
        addOns: addOns,
        deliveryCharge: deliveryCharge,
        total: total,
        charge: charge,
      ),
    );
  }
}
