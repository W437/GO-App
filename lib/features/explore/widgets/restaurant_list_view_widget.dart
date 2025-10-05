import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:godelivery_user/common/models/restaurant_model.dart';
import 'package:godelivery_user/common/widgets/custom_image_widget.dart';
import 'package:godelivery_user/features/explore/controllers/explore_controller.dart';
import 'package:godelivery_user/helper/address_helper.dart';
import 'package:godelivery_user/helper/route_helper.dart';
import 'package:godelivery_user/features/restaurant/screens/restaurant_screen.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';

class RestaurantListViewWidget extends StatelessWidget {
  final ExploreController exploreController;
  final ScrollController? scrollController;

  const RestaurantListViewWidget({
    super.key,
    required this.exploreController,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ExploreController>(
      builder: (controller) {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.filteredRestaurants == null ||
            controller.filteredRestaurants!.isEmpty) {
          return Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.restaurant_outlined,
                    size: 60,
                    color: Theme.of(context).disabledColor,
                  ),
                  const SizedBox(height: Dimensions.paddingSizeDefault),
                  Text(
                    'no_restaurants_found'.tr,
                    style: robotoMedium.copyWith(
                      color: Theme.of(context).disabledColor,
                      fontSize: Dimensions.fontSizeDefault,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await controller.getNearbyRestaurants(reload: true);
          },
          child: ListView.separated(
            controller: scrollController,
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            itemCount: controller.filteredRestaurants!.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: Dimensions.paddingSizeDefault),
            itemBuilder: (context, index) {
              final restaurant = controller.filteredRestaurants![index];
              return _buildRestaurantCard(context, restaurant, index);
            },
          ),
        );
      },
    );
  }

  Widget _buildRestaurantCard(
    BuildContext context,
    Restaurant restaurant,
    int index,
  ) {
    final distance = _calculateDistance(restaurant);
    final isOpen = restaurant.open == 1 && restaurant.active == true;

    return InkWell(
      onTap: () {
        exploreController.selectRestaurant(index);
        Get.toNamed(
          RouteHelper.getRestaurantRoute(restaurant.id),
          arguments: RestaurantScreen(restaurant: restaurant),
        );
      },
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      child: Container(
        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          border: Border.all(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Restaurant Logo
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                child: CustomImageWidget(
                  image: restaurant.logoFullUrl ?? '',
                  height: 70,
                  width: 70,
                  fit: BoxFit.cover,
                  isRestaurant: true,
                ),
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),

            // Restaurant Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and Status
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          restaurant.name ?? '',
                          style: robotoBold.copyWith(
                            fontSize: Dimensions.fontSizeDefault,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isOpen
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isOpen ? 'OPEN' : 'CLOSED',
                          style: robotoMedium.copyWith(
                            fontSize: 10,
                            color: isOpen ? Colors.green : Colors.red,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Rating
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        size: 16,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        restaurant.avgRating?.toStringAsFixed(1) ?? '0.0',
                        style: robotoMedium.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${restaurant.ratingCount ?? 0})',
                        style: robotoRegular.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          color: Theme.of(context).disabledColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Cuisines
                  if (restaurant.cuisineNames != null &&
                      restaurant.cuisineNames!.isNotEmpty)
                    Text(
                      restaurant.cuisineNames!
                          .take(3)
                          .map((c) => c.name)
                          .join(', '),
                      style: robotoRegular.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: Theme.of(context).disabledColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),

                  // Delivery Time, Distance & Free Delivery
                  Row(
                    children: [
                      // Delivery Time
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: isOpen ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        restaurant.deliveryTime ?? '30-40 min',
                        style: robotoRegular.copyWith(
                          fontSize: Dimensions.fontSizeExtraSmall,
                          color: Theme.of(context).disabledColor,
                        ),
                      ),
                      const SizedBox(width: Dimensions.paddingSizeSmall),

                      // Distance
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${distance.toStringAsFixed(1)} ${'km'.tr}',
                        style: robotoRegular.copyWith(
                          fontSize: Dimensions.fontSizeExtraSmall,
                          color: Theme.of(context).disabledColor,
                        ),
                      ),

                      // Free Delivery Badge
                      if (restaurant.freeDelivery == true) ...[
                        const SizedBox(width: Dimensions.paddingSizeSmall),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: Colors.green.withValues(alpha: 0.3),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            'FREE',
                            style: robotoMedium.copyWith(
                              fontSize: 10,
                              color: Colors.green,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Arrow Icon
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).disabledColor,
            ),
          ],
        ),
      ),
    );
  }

  double _calculateDistance(Restaurant restaurant) {
    try {
      final address = AddressHelper.getAddressFromSharedPref();
      if (address != null &&
          restaurant.latitude != null &&
          restaurant.longitude != null) {
        return Geolocator.distanceBetween(
              double.parse(restaurant.latitude!),
              double.parse(restaurant.longitude!),
              double.parse(address.latitude!),
              double.parse(address.longitude!),
            ) /
            1000;
      }
    } catch (e) {
      // Return default distance if calculation fails
    }
    return 0.0;
  }
}
