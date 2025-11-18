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
import 'package:godelivery_user/features/home/widgets/blurhash_image_widget.dart';
import 'package:godelivery_user/common/widgets/shared/feedback/custom_snackbar_widget.dart';
import 'package:godelivery_user/features/restaurant/screens/restaurant_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

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
          mainAxisExtent: 260,
        ),
        padding: EdgeInsets.symmetric(horizontal: !ResponsiveHelper.isDesktop(context) ? Dimensions.paddingSizeDefault : 0),
        itemBuilder: (context, index) {
          return RestaurantView(restaurant: restaurants![index]!);
        },
      ) : Center(child: Padding(
        padding: const EdgeInsets.only(top: Dimensions.paddingSizeOverLarge),
        child: Column(
          children: [
            const SizedBox(height: 110),
            const CustomAssetImageWidget(Images.emptyRestaurant, height: 80, width: 80),
            const SizedBox(height: Dimensions.paddingSizeExtraSmall),
            Text('there_is_no_restaurant'.tr, style: robotoMedium.copyWith(color: Theme.of(context).disabledColor)),
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
          mainAxisExtent: 260,
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
    bool isAvailable = restaurant.open == 1 && restaurant.active!;
    bool isRTL = Get.find<LocalizationController>().isLtr == false;
    double distance = Get.find<RestaurantController>().getRestaurantDistance(
      LatLng(double.parse(restaurant.latitude!), double.parse(restaurant.longitude!)),
    );
    String characteristics = '';
    if(restaurant.characteristics != null) {
      for (var v in restaurant.characteristics!) {
        characteristics = '$characteristics${characteristics.isNotEmpty ? ', ' : ''}$v';
      }
    }

    // Determine restaurant type/category
    String category = '';
    if(characteristics.toLowerCase().contains('pizza') || restaurant.name!.toLowerCase().contains('pizza')) {
      category = 'PIZZERIA';
    } else if(characteristics.toLowerCase().contains('burger') || restaurant.name!.toLowerCase().contains('burger')) {
      category = 'BURGERS';
    } else if(characteristics.toLowerCase().contains('coffee') || restaurant.name!.toLowerCase().contains('cafe')) {
      category = 'CAFE';
    } else {
      category = 'RESTAURANT';
    }

    return Container(
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
      child: CustomInkWellWidget(
        onTap: onTap ?? () {
          if(restaurant.restaurantStatus == 1){
            Get.toNamed(RouteHelper.getRestaurantRoute(restaurant.id), arguments: RestaurantScreen(restaurant: restaurant));
          }else if(restaurant.restaurantStatus == 0){
            showCustomSnackBar('restaurant_is_not_available'.tr);
          }
        },
        radius: 20,
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
                        // Dark gradient overlay
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.3),
                                Colors.black.withValues(alpha: 0.5),
                              ],
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

                  // Logo and restaurant name in center
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 60,
                          width: 60,
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
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          restaurant.name ?? '',
                          style: robotoBold.copyWith(
                            fontSize: Dimensions.fontSizeLarge,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Opening hours or closed status at bottom
                  Positioned(
                    bottom: 8,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isAvailable ? Icons.access_time : Icons.lock_clock,
                              size: 12,
                              color: isAvailable ? Colors.white : Colors.redAccent,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isAvailable
                                ? restaurant.deliveryTime ?? '30-45 min'
                                : 'closed'.tr,
                              style: robotoRegular.copyWith(
                                fontSize: 11,
                                color: isAvailable ? Colors.white : Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Favorite button
                  Positioned(
                    top: 12,
                    right: isRTL ? null : 12,
                    left: isRTL ? 12 : null,
                    child: GetBuilder<FavouriteController>(builder: (favouriteController) {
                      bool isWished = favouriteController.wishRestIdList.contains(restaurant.id);
                      return Container(
                        height: 36,
                        width: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: CustomFavouriteWidget(
                          isWished: isWished,
                          isRestaurant: true,
                          restaurant: restaurant,
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            // Content Section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Restaurant Name and Description
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          restaurant.name ?? '',
                          style: robotoMedium.copyWith(
                            fontSize: Dimensions.fontSizeDefault,
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

                    // Bottom Info Row
                    Directionality(
                      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Delivery time
                          Row(
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                size: 14,
                                color: Theme.of(context).hintColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                restaurant.deliveryTime ?? '30-45',
                                style: robotoRegular.copyWith(
                                  fontSize: Dimensions.fontSizeSmall,
                                  color: Theme.of(context).hintColor,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'min'.tr,
                                style: robotoRegular.copyWith(
                                  fontSize: Dimensions.fontSizeExtraSmall,
                                  color: Theme.of(context).hintColor,
                                ),
                              ),
                            ],
                          ),

                          // Status
                          if (!isAvailable)
                            Text(
                              'closed'.tr,
                              style: robotoMedium.copyWith(
                                fontSize: Dimensions.fontSizeSmall,
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),

                          // Rating with reviews
                          if (restaurant.ratingCount! > 0)
                            Row(
                              children: [
                                Text(
                                  restaurant.avgRating!.toStringAsFixed(1),
                                  style: robotoMedium.copyWith(
                                    fontSize: Dimensions.fontSizeSmall,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '(${restaurant.ratingCount})',
                                  style: robotoRegular.copyWith(
                                    fontSize: Dimensions.fontSizeExtraSmall,
                                    color: Theme.of(context).hintColor,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.star_rounded,
                                  size: 16,
                                  color: const Color(0xFFFFB800),
                                ),
                              ],
                            ),

                          // Free delivery badge or distance
                          if (restaurant.freeDelivery!)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.local_shipping_outlined,
                                    size: 14,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'free'.tr.toUpperCase(),
                                    style: robotoMedium.copyWith(
                                      fontSize: Dimensions.fontSizeSmall,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 14,
                                  color: Theme.of(context).hintColor,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '${distance.toStringAsFixed(1)} km',
                                  style: robotoRegular.copyWith(
                                    fontSize: Dimensions.fontSizeSmall,
                                    color: Theme.of(context).hintColor,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
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
    return  Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
        color: Theme.of(context).shadowColor,
        border: Border.all(color: Theme.of(context).shadowColor),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        ),
        child: Stack(clipBehavior: Clip.none, children: [

            ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(Dimensions.radiusDefault), topRight: Radius.circular(Dimensions.radiusDefault)),
              child: Shimmer(
                child: Container(
                  height: 93, width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).shadowColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(Dimensions.radiusDefault),
                      topRight: Radius.circular(Dimensions.radiusDefault),
                    ),
                  ),
                ),
              ),
            ),

            Positioned(
              top: 60, left: 10, right: isDineInRestaurant ? null : 0,
              child: Column(
                crossAxisAlignment: isDineInRestaurant ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    height: 70, width: 70,
                    decoration:  BoxDecoration(
                      color: Theme.of(context).shadowColor,
                      border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                      borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                    ),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeSmall),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                    child: Shimmer(
                      child: Container(height: 15, width: 170, decoration: BoxDecoration(borderRadius: BorderRadius.circular(Dimensions.radiusSmall), color: Theme.of(context).shadowColor)),
                    ),
                  ),
                  const SizedBox(height: 10),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                    child: Shimmer(
                      child: Container(height: 10, width: 220, decoration: BoxDecoration(borderRadius: BorderRadius.circular(Dimensions.radiusSmall), color: Theme.of(context).shadowColor)),
                    ),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconWithTextRowWidget(
                        icon: Icons.star_border, text: '0.0',
                        color: Theme.of(context).shadowColor,
                        style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).shadowColor),
                      ),

                      Padding(
                        padding: const EdgeInsets.only(left: Dimensions.paddingSizeDefault),
                        child: ImageWithTextRowWidget(
                          widget: Image.asset(Images.deliveryIcon, height: 20, width: 20, color: Theme.of(context).shadowColor),
                          text: 'free'.tr,
                          style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).shadowColor),
                        ),
                      ),
                      const SizedBox(width: Dimensions.paddingSizeDefault),

                      IconWithTextRowWidget(
                        icon: Icons.access_time_outlined, text: '10-30 min',
                        color: Theme.of(context).shadowColor,
                        style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).shadowColor),
                      ),

                    ],
                  ),
                ],
              ),
            ),

            Positioned(
              top: Dimensions.paddingSizeSmall, right: Dimensions.paddingSizeSmall,
              child: Icon(
                Icons.favorite,  size: 20,
                color: Theme.of(context).shadowColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}