import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:godelivery_user/common/models/restaurant_model.dart';
import 'package:godelivery_user/common/widgets/custom_favourite_widget.dart';
import 'package:godelivery_user/common/widgets/custom_image_widget.dart';
import 'package:godelivery_user/common/widgets/custom_snackbar_widget.dart';
import 'package:godelivery_user/features/favourite/controllers/favourite_controller.dart';
import 'package:godelivery_user/helper/address_helper.dart';
import 'package:godelivery_user/helper/route_helper.dart';
import 'package:godelivery_user/features/restaurant/screens/restaurant_screen.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';

class RestaurantBottomSheetWidget extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback onClose;

  const RestaurantBottomSheetWidget({
    super.key,
    required this.restaurant,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final distance = _calculateDistance();
    final isOpen = restaurant.open == 1 && restaurant.active == true;

    return Container(
      margin: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            margin: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).disabledColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row (Logo, Info, Actions)
                Row(
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
                          height: 80,
                          width: 80,
                          fit: BoxFit.cover,
                          isRestaurant: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: Dimensions.paddingSizeDefault),

                    // Restaurant Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name
                          Text(
                            restaurant.name ?? '',
                            style: robotoBold.copyWith(
                              fontSize: Dimensions.fontSizeLarge,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),

                          // Address
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: Theme.of(context).disabledColor,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  restaurant.address ?? 'no_address_found'.tr,
                                  style: robotoRegular.copyWith(
                                    fontSize: Dimensions.fontSizeSmall,
                                    color: Theme.of(context).disabledColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
                                size: 18,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                restaurant.avgRating?.toStringAsFixed(1) ?? '0.0',
                                style: robotoBold.copyWith(
                                  fontSize: Dimensions.fontSizeDefault,
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
                        ],
                      ),
                    ),

                    // Action Buttons
                    Column(
                      children: [
                        // Favorite Button
                        GetBuilder<FavouriteController>(
                          builder: (favouriteController) {
                            bool isWished = favouriteController.wishRestIdList
                                .contains(restaurant.id);
                            return CustomFavouriteWidget(
                              isWished: isWished,
                              isRestaurant: true,
                              restaurant: restaurant,
                            );
                          },
                        ),
                        const SizedBox(height: Dimensions.paddingSizeSmall),

                        // Directions Button
                        InkWell(
                          onTap: () async {
                            String url =
                                'https://www.google.com/maps/dir/?api=1&destination=${restaurant.latitude},${restaurant.longitude}&mode=d';
                            if (await canLaunchUrlString(url)) {
                              await launchUrlString(
                                url,
                                mode: LaunchMode.externalApplication,
                              );
                            } else {
                              showCustomSnackBar('unable_to_launch_google_map'.tr);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                            ),
                            child: Icon(
                              Icons.directions,
                              color: Theme.of(context).primaryColor,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: Dimensions.paddingSizeDefault),

                // Cuisines
                if (restaurant.cuisineNames != null &&
                    restaurant.cuisineNames!.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: restaurant.cuisineNames!.map((cuisine) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Dimensions.paddingSizeSmall,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          cuisine.name ?? '',
                          style: robotoMedium.copyWith(
                            fontSize: Dimensions.fontSizeExtraSmall,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: Dimensions.paddingSizeDefault),

                // Details Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Status
                    _buildDetailItem(
                      context: context,
                      icon: Icons.access_time,
                      label: isOpen ? 'open_now'.tr : 'closed_now'.tr,
                      color: isOpen ? Colors.green : Colors.red,
                    ),

                    // Delivery Time
                    _buildDetailItem(
                      context: context,
                      icon: Icons.delivery_dining,
                      label: restaurant.deliveryTime ?? '30-40 min',
                      color: Theme.of(context).primaryColor,
                    ),

                    // Distance
                    _buildDetailItem(
                      context: context,
                      icon: Icons.location_on,
                      label: '${distance.toStringAsFixed(1)} ${'km'.tr}',
                      color: Theme.of(context).primaryColor,
                    ),
                  ],
                ),
                const SizedBox(height: Dimensions.paddingSizeDefault),

                // View Restaurant Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Get.toNamed(
                        RouteHelper.getRestaurantRoute(restaurant.id),
                        arguments: RestaurantScreen(restaurant: restaurant),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(
                        vertical: Dimensions.paddingSizeDefault,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                      ),
                    ),
                    child: Text(
                      'view_restaurant'.tr,
                      style: robotoBold.copyWith(
                        color: Colors.white,
                        fontSize: Dimensions.fontSizeDefault,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: robotoMedium.copyWith(
            fontSize: Dimensions.fontSizeSmall,
            color: Theme.of(context).textTheme.bodyMedium!.color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  double _calculateDistance() {
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
