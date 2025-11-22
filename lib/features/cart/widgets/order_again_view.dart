import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/common/widgets/adaptive/empty_states/not_logged_in_screen.dart';
import 'package:godelivery_user/common/widgets/shared/buttons/custom_button_widget.dart';
import 'package:godelivery_user/features/auth/controllers/auth_controller.dart';
import 'package:godelivery_user/features/cart/widgets/cart_summary_card.dart';
import 'package:godelivery_user/features/order/controllers/order_controller.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';

class OrderAgainView extends StatelessWidget {
  const OrderAgainView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<OrderController>(builder: (orderController) {
      final isGuest = Get.find<AuthController>().isGuestLoggedIn();

      // Still loading
      if (orderController.historyOrderList == null) {
        return const Center(child: CircularProgressIndicator());
      }

      // Guest user - show login prompt
      if (orderController.historyUnauthorized && isGuest) {
        return NotLoggedInScreen(
          callBack: (success) {
            if (success) {
              orderController.getHistoryOrders(1);
            }
          },
        );
      }

      // Logged-in user with no orders - simple empty state
      if (orderController.historyOrderList!.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 64,
                color: Theme.of(context).disabledColor,
              ),
              const SizedBox(height: Dimensions.paddingSizeDefault),
              Text(
                'No past orders',
                style: robotoBold.copyWith(
                  fontSize: Dimensions.fontSizeLarge,
                  color: Theme.of(context).textTheme.bodyLarge!.color,
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              Text(
                'Your order history will appear here',
                style: robotoRegular.copyWith(
                  color: Theme.of(context).disabledColor,
                ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        itemCount: orderController.historyOrderList!.length,
        itemBuilder: (context, index) {
          final order = orderController.historyOrderList![index];
          
          List<String> itemImages = [];
          
          return CartSummaryCard(
            restaurantName: order.restaurant?.name ?? 'Unknown Restaurant',
            restaurantLogo: order.restaurant?.logoFullUrl ?? '',
            deliveryTime: null, // Past order
            subtotal: order.orderAmount ?? 0,
            itemImages: itemImages,
            onViewCart: () async {
              // Reorder logic
              // 1. Get order details
              // 2. Call reOrder
              // We need to show a loader or something, but for now let's just await
              // Ideally we should have a loading state in the UI
              
              await orderController.getOrderDetails(order.id.toString());
              if (orderController.orderDetails != null && order.restaurant != null) {
                orderController.reOrder(orderController.orderDetails!, order.restaurant!.zoneId);
              }
            },
            buttonText: 'Order again',
            isOffline: false, 
          );
        },
      );
    });
  }
}
