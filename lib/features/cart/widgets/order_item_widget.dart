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
/// Collapsed: [Qty Badge] [Name + Price] [Image]
/// Expanded: [Delete] [- qty +] [spacer] [Product Title] [Image]
class OrderItemWidget extends StatefulWidget {
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
  State<OrderItemWidget> createState() => _OrderItemWidgetState();
}

class _OrderItemWidgetState extends State<OrderItemWidget> {
  bool _isExpanded = false;

  @override
  void didUpdateWidget(OrderItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset expanded state if cart item changed
    if (oldWidget.cart.product?.id != widget.cart.product?.id ||
        oldWidget.cartIndex != widget.cartIndex) {
      _isExpanded = false;
    }
  }

  void _onExpandedChanged(bool expanded) {
    setState(() {
      _isExpanded = expanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    String addOnText = CartHelper.setupAddonsText(cart: widget.cart) ?? '';
    String variationText = CartHelper.setupVariationText(cart: widget.cart);
    double? discount = widget.cart.product!.discount;
    String? discountType = widget.cart.product!.discountType;
    final Color accent = Theme.of(context).primaryColor;
    final double lineTotal = _calculateLineTotal(
      discount: discount,
      discountType: discountType,
    );

    return GestureDetector(
      onTap: _isExpanded ? null : () => _navigateToProductInRestaurant(context),
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
            // Quantity badge / Edit controls
            ExpandableQuantityBadge(
              cart: widget.cart,
              cartIndex: widget.cartIndex,
              onExpandedChanged: _onExpandedChanged,
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),

            // Item Info (fades out when expanded) / Product title (fades in when expanded)
            Expanded(
              child: AnimatedCrossFade(
                duration: const Duration(milliseconds: 200),
                crossFadeState: _isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: _buildProductInfo(context, accent, lineTotal, variationText, addOnText),
                secondChild: _buildExpandedTitle(context),
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),

            // Image
            if (widget.cart.product!.imageFullUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: BlurhashImageWidget(
                    imageUrl: widget.cart.product!.imageFullUrl!,
                    blurhash: widget.cart.product!.imageBlurhash,
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

  Widget _buildProductInfo(
    BuildContext context,
    Color accent,
    double lineTotal,
    String variationText,
    String addOnText,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.cart.product!.name ?? '',
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
    );
  }

  Widget _buildExpandedTitle(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        widget.cart.product!.name ?? '',
        style: robotoMedium.copyWith(
          fontSize: Dimensions.fontSizeSmall,
          color: Theme.of(context).hintColor,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.right,
      ),
    );
  }

  double _calculateLineTotal({double? discount, String? discountType}) {
    final int quantity = widget.cart.quantity ?? 1;

    // Base price with discount applied per item
    final double unitPrice = PriceConverter.convertWithDiscount(
          widget.cart.product!.price!,
          discount,
          discountType,
        ) ??
        widget.cart.product!.price!;
    double total = unitPrice * quantity;

    // Variation price (per selected option * quantity)
    if (widget.cart.product?.variations != null && widget.cart.variations != null) {
      final int variationGroupCount = min(widget.cart.product!.variations!.length, widget.cart.variations!.length);
      for (int group = 0; group < variationGroupCount; group++) {
        final variation = widget.cart.product!.variations![group];
        final selections = widget.cart.variations![group];
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
    if (widget.cart.addOnIds != null && widget.cart.product?.addOns != null) {
      for (final addOnId in widget.cart.addOnIds!) {
        final addOn = widget.cart.product!.addOns!.firstWhereOrNull((element) => element.id == addOnId.id);
        if (addOn != null) {
          total += (addOn.price ?? 0) * (addOnId.quantity ?? 1);
        }
      }
    }

    return PriceConverter.toFixed(total);
  }

  void _navigateToProductInRestaurant(BuildContext context) {
    if (widget.cart.product?.restaurantId == null || widget.cart.product?.id == null) {
      return;
    }

    Get.toNamed(
      RouteHelper.getRestaurantRoute(
        widget.cart.product!.restaurantId,
        scrollToProductId: widget.cart.product!.id,
      ),
      arguments: RestaurantScreen(
        restaurant: Restaurant(id: widget.cart.product!.restaurantId),
        scrollToProductId: widget.cart.product!.id,
      ),
    );
  }
}
