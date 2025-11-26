import 'package:animated_emoji/animated_emoji.dart';
import 'package:godelivery_user/features/home/widgets/categorized_restaurants_widget.dart';
import 'package:godelivery_user/features/restaurant/controllers/restaurant_controller.dart';
import 'package:godelivery_user/helper/ui/responsive_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

/// Widget that displays the "Explore" section with restaurants grouped by categories
/// Uses the home-feed API to get categorized restaurants
class RestCategoryViewWidget extends StatelessWidget {
  const RestCategoryViewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<RestaurantController>(builder: (restaurantController) {
      final categories = restaurantController.homeFeedCategories;

      // Loading state
      if (categories == null) {
        return _buildShimmer(context);
      }

      // Empty state
      if (categories.isEmpty) {
        return _buildEmptyState(context);
      }

      // Content
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title: "All Restaurants"
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveHelper.isDesktop(context)
                  ? 0
                  : Dimensions.paddingSizeDefault,
            ),
            child: Row(
              children: [
                Text(
                  'all_restaurants'.tr,
                  style: robotoBold.copyWith(
                    fontSize: Dimensions.fontSizeOverLarge + 4,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedEmoji(
                  AnimatedEmojis.yum,
                  size: 28,
                ),
              ],
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeLarge),

          // List of categorized restaurants
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: categories.length,
            separatorBuilder: (context, index) => const SizedBox(
              height: Dimensions.paddingSizeExtraLarge,
            ),
            itemBuilder: (context, index) {
              final category = categories[index];
              return CategorizedRestaurantsWidget(
                title: category.name ?? category.title ?? '',
                restaurants: category.restaurants ?? [],
              );
            },
          ),
        ],
      );
    });
  }

  Widget _buildShimmer(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title shimmer
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveHelper.isDesktop(context)
                ? 0
                : Dimensions.paddingSizeDefault,
          ),
          child: Shimmer(
            child: Container(
              height: 28,
              width: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).hintColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeLarge),

        // Category shimmers
        for (int i = 0; i < 2; i++) ...[
          _buildCategoryShimmer(context),
          const SizedBox(height: Dimensions.paddingSizeExtraLarge),
        ],
      ],
    );
  }

  Widget _buildCategoryShimmer(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category title shimmer
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveHelper.isDesktop(context)
                ? 0
                : Dimensions.paddingSizeDefault,
          ),
          child: Shimmer(
            child: Container(
              height: 20,
              width: 100,
              decoration: BoxDecoration(
                color: Theme.of(context).hintColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeDefault),

        // Restaurant card shimmers
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveHelper.isDesktop(context)
                ? 0
                : Dimensions.paddingSizeDefault,
          ),
          child: Column(
            children: [
              for (int j = 0; j < 2; j++) ...[
                _buildRestaurantCardShimmer(context),
                const SizedBox(height: Dimensions.paddingSizeLarge),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRestaurantCardShimmer(BuildContext context) {
    return Container(
      height: 305,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).hintColor.withValues(alpha: 0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          // Image shimmer
          Shimmer(
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                color: Theme.of(context).hintColor.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Shimmer(
                        child: Container(
                          height: 16,
                          width: 140,
                          decoration: BoxDecoration(
                            color: Theme.of(context).hintColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Shimmer(
                        child: Container(
                          height: 12,
                          width: 200,
                          decoration: BoxDecoration(
                            color: Theme.of(context).hintColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Shimmer(
                        child: Container(
                          height: 12,
                          width: 60,
                          decoration: BoxDecoration(
                            color: Theme.of(context).hintColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Shimmer(
                        child: Container(
                          height: 12,
                          width: 50,
                          decoration: BoxDecoration(
                            color: Theme.of(context).hintColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 60,
          horizontal: Dimensions.paddingSizeDefault,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).hintColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.explore_rounded,
                size: 56,
                color: Theme.of(context).hintColor.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'no_categories_available'.tr,
              style: robotoMedium.copyWith(
                fontSize: Dimensions.fontSizeLarge,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'check_back_later'.tr,
              style: robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeDefault,
                color: Theme.of(context).hintColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
