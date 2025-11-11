import 'package:godelivery_user/common/widgets/bouncy_bottom_sheet.dart';
import 'package:godelivery_user/common/widgets/custom_ink_well_widget.dart';
import 'package:godelivery_user/features/home/widgets/all_categories_bottom_sheet.dart';
import 'package:godelivery_user/features/home/widgets/arrow_icon_button_widget.dart';
import 'package:godelivery_user/features/language/controllers/localization_controller.dart';
import 'package:godelivery_user/features/category/controllers/category_controller.dart';
import 'package:godelivery_user/helper/responsive_helper.dart';
import 'package:godelivery_user/helper/route_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:godelivery_user/common/widgets/custom_image_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class WhatOnYourMindViewWidget extends StatelessWidget {
  const WhatOnYourMindViewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CategoryController>(builder: (categoryController) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: EdgeInsets.only(
            top: ResponsiveHelper.isMobile(context) ? Dimensions.paddingSizeLarge : Dimensions.paddingSizeOverLarge,
            left: Get.find<LocalizationController>().isLtr ? Dimensions.paddingSizeExtraSmall : 0,
            right: Get.find<LocalizationController>().isLtr ? 0 : Dimensions.paddingSizeExtraSmall,
            bottom: ResponsiveHelper.isMobile(context) ? Dimensions.paddingSizeDefault : Dimensions.paddingSizeOverLarge,
          ),
          child: Padding(padding: const EdgeInsets.only(left: Dimensions.paddingSizeSmall, right: Dimensions.paddingSizeDefault),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('what_on_your_mind'.tr, style: ResponsiveHelper.isDesktop(context) ? robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge, fontWeight: FontWeight.w600) : robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge, fontWeight: FontWeight.w600)),
              ArrowIconButtonWidget(onTap: () {
                showBouncyBottomSheet(
                  context: context,
                  builder: (context) => const AllCategoriesBottomSheet(),
                );
              }),
            ]),
          ),
        ),

        SizedBox(
          height: ResponsiveHelper.isMobile(context) ? 120 : 170,
          child: categoryController.categoryList != null ? ListView.builder(
            physics: ResponsiveHelper.isMobile(context) ? const BouncingScrollPhysics() : const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: Dimensions.paddingSizeDefault),
            itemCount: categoryController.categoryList!.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall, right: Dimensions.paddingSizeDefault),
                child: Column(
                  children: [
                    CustomInkWellWidget(
                      onTap: () => Get.toNamed(RouteHelper.getCategoryProductRoute(
                        categoryController.categoryList![index].id, categoryController.categoryList![index].name!,
                      )),
                      radius: Dimensions.radiusLarge,
                      child: Container(
                        width: ResponsiveHelper.isMobile(context) ? 70 : 90,
                        height: ResponsiveHelper.isMobile(context) ? 70 : 90,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                          color: Get.isDarkMode
                            ? Theme.of(context).cardColor
                            : Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.2),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(2),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(Dimensions.radiusLarge - 2),
                            child: CustomImageWidget(
                              image: categoryController.categoryList![index].imageFullUrl ?? '',
                              height: ResponsiveHelper.isMobile(context) ? 66 : 86,
                              width: ResponsiveHelper.isMobile(context) ? 66 : 86,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                    SizedBox(
                      width: ResponsiveHelper.isMobile(context) ? 70 : 90,
                      child: Text(
                        categoryController.categoryList![index].name!,
                        style: robotoMedium.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1, 
                        overflow: TextOverflow.ellipsis, 
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            },
          ) : WebWhatOnYourMindViewShimmer(categoryController: categoryController),
        ),

        const SizedBox(height: Dimensions.paddingSizeLarge),

      ]);
    });
  }
}

class WebWhatOnYourMindViewShimmer extends StatelessWidget {
  final CategoryController categoryController;
  const WebWhatOnYourMindViewShimmer({super.key, required this.categoryController});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: ResponsiveHelper.isMobile(context) ? 120 : 170,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: 10,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: Dimensions.paddingSizeSmall),
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall, right: Dimensions.paddingSizeSmall, top: Dimensions.paddingSizeSmall),
            child: Container(
              width: ResponsiveHelper.isMobile(context) ? 70 : 108,
              height: ResponsiveHelper.isMobile(context) ? 70 : 100,
              padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
              margin: EdgeInsets.only(top: ResponsiveHelper.isMobile(context) ? 0 : Dimensions.paddingSizeSmall),
              child: Column(children: [

                ClipRRect(
                  borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                  child: Shimmer(
                    child: Container(
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(Dimensions.radiusLarge), color: Theme.of(context).shadowColor),
                      height: ResponsiveHelper.isMobile(context) ? 70 : 80, width: 70,
                    ),
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeSmall),

                ClipRRect(
                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                  child: Shimmer(
                    child: Container(
                      height: ResponsiveHelper.isMobile(context) ? 10 : 15, width: 150,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(Dimensions.radiusSmall), color: Theme.of(context).shadowColor),
                    ),
                  ),
                ),

              ]),
            ),
          );
        },
      ),
    );
  }
}