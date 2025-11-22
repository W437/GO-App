import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/features/cart/domain/models/cart_model.dart';
import 'package:godelivery_user/common/models/product_model.dart';
import 'package:godelivery_user/common/models/restaurant_model.dart';
import 'package:godelivery_user/features/cart/widgets/expandable_quantity_badge.dart';
import 'package:godelivery_user/features/restaurant/screens/restaurant_screen.dart';
import 'package:godelivery_user/helper/business_logic/cart_helper.dart';
import 'package:godelivery_user/helper/converters/price_converter.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:godelivery_user/features/home/widgets/blurhash_image_widget.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';

/// Order Item Widget - Simplified cart item display for order review
/// Layout: [Qty Pill] [Name + Description + Price] [Image]
/// Badge expands → pushes entire layout → image slides off-screen
class OrderItemWidget extends StatelessWidget {
  final CartModel cart;
  final int cartIndex;
  final List<AddOns> addOns;

  const OrderItemWidget({
    super.key,
    required this.cart,
    required this.cartIndex,
    required this.addOns,
  });

  @override
  Widget build(BuildContext context) {
    String addOnText = CartHelper.setupAddonsText(cart: cart) ?? '';
    String variationText = CartHelper.setupVariationText(cart: cart);
    double? discount = cart.product!.discount;
    String? discountType = cart.product!.discountType;

    return GestureDetector(
      onTap: () => _navigateToProductInRestaurant(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
        child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                // Expandable Quantity Badge
                ExpandableQuantityBadge(
                  cart: cart,
                  cartIndex: cartIndex,
                ),
                const SizedBox(width: Dimensions.paddingSizeDefault),

                // Item Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cart.product!.name!,
                        style: robotoMedium.copyWith(
                          fontSize: Dimensions.fontSizeDefault,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      if (variationText.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            variationText,
                            style: robotoRegular.copyWith(
                              fontSize: Dimensions.fontSizeSmall,
                              color: Theme.of(context).hintColor,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                      if (addOnText.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            addOnText,
                            style: robotoRegular.copyWith(
                              fontSize: Dimensions.fontSizeSmall,
                              color: Theme.of(context).hintColor,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                      const SizedBox(height: 4),

                      Text(
                        PriceConverter.convertPrice(
                          cart.product!.price,
                          discount: discount,
                          discountType: discountType,
                        ),
                        style: robotoMedium.copyWith(
                          fontSize: Dimensions.fontSizeDefault,
                          color: Theme.of(context).primaryColor,
                        ),
                        textDirection: TextDirection.ltr,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Dimensions.paddingSizeDefault),

                // Image
                if (cart.product!.imageFullUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child: BlurhashImageWidget(
                        imageUrl: cart.product!.imageFullUrl!,
                        blurhash: cart.product!.imageBlurhash,
                        fit: BoxFit.cover,
                        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                      ),
                    ),
                  ),
        ],
        ),
      ),
    );
  }

  void _navigateToProductInRestaurant(BuildContext context) {
    if (cart.product?.restaurantId == null || cart.product?.id == null) {
      return;
    }

    Get.toNamed(
      RouteHelper.getRestaurantRoute(
        cart.product!.restaurantId,
        scrollToProductId: cart.product!.id,
      ),
      arguments: RestaurantScreen(
        restaurant: Restaurant(id: cart.product!.restaurantId),
        scrollToProductId: cart.product!.id,
      ),
    );
  }
}
