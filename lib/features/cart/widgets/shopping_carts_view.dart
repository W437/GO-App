import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/features/cart/controllers/cart_controller.dart';
import 'package:godelivery_user/features/cart/widgets/cart_summary_card.dart';
import 'package:godelivery_user/features/restaurant/screens/restaurant_screen.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';

class ShoppingCartsView extends StatelessWidget {
  final VoidCallback? onViewCart;
  const ShoppingCartsView({super.key, this.onViewCart});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CartController>(builder: (cartController) {
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

      // Multi-restaurant cart support: Display all restaurant carts
      final restaurantCarts = cartController.restaurantCarts;

      return ListView.builder(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        itemCount: restaurantCarts.length,
        itemBuilder: (context, index) {
          final restaurantCart = restaurantCarts[index];
          final restaurant = restaurantCart.restaurant;

          // Build item images for preview
          List<String> itemImages = [];
          for (var cartModel in restaurantCart.items) {
            if (cartModel.product?.imageFullUrl != null) {
              itemImages.add(cartModel.product!.imageFullUrl!);
            }
          }

          return CartSummaryCard(
            restaurantName: restaurant.name ?? '',
            restaurantLogo: restaurant.logoFullUrl ?? '',
            deliveryTime: restaurant.deliveryTime ?? '30-40 min',
            subtotal: restaurantCart.subtotal,
            itemImages: itemImages,
            onViewCart: () {
              if (onViewCart != null) {
                // Set context to this restaurant before viewing details
                cartController.setCurrentRestaurant(restaurantCart.restaurantId);
                onViewCart!();
              }
            },
            isOffline: !restaurantCart.canOrder,
            onAddMore: () {
              Get.toNamed(
                RouteHelper.getRestaurantRoute(restaurant.id!),
                arguments: RestaurantScreen(restaurantId: restaurant.id!),
              );
            },
            onDeleteCart: () {
              // Delete cart for this specific restaurant
              cartController.clearRestaurantCart(restaurantCart.restaurantId);
            },
          );
        },
      );
    });
  }
}
