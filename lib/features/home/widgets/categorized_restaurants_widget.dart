import 'package:godelivery_user/common/models/restaurant_model.dart';
import 'package:godelivery_user/features/home/widgets/rest_card_large.dart';
import 'package:godelivery_user/helper/ui/responsive_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CategorizedRestaurantsWidget extends StatelessWidget {
  final String title;
  final List<Restaurant> restaurants;

  const CategorizedRestaurantsWidget({
    super.key,
    required this.title,
    required this.restaurants,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveHelper.isDesktop(context)
              ? 0
              : Dimensions.paddingSizeDefault,
          ),
          child: Text(
            title,
            style: robotoBold.copyWith(
              fontSize: Dimensions.fontSizeOverLarge,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeDefault),

        // Restaurants List or Empty State
        restaurants.isNotEmpty
          ? _buildRestaurantsList(context)
          : _buildEmptyState(context),
      ],
    );
  }

  Widget _buildRestaurantsList(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.isDesktop(context)
          ? 0
          : Dimensions.paddingSizeDefault,
      ),
      itemCount: restaurants.length,
      separatorBuilder: (context, index) => const SizedBox(
        height: Dimensions.paddingSizeLarge,
      ),
      itemBuilder: (context, index) {
        return RestaurantView(restaurant: restaurants[index]);
      },
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
                Icons.restaurant_menu_rounded,
                size: 56,
                color: Theme.of(context).hintColor.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'no_restaurants_in_category'.tr,
              style: robotoMedium.copyWith(
                fontSize: Dimensions.fontSizeLarge,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'check_other_categories'.tr,
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
