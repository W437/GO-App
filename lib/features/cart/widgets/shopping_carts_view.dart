import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/features/cart/controllers/cart_controller.dart';
import 'package:godelivery_user/features/cart/widgets/cart_summary_card.dart';
import 'package:godelivery_user/features/restaurant/controllers/restaurant_controller.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';

class ShoppingCartsView extends StatelessWidget {
  final VoidCallback? onViewCart;
  const ShoppingCartsView({super.key, this.onViewCart});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CartController>(builder: (cartController) {
      return GetBuilder<RestaurantController>(builder: (restaurantController) {
        if (cartController.cartList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_cart_outlined, size: 50, color: Theme.of(context).disabledColor),
                const SizedBox(height: Dimensions.paddingSizeSmall),
                Text('No active carts', style: robotoRegular.copyWith(color: Theme.of(context).disabledColor)),
              ],
            ),
          );
        }

        // Assuming single restaurant cart for now
        final restaurant = restaurantController.restaurant;
        final cartList = cartController.cartList;
        
        if (restaurant == null) return const SizedBox();

        List<String> itemImages = [];
        for (var cartModel in cartList) {
          if (cartModel.product?.imageFullUrl != null) {
            itemImages.add(cartModel.product!.imageFullUrl!);
          }
        }

        return ListView(
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          children: [
            CartSummaryCard(
              restaurantName: restaurant.name ?? '',
              restaurantLogo: restaurant.logoFullUrl ?? '',
              deliveryTime: restaurant.deliveryTime ?? '30-40 min',
              subtotal: cartController.subTotal,
              itemImages: itemImages,
              onViewCart: onViewCart ?? () {},
              isOffline: !restaurantController.isRestaurantOpenNow(restaurant.active!, restaurant.schedules),
            ),
          ],
        );
      });
    });
  }
}
