import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/common/models/product_model.dart';
import 'package:godelivery_user/common/widgets/adaptive/product/product_bottom_sheet_widget.dart';
import 'package:godelivery_user/common/widgets/shared/buttons/custom_ink_well_widget.dart';
import 'package:godelivery_user/features/cart/controllers/cart_controller.dart';
import 'package:godelivery_user/features/home/widgets/blurhash_image_widget.dart';
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
              color: Color.fromRGBO(0, 0, 0, 0.16),
              blurRadius: 4,
              spreadRadius: 0,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              children: [
                // Product Image - fills the top section
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    width: double.infinity,
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

                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
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
            ],
          ),

            // Cart Quantity Badge - Top Right
            GetBuilder<CartController>(
              builder: (cartController) {
                // Calculate total quantity of this product in cart
                int totalQuantity = 0;
                for (var cartItem in cartController.cartList) {
                  if (cartItem.product?.id == product.id) {
                    totalQuantity += cartItem.quantity ?? 0;
                  }
                }

                if (totalQuantity == 0) return const SizedBox();

                return Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '$totalQuantity',
                      style: robotoBold.copyWith(
                        color: Colors.white,
                        fontSize: Dimensions.fontSizeSmall,
                      ),
                    ),
                  ),
                );
              },
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
