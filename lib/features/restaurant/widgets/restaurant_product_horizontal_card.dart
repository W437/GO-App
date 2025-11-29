import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/common/models/product_model.dart';
import 'package:godelivery_user/common/widgets/shared/buttons/custom_ink_well_widget.dart';
import 'package:godelivery_user/common/widgets/shared/sheets/custom_sheet.dart';
import 'package:godelivery_user/features/cart/controllers/cart_controller.dart';
import 'package:godelivery_user/features/checkout/domain/models/place_order_body_model.dart';
import 'package:godelivery_user/features/home/widgets/blurhash_image_widget.dart';
import 'package:godelivery_user/features/restaurant/widgets/expandable_product_quantity_badge.dart';
import 'package:godelivery_user/common/widgets/adaptive/product/restaurant_product_sheet.dart';
import 'package:godelivery_user/helper/converters/price_converter.dart';
import 'package:godelivery_user/helper/ui/responsive_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';

class RestaurantProductHorizontalCard extends StatefulWidget {
  final Product product;
  const RestaurantProductHorizontalCard({super.key, required this.product});

  @override
  State<RestaurantProductHorizontalCard> createState() => _RestaurantProductHorizontalCardState();
}

class _RestaurantProductHorizontalCardState extends State<RestaurantProductHorizontalCard> {
  @override
  Widget build(BuildContext context) {
    double price = widget.product.price!;
    double discount = widget.product.discount!;
    String discountType = widget.product.discountType!;
    double discountPrice = PriceConverter.convertWithDiscount(price, discount, discountType)!;

    // Build tooltip message
    String tooltipMessage = widget.product.name ?? '';
    if (widget.product.description != null && widget.product.description!.isNotEmpty) {
      tooltipMessage += '\n\n${widget.product.description}';
    }

    return Tooltip(
      message: tooltipMessage,
      preferBelow: false,
      verticalOffset: 20,
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      margin: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      textStyle: robotoRegular.copyWith(
        fontSize: Dimensions.fontSizeSmall,
        color: Theme.of(context).textTheme.bodyLarge?.color,
      ),
      waitDuration: const Duration(milliseconds: 500),
      child: CustomInkWellWidget(
        onTap: () {
          if (ResponsiveHelper.isMobile(context)) {
            CustomSheet.show(
              context: context,
              child: RestaurantProductSheet(product: widget.product, inRestaurantPage: true),
              showHandle: false,
              padding: EdgeInsets.zero,
            );
          } else {
            Get.dialog(
              Dialog(child: RestaurantProductSheet(product: widget.product, inRestaurantPage: true)),
            );
          }
        },
        radius: Dimensions.radiusDefault,
        padding: EdgeInsets.zero,
        child: SizedBox(
        width: 160,
        child: Stack(
          children: [
            GetBuilder<CartController>(
              builder: (cartController) {
                int totalQuantity = 0;
                for (var cartItem in cartController.cartList) {
                  if (cartItem.product?.id == widget.product.id) {
                    totalQuantity += cartItem.quantity ?? 0;
                  }
                }

                final bool isInCart = totalQuantity > 0;

                return Container(
                  width: 160,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Product Image - fixed height
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(Dimensions.radiusDefault),
                            topRight: Radius.circular(Dimensions.radiusDefault),
                          ),
                          child: BlurhashImageWidget(
                            imageUrl: widget.product.imageFullUrl ?? '',
                            blurhash: widget.product.imageBlurhash,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                      // Bottom info section - below image
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(Dimensions.radiusDefault),
                            bottomRight: Radius.circular(Dimensions.radiusDefault),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Likes & Price Row - full width muted bg
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 6),
                              decoration: BoxDecoration(
                                color: Theme.of(context).hintColor.withValues(alpha: 0.08),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Icon(Icons.favorite, color: Colors.red, size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${widget.product.likeCount ?? 0}',
                                        style: robotoRegular.copyWith(
                                          fontSize: Dimensions.fontSizeSmall,
                                          color: Theme.of(context).hintColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    PriceConverter.convertPrice(discountPrice),
                                    style: robotoMedium.copyWith(
                                      fontSize: Dimensions.fontSizeDefault,
                                      color: Theme.of(context).textTheme.bodyLarge?.color,
                                      height: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Name - single line with ellipsis
                            Padding(
                              padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                              child: Text(
                                widget.product.name ?? '',
                                style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Blue strip at bottom - only when in cart
            GetBuilder<CartController>(
              builder: (cartController) {
                int totalQuantity = 0;
                for (var cartItem in cartController.cartList) {
                  if (cartItem.product?.id == widget.product.id) {
                    totalQuantity += cartItem.quantity ?? 0;
                  }
                }

                if (totalQuantity == 0) return const SizedBox();

                return Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(Dimensions.radiusDefault),
                        bottomRight: Radius.circular(Dimensions.radiusDefault),
                      ),
                    ),
                  ),
                );
              },
            ),

            // Add Button / Quantity Badge - Top Right Corner
            Positioned(
              top: 0,
              right: 0,
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (_) {}, // Block pointer events
                onPointerUp: (_) {},   // Block pointer events
                onPointerMove: (_) {}, // Block pointer events
                onPointerCancel: (_) {}, // Block pointer events
                child: GetBuilder<CartController>(
                  builder: (cartController) {
                    final cartItems = cartController.cartList
                        .where((item) => item.product?.id == widget.product.id)
                        .toList();
                    final int totalQuantity = cartItems.fold(0, (sum, item) => sum + (item.quantity ?? 0));

                    // Show quantity badge if in cart
                    if (totalQuantity > 0) {
                      return ExpandableProductQuantityBadge(
                        productId: widget.product.id!,
                      );
                    }

                    // Show ADD button if not in cart
                    return GestureDetector(
                      onTap: () {
                        // Check if product has variations
                        if (widget.product.variations != null && widget.product.variations!.isNotEmpty) {
                          // Open product sheet for variations
                          if (ResponsiveHelper.isMobile(context)) {
                            CustomSheet.show(
                              context: context,
                              child: RestaurantProductSheet(product: widget.product, inRestaurantPage: true),
                              showHandle: false,
                              padding: EdgeInsets.zero,
                            );
                          } else {
                            Get.dialog(
                              Dialog(child: RestaurantProductSheet(product: widget.product, inRestaurantPage: true)),
                            );
                          }
                        } else {
                          // Add directly to cart
                          final onlineCart = OnlineCart(
                            null,
                            widget.product.id,
                            null,
                            widget.product.price!.toString(),
                            [],
                            1,
                            [],
                            [],
                            [],
                            'Food',
                            variationOptionIds: [],
                          );
                          cartController.addToCartOnline(onlineCart, fromDirectlyAdd: true);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(Dimensions.radiusDefault),
                            bottomLeft: Radius.circular(Dimensions.radiusDefault),
                          ),
                        ),
                        child: Text(
                          'ADD',
                          style: robotoBold.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

