import 'package:godelivery_user/common/widgets/shared/buttons/custom_ink_well_widget.dart';
import 'package:godelivery_user/features/home/widgets/all_cuisines_bottom_sheet.dart';
import 'package:godelivery_user/features/home/widgets/arrow_icon_button_widget.dart';
import 'package:godelivery_user/features/home/widgets/cuisine_card_widget.dart';
import 'package:godelivery_user/features/splash/controllers/theme_controller.dart';
import 'package:godelivery_user/features/cuisine/controllers/cuisine_controller.dart';
import 'package:godelivery_user/helper/ui/responsive_helper.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/images.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class CuisineViewWidget extends StatelessWidget {
  const CuisineViewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CuisineController>(builder: (cuisineController) {
        return (cuisineController.cuisineModel != null && cuisineController.cuisineModel!.cuisines!.isEmpty) ? const SizedBox() : Container(
          width: Dimensions.webMaxWidth,
          margin: EdgeInsets.symmetric(vertical: ResponsiveHelper.isMobile(context)  ? Dimensions.paddingSizeDefault : Dimensions.paddingSizeLarge),
          decoration: BoxDecoration(
            image: DecorationImage(
              image: const AssetImage(Images.cuisineBgPng),
              colorFilter: ColorFilter.mode(Theme.of(context).primaryColor.withValues(alpha: 0.1), BlendMode.color),
              fit: BoxFit.cover,
            ),
            borderRadius: BorderRadius.all(Radius.circular(ResponsiveHelper.isMobile(context) ? 0 : Dimensions.radiusSmall)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: Dimensions.paddingSizeLarge,
                  right: Dimensions.paddingSizeLarge,
                  top: Dimensions.paddingSizeLarge,
                  bottom: Dimensions.paddingSizeDefault,
                ),
                child: Text('cuisine'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge, fontWeight: FontWeight.w600)),
              ),

              SizedBox(
                height: ResponsiveHelper.isMobile(context) ? 120 : 170,
                child: cuisineController.cuisineModel != null ? ListView.builder(
                  physics: ResponsiveHelper.isMobile(context) ? const BouncingScrollPhysics() : const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: Dimensions.paddingSizeLarge),
                  itemCount: cuisineController.cuisineModel!.cuisines!.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: Dimensions.paddingSizeLarge),
                      child: CustomInkWellWidget(
                        onTap: () => Get.toNamed(RouteHelper.getCuisineRestaurantRoute(cuisineController.cuisineModel!.cuisines![index].id, cuisineController.cuisineModel!.cuisines![index].name)),
                        radius: Dimensions.radiusDefault,
                        child: SizedBox(
                          width: ResponsiveHelper.isMobile(context) ? 100 : 120,
                          child: CuisineCardWidget(
                            image: cuisineController.cuisineModel!.cuisines![index].imageFullUrl ?? '',
                            name: cuisineController.cuisineModel!.cuisines![index].name ?? '',
                          ),
                        ),
                      ),
                    );
                  },
                ) : const CuisineShimmer(),
              ),

              const SizedBox(height: Dimensions.paddingSizeLarge),
            ],
          ),
        );
      }
    );
  }
}



class CuisineShimmer extends StatelessWidget {
  const CuisineShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(left: Dimensions.paddingSizeLarge),
      itemCount: 6,
      shrinkWrap: true,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(right: Dimensions.paddingSizeLarge),
          child: SizedBox(
            width: ResponsiveHelper.isMobile(context) ? 100 : 120,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(Dimensions.paddingSizeSmall), bottomRight: Radius.circular(Dimensions.paddingSizeSmall)),
              child: Stack(
                children: [
                  Positioned(bottom: -55, left: 0, right: 0,
                    child: Transform.rotate(
                      angle: 40,
                      child: Container(
                        height: 120, width: 120,
                        color: Theme.of(context).cardColor,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[Get.find<ThemeController>().darkTheme ? 950 : 200],
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: Shimmer(
                            child: Container(
                              height: 100, width: 100,
                              color: Colors.grey[Get.find<ThemeController>().darkTheme ? 900 : 200],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      alignment: Alignment.center,
                      height: 30, width: 120,
                      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall),
                      decoration: BoxDecoration(
                        color: Colors.grey[Get.find<ThemeController>().darkTheme ? 800 : 100],
                        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(Dimensions.paddingSizeSmall), bottomRight: Radius.circular(Dimensions.paddingSizeSmall)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}



