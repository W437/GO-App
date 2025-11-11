import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/features/category/controllers/category_controller.dart';
import 'package:godelivery_user/common/widgets/custom_image_widget.dart';
import 'package:godelivery_user/common/widgets/custom_ink_well_widget.dart';
import 'package:godelivery_user/helper/responsive_helper.dart';
import 'package:godelivery_user/helper/route_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';

class AllCategoriesBottomSheet extends StatelessWidget {
  const AllCategoriesBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(Dimensions.radiusExtraLarge),
          topRight: Radius.circular(Dimensions.radiusExtraLarge),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: Dimensions.paddingSizeDefault),
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).disabledColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'categories'.tr,
                  style: robotoBold.copyWith(
                    fontSize: Dimensions.fontSizeLarge,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
          ),

          // Categories Grid
          Flexible(
            child: GetBuilder<CategoryController>(
              builder: (categoryController) {
                return categoryController.categoryList != null
                    ? GridView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Dimensions.paddingSizeLarge,
                          vertical: Dimensions.paddingSizeSmall,
                        ),
                        shrinkWrap: true,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: ResponsiveHelper.isMobile(context) ? 3 : 6,
                          mainAxisSpacing: Dimensions.paddingSizeSmall,
                          crossAxisSpacing: Dimensions.paddingSizeSmall,
                          childAspectRatio: 1,
                        ),
                        itemCount: categoryController.categoryList!.length,
                        itemBuilder: (context, index) {
                          return CustomInkWellWidget(
                            onTap: () {
                              Get.back();
                              Get.toNamed(RouteHelper.getCategoryProductRoute(
                                categoryController.categoryList![index].id,
                                categoryController.categoryList![index].name!,
                              ));
                            },
                            radius: Dimensions.radiusDefault,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey[Get.isDarkMode ? 800 : 200]!,
                                    blurRadius: 5,
                                    spreadRadius: 1,
                                  )
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                                    child: CustomImageWidget(
                                      height: 50,
                                      width: 50,
                                      fit: BoxFit.cover,
                                      image: categoryController.categoryList![index].imageFullUrl ?? '',
                                    ),
                                  ),
                                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                                  Text(
                                    categoryController.categoryList![index].name!,
                                    textAlign: TextAlign.center,
                                    style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      )
                    : const Center(child: CircularProgressIndicator());
              },
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + Dimensions.paddingSizeDefault),
        ],
      ),
    );
  }
}
