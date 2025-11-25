import 'dart:ui';
import 'package:godelivery_user/common/widgets/shared/images/custom_asset_image_widget.dart';
import 'package:godelivery_user/common/widgets/shared/layout/custom_distance_cliper_widget.dart';
import 'package:godelivery_user/common/widgets/adaptive/custom_favourite_widget.dart';
import 'package:godelivery_user/common/widgets/shared/buttons/custom_ink_well_widget.dart';
import 'package:godelivery_user/features/favourite/controllers/favourite_controller.dart';
import 'package:godelivery_user/features/home/widgets/icon_with_text_row_widget.dart';
import 'package:godelivery_user/features/restaurant/controllers/restaurant_controller.dart';
import 'package:godelivery_user/common/models/restaurant_model.dart';
import 'package:godelivery_user/helper/converters/date_converter.dart';
import 'package:godelivery_user/helper/ui/responsive_helper.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:godelivery_user/features/language/controllers/localization_controller.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/images.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:godelivery_user/util/app_colors.dart';
import 'package:godelivery_user/features/home/widgets/blurhash_image_widget.dart';
import 'package:godelivery_user/common/widgets/shared/feedback/custom_snackbar_widget.dart';
import 'package:godelivery_user/features/restaurant/screens/restaurant_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:animated_emoji/animated_emoji.dart';

class RestaurantsViewWidget extends StatelessWidget {
  final List<Restaurant?>? restaurants;
  const RestaurantsViewWidget({super.key, this.restaurants});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: Dimensions.webMaxWidth,
      child: restaurants != null ? restaurants!.isNotEmpty ? GridView.builder(
        shrinkWrap: true,
        itemCount: restaurants!.length,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: ResponsiveHelper.isMobile(context) ? 1 : ResponsiveHelper.isTab(context) ? 3 : 4,
          mainAxisSpacing: Dimensions.paddingSizeLarge,
          crossAxisSpacing: Dimensions.paddingSizeLarge,
          mainAxisExtent: 305,
        ),
        padding: EdgeInsets.symmetric(horizontal: !ResponsiveHelper.isDesktop(context) ? Dimensions.paddingSizeDefault : 0),
        itemBuilder: (context, index) {
          return RestaurantView(restaurant: restaurants![index]!);
        },
      ) : Center(child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: Dimensions.paddingSizeDefault),
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
              'no_restaurants_found'.tr,
              style: robotoMedium.copyWith(
                fontSize: Dimensions.fontSizeLarge,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'try_different_location'.tr,
              style: robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeDefault,
                color: Theme.of(context).hintColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      )) : GridView.builder(
        shrinkWrap: true,
        itemCount: 12,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: ResponsiveHelper.isMobile(context) ? 1 : ResponsiveHelper.isTab(context) ? 3 : 4,
          mainAxisSpacing: Dimensions.paddingSizeLarge,
          crossAxisSpacing: Dimensions.paddingSizeLarge,
          mainAxisExtent: 305,
        ),
        padding: EdgeInsets.symmetric(horizontal: !ResponsiveHelper.isDesktop(context) ? Dimensions.paddingSizeLarge : 0),
        itemBuilder: (context, index) {
          return const WebRestaurantShimmer();
        },
      ),

    );
  }
}

