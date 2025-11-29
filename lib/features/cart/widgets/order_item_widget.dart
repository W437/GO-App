import 'dart:math';
import 'package:collection/collection.dart';
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
    final Color accent = Theme.of(context).primaryColor;
    final double lineTotal = _calculateLineTotal(
      discount: discount,
      discountType: discountType,
    );

    return GestureDetector(
      onTap: () => _navigateToProductInRestaurant(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Quantity badge (clickable)
            ExpandableQuantityBadge(
              cart: cart,
              cartIndex: cartIndex,
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),

            // Item Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cart.product!.name ?? '',
                    style: robotoMedium.copyWith(
                      fontSize: Dimensions.fontSizeDefault,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  Text(
                    PriceConverter.convertPrice(lineTotal),
                    style: robotoMedium.copyWith(
                      fontSize: Dimensions.fontSizeDefault,
                      color: accent,
                    ),
                    textDirection: TextDirection.ltr,
                  ),

                  if (variationText.isNotEmpty || addOnText.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    if (variationText.isNotEmpty)
                      Text(
                        variationText,
                        style: robotoRegular.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          color: Theme.of(context).hintColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (addOnText.isNotEmpty)
                      Text(
                        addOnText,
                        style: robotoRegular.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          color: Theme.of(context).hintColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),

            // Image
            if (cart.product!.imageFullUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                child: SizedBox(
                  width: 72,
                  height: 72,
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

  double _calculateLineTotal({double? discount, String? discountType}) {
    final int quantity = cart.quantity ?? 1;

    // Base price with discount applied per item
    final double unitPrice = PriceConverter.convertWithDiscount(
          cart.product!.price!,
          discount,
          discountType,
        ) ??
        cart.product!.price!;
    double total = unitPrice * quantity;

    // Variation price (per selected option * quantity)
    if (cart.product?.variations != null && cart.variations != null) {
      final int variationGroupCount = min(cart.product!.variations!.length, cart.variations!.length);
      for (int group = 0; group < variationGroupCount; group++) {
        final variation = cart.product!.variations![group];
        final selections = cart.variations![group];
        if (variation.variationValues == null || selections == null) continue;

        final int optionCount = min(variation.variationValues!.length, selections.length);
        for (int option = 0; option < optionCount; option++) {
          if (selections[option] == true) {
            total += (variation.variationValues![option].optionPrice ?? 0) * quantity;
          }
        }
      }
    }

    // Add-ons price (stored quantity is already absolute)
    if (cart.addOnIds != null && cart.product?.addOns != null) {
      for (final addOnId in cart.addOnIds!) {
        final addOn = cart.product!.addOns!.firstWhereOrNull((element) => element.id == addOnId.id);
        if (addOn != null) {
          total += (addOn.price ?? 0) * (addOnId.quantity ?? 1);
        }
      }
    }

    return PriceConverter.toFixed(total);
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
