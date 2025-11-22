import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/common/models/product_model.dart';
import 'package:godelivery_user/common/widgets/adaptive/product/product_bottom_sheet_widget.dart';
import 'package:godelivery_user/common/widgets/shared/buttons/custom_ink_well_widget.dart';
import 'package:godelivery_user/features/cart/controllers/cart_controller.dart';
import 'package:godelivery_user/features/home/widgets/blurhash_image_widget.dart';
import 'package:godelivery_user/features/restaurant/widgets/compact_expandable_cart_badge.dart';
import 'package:godelivery_user/helper/converters/price_converter.dart';
import 'package:godelivery_user/helper/ui/responsive_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';

class RestaurantHorizontalProductCard extends StatelessWidget {
  final Product product;
  const RestaurantHorizontalProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    double price = product.price!;
    double discount = product.discount!;
    String discountType = product.discountType!;
    double discountPrice = PriceConverter.convertWithDiscount(price, discount, discountType)!;

    return CustomInkWellWidget(
      onTap: () {
        if (ResponsiveHelper.isMobile(context)) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            useRootNavigator: true,
            builder: (context) => TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.95, end: 1.0),
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  alignment: Alignment.bottomCenter,
                  child: child,
                );
              },
              child: ProductBottomSheetWidget(product: product, inRestaurantPage: true),
            ),
          );
        } else {
          Get.dialog(
            Dialog(child: ProductBottomSheetWidget(product: product, inRestaurantPage: true)),
          );
        }
      },
      radius: Dimensions.radiusDefault,
      padding: EdgeInsets.zero,
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(6, 24, 44, 0.1),
              blurRadius: 0,
              spreadRadius: 2,
              offset: Offset(0, 0),
            ),
            BoxShadow(
              color: Color.fromRGBO(6, 24, 44, 0.3),
              blurRadius: 6,
              spreadRadius: -1,
              offset: Offset(0, 4),
            ),
            BoxShadow(
              color: Color.fromRGBO(255, 255, 255, 0.08),
              blurRadius: 0,
              spreadRadius: 0,
              offset: Offset(0, 1),
            ),
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.3),
              blurRadius: 0,
              spreadRadius: 0,
              offset: Offset(0, 0),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Product Image - takes up top 70% of card
            Align(
              alignment: Alignment.topCenter,
              child: FractionallySizedBox(
                heightFactor: 0.7,
                widthFactor: 1.0,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(Dimensions.radiusDefault),
                    topRight: Radius.circular(Dimensions.radiusDefault),
                  ),
                  child: BlurhashImageWidget(
                    imageUrl: product.imageFullUrl ?? '',
                    blurhash: product.imageBlurhash,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            // Bottom info section - overlays bottom of image
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                ),
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Likes & Price Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.favorite, color: Colors.orange, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${product.likeCount ?? 0}',
                              style: robotoRegular.copyWith(
                                fontSize: Dimensions.fontSizeSmall,
                                color: Theme.of(context).hintColor,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          PriceConverter.convertPrice(discountPrice),
                          style: robotoBold.copyWith(
                            fontSize: Dimensions.fontSizeDefault,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Name
                    Text(
                      product.name ?? '',
                      style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            // Expandable Cart Badge - Top Right Corner
            Positioned(
              top: 0,
              right: 0,
              child: CompactExpandableCartBadge(
                productId: product.id!,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Extension to safely access unit if it's not in the model definition we saw earlier
// If 'unit' is not in Product, we might need to check if it's available or use something else.
// Based on the model file I read, I didn't see 'unit'. I saw 'choiceOptions', 'variations'.
// The reference image shows "350g", "1.5L". This is usually a 'unit' field.
// I'll check the Product model again quickly to see if I missed 'unit' or similar.
// If not, I'll just omit it or use description for now.