class RestaurantView extends StatelessWidget {
  final Restaurant restaurant;
  final Function()? onTap;
  final bool isSelected;
  const RestaurantView({super.key, required this.restaurant, this.onTap, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    bool isAvailable = restaurant.open == 1 && (restaurant.active ?? false);
    bool isRTL = Get.find<LocalizationController>().isLtr == false;
    double distance = 0.0;
    if (restaurant.latitude != null && restaurant.longitude != null) {
      try {
        distance = Get.find<RestaurantController>().getRestaurantDistance(
          LatLng(double.parse(restaurant.latitude!), double.parse(restaurant.longitude!)),
        );
      } catch (e) {
        distance = 0.0;
      }
    }
    String characteristics = '';
    if(restaurant.characteristics != null) {
      for (var v in restaurant.characteristics!) {
        characteristics = '$characteristics${characteristics.isNotEmpty ? ', ' : ''}$v';
      }
    }

    // Determine restaurant type/category
    String category = '';
    String restaurantName = restaurant.name ?? '';
    if(characteristics.toLowerCase().contains('pizza') || restaurantName.toLowerCase().contains('pizza')) {
      category = 'PIZZERIA';
    } else if(characteristics.toLowerCase().contains('burger') || restaurantName.toLowerCase().contains('burger')) {
      category = 'BURGERS';
    } else if(characteristics.toLowerCase().contains('coffee') || restaurantName.toLowerCase().contains('cafe')) {
      category = 'CAFE';
    } else {
      category = 'RESTAURANT';
    }

    return CustomInkWellWidget(
      onTap: onTap ?? () {
        if(restaurant.restaurantStatus == 1){
          Get.toNamed(RouteHelper.getRestaurantRoute(restaurant.id), arguments: RestaurantScreen(restaurant: restaurant));
        }else if(restaurant.restaurantStatus == 0){
          showCustomSnackBar('restaurant_is_not_available'.tr);
        }
      },
      radius: 20,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: isSelected ? Border.all(color: Theme.of(context).primaryColor, width: 2) : null,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Get.isDarkMode
                  ? Colors.black.withValues(alpha: 0.4)
                  : Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 0,
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section with Logo Overlay
            Container(
              height: 180,
              width: double.infinity,
              child: Stack(
                children: [
                  // Background image
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        BlurhashImageWidget(
                          imageUrl: '${restaurant.coverPhotoFullUrl}',
                          blurhash: restaurant.coverPhotoBlurhash,
                          fit: BoxFit.cover,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        // Subtle gradient overlay (bottom 20% only)
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.3),
                              ],
                              stops: const [0.8, 1.0], // Only bottom 20%
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Category label
                  Positioned(
                    top: 12,
                    left: isRTL ? null : 12,
                    right: isRTL ? 12 : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        category,
                        style: robotoBold.copyWith(
                          fontSize: 10,
                          color: Colors.black87,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),

                  // Logo in top right corner
                  Positioned(
                    top: 12,
                    right: isRTL ? null : 12,
                    left: isRTL ? 12 : null,
                    child: Container(
                      height: 50,
                      width: 50,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 10,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: BlurhashImageWidget(
                          imageUrl: '${restaurant.logoFullUrl}',
                          blurhash: restaurant.logoBlurhash,
                          fit: BoxFit.cover,
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    ),
                  ),

                  // Status bar at bottom with blur effect - always show
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Rating
                              if (restaurant.ratingCount != null && restaurant.ratingCount! > 0) ...[
                                Icon(
                                  Icons.star_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${restaurant.avgRating?.toStringAsFixed(1) ?? "0.0"}',
                                  style: robotoMedium.copyWith(
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '(${restaurant.ratingCount})',
                                  style: robotoRegular.copyWith(
                                    fontSize: 11,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],

                              // Open/Closed Status
                              Icon(
                                isAvailable ? Icons.access_time : Icons.lock_clock,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isAvailable
                                  ? 'Closes at ${restaurant.availableTimeEnds ?? "23:00"}'
                                  : 'Opens at ${restaurant.availableTimeStarts ?? "09:00"}',
                                style: robotoMedium.copyWith(
                                  fontSize: 11,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                ],
              ),
            ),

            // Content Section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Restaurant Name, Description and ETA
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left side: Name and Description
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                restaurant.name ?? '',
                                style: robotoMedium.copyWith(
                                  fontSize: Dimensions.fontSizeLarge,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (restaurant.shortDescription != null && restaurant.shortDescription!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  restaurant.shortDescription!,
                                  style: robotoRegular.copyWith(
                                    fontSize: Dimensions.fontSizeSmall,
                                    color: Theme.of(context).hintColor,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ] else if (characteristics.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  characteristics,
                                  style: robotoRegular.copyWith(
                                    fontSize: Dimensions.fontSizeSmall,
                                    color: Theme.of(context).hintColor,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Right side: ETA badge - green when open, red when closed
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isAvailable
                              ? AppColors.brandAccent.withValues(alpha: 0.1)
                              : AppColors.semanticError.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: isAvailable
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    restaurant.deliveryTime?.replaceAll('-min', '').replaceAll(' min', '') ?? '30-45',
                                    style: robotoMedium.copyWith(
                                      fontSize: Dimensions.fontSizeDefault,
                                      color: AppColors.brandAccent,
                                      height: 1.0,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  Text(
                                    'min'.tr,
                                    style: robotoRegular.copyWith(
                                      fontSize: Dimensions.fontSizeSmall,
                                      color: AppColors.brandAccent,
                                      height: 1.2,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              )
                            : AnimatedEmoji(
                                AnimatedEmojis.sleep,
                                size: 32,
                              ),
                        ),
                      ],
                    ),

                    // Separator line
                    Container(
                      height: 1,
                      color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                    ),

                    // Bottom Info Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left side: Delivery Cost and Rating
                        Row(
                          children: [
                            // Delivery Cost
                            if (restaurant.freeDelivery ?? false) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.local_shipping,
                                      size: 16,
                                      color: Colors.green,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'free_delivery'.tr,
                                      style: robotoMedium.copyWith(
                                        fontSize: Dimensions.fontSizeDefault,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                            ] else ...[
                              Icon(
                                Icons.delivery_dining,
                                size: 18,
                                color: Theme.of(context).hintColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '₪${restaurant.deliveryFee?.toStringAsFixed(0) ?? restaurant.minimumShippingCharge?.toStringAsFixed(0) ?? "5"}',
                                style: robotoRegular.copyWith(
                                  fontSize: Dimensions.fontSizeDefault,
                                  color: Theme.of(context).hintColor,
                                ),
                              ),
                              const SizedBox(width: 16),
                            ],

                            // Rating
                            if (restaurant.ratingCount != null && restaurant.ratingCount! > 0) ...[
                              Icon(
                                Icons.star_rounded,
                                size: 18,
                                color: const Color(0xFFFFB800),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                restaurant.avgRating?.toStringAsFixed(1) ?? '0.0',
                                style: robotoMedium.copyWith(
                                  fontSize: Dimensions.fontSizeDefault,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '(${restaurant.ratingCount})',
                                style: robotoRegular.copyWith(
                                  fontSize: Dimensions.fontSizeSmall,
                                  color: Theme.of(context).hintColor,
                                ),
                              ),
                            ] else ...[
                              Icon(
                                Icons.star_border_rounded,
                                size: 18,
                                color: Theme.of(context).hintColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'new'.tr,
                                style: robotoRegular.copyWith(
                                  fontSize: Dimensions.fontSizeDefault,
                                  color: Theme.of(context).hintColor,
                                ),
                              ),
                            ],
                          ],
                        ),

                        // Right side: Distance
                        Row(
                          children: [
                            Icon(
                              Icons.near_me,
                              size: 16,
                              color: Theme.of(context).hintColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${distance.toStringAsFixed(1)} km',
                              style: robotoRegular.copyWith(
                                fontSize: Dimensions.fontSizeDefault,
                                color: Theme.of(context).hintColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WebRestaurantShimmer extends StatelessWidget {
  final bool isDineInRestaurant;
  const WebRestaurantShimmer({super.key, this.isDineInRestaurant = false});

  @override
  Widget build(BuildContext context) {
    final shimmerColor = Theme.of(context).hintColor.withValues(alpha: 0.1);
    final shimmerHighlight = Theme.of(context).hintColor.withValues(alpha: 0.15);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Get.isDarkMode
                ? Colors.black.withValues(alpha: 0.4)
                : Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            child: Shimmer(
              color: shimmerHighlight,
              child: Container(
                height: 180,
                width: double.infinity,
                color: shimmerColor,
              ),
            ),
          ),

          // Content placeholder
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Title and description
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Shimmer(
                        color: shimmerHighlight,
                        child: Container(
                          height: 16,
                          width: 140,
                          decoration: BoxDecoration(
                            color: shimmerColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Shimmer(
                        color: shimmerHighlight,
                        child: Container(
                          height: 12,
                          width: 200,
                          decoration: BoxDecoration(
                            color: shimmerColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Separator
                  Container(
                    height: 1,
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                  ),

                  // Bottom info
                  Row(
                    children: [
                      Shimmer(
                        color: shimmerHighlight,
                        child: Container(
                          height: 12,
                          width: 60,
                          decoration: BoxDecoration(
                            color: shimmerColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Shimmer(
                        color: shimmerHighlight,
                        child: Container(
                          height: 12,
                          width: 50,
                          decoration: BoxDecoration(
                            color: shimmerColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Shimmer(
                        color: shimmerHighlight,
                        child: Container(
                          height: 12,
                          width: 45,
                          decoration: BoxDecoration(
                            color: shimmerColor,
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
}