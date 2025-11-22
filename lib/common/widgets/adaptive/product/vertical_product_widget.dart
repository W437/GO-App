import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/common/models/product_model.dart';
import 'package:godelivery_user/common/widgets/adaptive/custom_favourite_widget.dart';
import 'package:godelivery_user/common/widgets/adaptive/discount_tag_widget.dart';
import 'package:godelivery_user/common/widgets/adaptive/not_available_widget.dart';
import 'package:godelivery_user/common/widgets/adaptive/product/product_bottom_sheet_widget.dart';
import 'package:godelivery_user/common/widgets/shared/buttons/custom_ink_well_widget.dart';
import 'package:godelivery_user/common/widgets/shared/feedback/custom_snackbar_widget.dart';
import 'package:godelivery_user/common/widgets/shared/sheets/custom_sheet.dart';
import 'package:godelivery_user/features/cart/controllers/cart_controller.dart';
import 'package:godelivery_user/features/cart/domain/models/cart_model.dart';
import 'package:godelivery_user/features/home/widgets/blurhash_image_widget.dart';
import 'package:godelivery_user/helper/converters/date_converter.dart';
import 'package:godelivery_user/helper/converters/price_converter.dart';
import 'package:godelivery_user/helper/ui/responsive_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';

class VerticalProductWidget extends StatelessWidget {
  final Product product;
  final int index;
  final int length;
  final bool isCampaign;
  final bool inRestaurant;

  const VerticalProductWidget({
    super.key,
    required this.product,
    required this.index,
    required this.length,
    this.isCampaign = false,
    this.inRestaurant = false,
  });

  @override
  Widget build(BuildContext context) {
    bool desktop = ResponsiveHelper.isDesktop(context);
    double? discount = product.discount;
    String? discountType = product.discountType;
    bool isAvailable = DateConverter.isAvailable(product.availableTimeStarts, product.availableTimeEnds);

    return Padding(
      padding: EdgeInsets.only(bottom: desktop ? 0 : Dimensions.paddingSizeSmall),
      child: CustomInkWellWidget(
        onTap: () {
          ResponsiveHelper.isMobile(context)
              ? CustomSheet.show(
                  context: context,
                  child: ProductBottomSheetWidget(product: product, isCampaign: isCampaign),
                  showHandle: true,
                  padding: EdgeInsets.zero,
                )
              : Get.dialog(
                  Dialog(child: ProductBottomSheetWidget(product: product, isCampaign: isCampaign)),
                );
        },
        radius: Dimensions.radiusDefault,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, 1),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section with Overlays
              Expanded(
                flex: 6,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(Dimensions.radiusDefault)),
                      child: BlurhashImageWidget(
                        imageUrl: product.imageFullUrl ?? '',
                        blurhash: product.imageBlurhash,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                    DiscountTagWidget(
                      discount: discount,
                      discountType: discountType,
                      freeDelivery: false,
                    ),
                    // Add Button Overlay (Circular, Bottom Right)
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: GetBuilder<CartController>(builder: (cartController) {
                        int cartQty = cartController.cartQuantity(product.id!);
                        return InkWell(
                          onTap: () {
                            if (cartQty > 0) {
                              // Already in cart, open details
                              ResponsiveHelper.isMobile(context)
                                  ? Get.bottomSheet(
                                      ProductBottomSheetWidget(product: product, isCampaign: isCampaign),
                                      backgroundColor: Colors.transparent,
                                      isScrollControlled: true,
                                    )
                                  : Get.dialog(
                                      Dialog(child: ProductBottomSheetWidget(product: product, isCampaign: isCampaign)),
                                    );
                            } else {
                              // Add to cart
                              if (isAvailable) {
                                OnlineCart onlineCart = OnlineCart(
                                    null, product.id, null,
                                    product.price!.toString(), '', null,
                                    null, null, [], [], [], 'Food', [], product.name, product.image
                                );
                                cartController.addToCartOnline(onlineCart);
                              } else {
                                showCustomSnackBar('item_not_available'.tr);
                              }
                            }
                          },
                          child: Container(
                            height: 35,
                            width: 35,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).primaryColor,
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 5, offset: const Offset(0, 2))
                              ],
                            ),
                            child: Icon(
                              cartQty > 0 ? Icons.check : Icons.add,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        );
                      }),
                    ),
                    if (!isAvailable) const NotAvailableWidget(isRestaurant: false),
                  ],
                ),
              ),

              // Text Section
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name ?? '',
                            style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            product.description ?? '',
                            style: robotoRegular.copyWith(
                              fontSize: Dimensions.fontSizeExtraSmall,
                              color: Theme.of(context).disabledColor,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (discount != null && discount > 0)
                                Text(
                                  PriceConverter.convertPrice(product.price),
                                  style: robotoRegular.copyWith(
                                    fontSize: Dimensions.fontSizeExtraSmall,
                                    color: Theme.of(context).disabledColor,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              Text(
                                PriceConverter.convertPrice(
                                  product.price,
                                  discount: discount,
                                  discountType: discountType,
                                ),
                                style: robotoBold.copyWith(
                                  fontSize: Dimensions.fontSizeDefault,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ],
                          ),
                          CustomFavouriteWidget(
                            isWished: Get.find<FavouriteController>().wishProductIdList.contains(product.id),
                            isRestaurant: false,
                            product: product,
                            size: 20,
                          )
                        ],
                      ),
                    ],
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

