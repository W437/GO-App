import 'package:godelivery_user/common/widgets/shared/badges/primary_badge_widget.dart';
import 'package:godelivery_user/features/home/controllers/home_controller.dart';
import 'package:godelivery_user/features/home/widgets/rest_new_card.dart';
import 'package:godelivery_user/helper/ui/responsive_helper.dart';
import 'package:godelivery_user/util/app_colors.dart';
import 'package:godelivery_user/util/app_constants.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class NewRestViewWidget extends StatelessWidget {
  const NewRestViewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeController>(builder: (homeController) {
      final newRestaurants = homeController.homeFeedModel?.newRestaurants;
      final restaurants = newRestaurants?.restaurants;

      // Show shimmer while loading
      if (homeController.homeFeedModel == null) {
        return _buildShimmer(context);
      }

      // Hide section if no new restaurants
      if (restaurants == null || restaurants.isEmpty) {
        return const SizedBox();
      }

      return Padding(
        padding: EdgeInsets.symmetric(
          vertical: ResponsiveHelper.isMobile(context)
              ? Dimensions.paddingSizeDefault
              : Dimensions.paddingSizeLarge,
          horizontal: 2,
        ),
        child: Container(
          width: Dimensions.webMaxWidth,
          decoration: BoxDecoration(
            gradient: Get.isDarkMode ? AppColors.gradientFrostDark : AppColors.gradientFrost,
            borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
            boxShadow: [
              BoxShadow(
                color: Get.isDarkMode
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.grey.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Header
              Padding(
                padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                child: Row(
                  children: [
                    Text(
                      newRestaurants?.title ?? '${'new_on'.tr} ${AppConstants.appName}',
                      style: robotoBold.copyWith(
                        fontSize: Dimensions.fontSizeLarge,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    PrimaryBadgeWidget(
                      value: restaurants.length,
                      fontSize: Dimensions.fontSizeSmall,
                    ),
                  ],
                ),
              ),

              // Restaurant Cards - Horizontal List
              SizedBox(
                height: 145,
                child: ListView.builder(
                  padding: const EdgeInsets.only(
                    left: Dimensions.paddingSizeDefault,
                    right: Dimensions.paddingSizeDefault,
                    bottom: Dimensions.paddingSizeDefault,
                  ),
                  itemCount: restaurants.length,
                  shrinkWrap: true,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(
                        right: index < restaurants.length - 1
                            ? Dimensions.paddingSizeDefault
                            : 0,
                      ),
                      child: CompactRestaurantWidget(
                        restaurant: restaurants[index],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildShimmer(BuildContext context) {
    final shimmerBase = Theme.of(context).hintColor.withValues(alpha: 0.1);

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: ResponsiveHelper.isMobile(context)
            ? Dimensions.paddingSizeDefault
            : Dimensions.paddingSizeLarge,
      ),
      child: Container(
        width: Dimensions.webMaxWidth,
        decoration: BoxDecoration(
          gradient: Get.isDarkMode ? AppColors.gradientFrostDark : AppColors.gradientFrost,
          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: Get.isDarkMode
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header shimmer
            Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              child: Shimmer(
                child: Container(
                  height: 20,
                  width: 150,
                  decoration: BoxDecoration(
                    color: shimmerBase,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),

            // Cards shimmer
            SizedBox(
              height: 145,
              child: ListView.builder(
                padding: const EdgeInsets.only(
                  left: Dimensions.paddingSizeDefault,
                  right: Dimensions.paddingSizeDefault,
                  bottom: Dimensions.paddingSizeDefault,
                ),
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 4,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index < 3 ? Dimensions.paddingSizeDefault : 0,
                    ),
                    child: Shimmer(
                      child: Container(
                        width: 200,
                        decoration: BoxDecoration(
                          color: shimmerBase,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
