import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/features/checkout/controllers/checkout_controller.dart';
import 'package:godelivery_user/features/location/controllers/location_controller.dart';
import 'package:godelivery_user/features/checkout/widgets/checkout_map_header.dart';
import 'package:godelivery_user/features/checkout/widgets/when_section.dart';
import 'package:godelivery_user/features/checkout/widgets/checkout_payment_section.dart';
import 'package:godelivery_user/features/checkout/widgets/tip_chips_section.dart';
import 'package:godelivery_user/features/checkout/widgets/minimal_summary_section.dart';
import 'package:godelivery_user/features/cart/domain/models/cart_model.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';

class CheckoutMobileView extends StatelessWidget {
  final CheckoutController checkoutController;
  final double price;
  final double discount;
  final double addOns;
  final double deliveryCharge;
  final double total;
  final double extraPackagingCharge;
  final double additionalCharge;
  final TextEditingController guestNameTextEditingController;
  final TextEditingController guestNumberTextEditingController;
  final TextEditingController guestEmailController;
  final FocusNode guestNumberNode;
  final FocusNode guestEmailNode;
  final JustTheController tooltipController2;
  final double badWeatherCharge;
  final double extraChargeForToolTip;
  final bool tomorrowClosed;
  final bool todayClosed;
  final double charge;
  final int subscriptionQty;
  final double orderAmount;
  final double? maxCodOrderAmount;
  final List<CartModel> cartList;
  final bool isCashOnDeliveryActive;
  final bool isDigitalPaymentActive;
  final bool isWalletActive;
  final bool isOfflinePaymentActive;
  final bool fromCart;
  final VoidCallback callBack;

  const CheckoutMobileView({
    super.key,
    required this.checkoutController,
    required this.price,
    required this.discount,
    required this.addOns,
    required this.deliveryCharge,
    required this.total,
    required this.extraPackagingCharge,
    required this.additionalCharge,
    required this.guestNameTextEditingController,
    required this.guestNumberTextEditingController,
    required this.guestEmailController,
    required this.guestNumberNode,
    required this.guestEmailNode,
    required this.tooltipController2,
    required this.badWeatherCharge,
    required this.extraChargeForToolTip,
    required this.tomorrowClosed,
    required this.todayClosed,
    required this.charge,
    required this.subscriptionQty,
    required this.orderAmount,
    required this.maxCodOrderAmount,
    required this.cartList,
    required this.isCashOnDeliveryActive,
    required this.isDigitalPaymentActive,
    required this.isWalletActive,
    required this.isOfflinePaymentActive,
    required this.fromCart,
    required this.callBack,
  });

  @override
  Widget build(BuildContext context) {
    final locationController = Get.find<LocationController>();
    final showTips = checkoutController.orderType != 'take_away' &&
                     checkoutController.orderType != 'dine_in';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Map header with tabs and quick actions
        CheckoutMapHeader(
          checkoutController: checkoutController,
          locationController: locationController,
        ),

        const SizedBox(height: 12),

        // When section
        WhenSection(
          checkoutController: checkoutController,
          todayClosed: todayClosed,
          tomorrowClosed: tomorrowClosed,
        ),

        const SizedBox(height: 12),

        // Payment section
        CheckoutPaymentSection(
          checkoutController: checkoutController,
          isCashOnDeliveryActive: isCashOnDeliveryActive,
          isDigitalPaymentActive: isDigitalPaymentActive,
          isWalletActive: isWalletActive,
          isOfflinePaymentActive: isOfflinePaymentActive,
          price: price,
          discount: discount,
          addOns: addOns,
          deliveryCharge: deliveryCharge,
          total: total,
          charge: charge,
        ),

        const SizedBox(height: 12),

        // Tips section
        if (showTips)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TipChipsSection(
              checkoutController: checkoutController,
            ),
          ),

        if (showTips) const SizedBox(height: 12),

        // Summary section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: MinimalSummarySection(
            checkoutController: checkoutController,
            orderAmount: orderAmount,
            charge: charge,
            subscriptionQty: subscriptionQty,
          ),
        ),

        const SizedBox(height: 120), // Bottom padding for order button
      ],
    );
  }
}
