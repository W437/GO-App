import 'package:godelivery_user/features/home/widgets/compact_restaurant_widget.dart';
import 'package:godelivery_user/features/restaurant/controllers/restaurant_controller.dart';
import 'package:godelivery_user/helper/ui/responsive_helper.dart';
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
    return GetBuilder<RestaurantController>(builder: (restaurantController) {
      final newRestaurants = restaurantController.homeFeedModel?.newRestaurants;
      final restaurants = newRestaurants?.restaurants;

      // Show shimmer while loading
      if (restaurantController.homeFeedModel == null) {
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
        ),
        child: Container(
          width: Dimensions.webMaxWidth,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${restaurants.length}',
                        style: robotoMedium.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Restaurant Cards - Horizontal List
              SizedBox(
                height: 190,
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
          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
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
              height: 190,
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
