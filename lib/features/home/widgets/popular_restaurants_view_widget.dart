import 'package:godelivery_user/common/widgets/shared/layout/custom_distance_cliper_widget.dart';
import 'package:godelivery_user/common/widgets/adaptive/custom_favourite_widget.dart';
import 'package:godelivery_user/common/widgets/shared/buttons/custom_ink_well_widget.dart';
import 'package:godelivery_user/features/home/widgets/arrow_icon_button_widget.dart';
import 'package:godelivery_user/features/home/widgets/icon_with_text_row_widget.dart';
import 'package:godelivery_user/features/language/controllers/localization_controller.dart';
import 'package:godelivery_user/features/restaurant/controllers/restaurant_controller.dart';
import 'package:godelivery_user/common/models/restaurant_model.dart';
import 'package:godelivery_user/features/favourite/controllers/favourite_controller.dart';
import 'package:godelivery_user/helper/ui/responsive_helper.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/images.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:godelivery_user/features/home/widgets/blurhash_image_widget.dart';
import 'package:godelivery_user/features/restaurant/screens/restaurant_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class PopularRestaurantsViewWidget extends StatelessWidget {
  final bool isRecentlyViewed;
  const PopularRestaurantsViewWidget({super.key, this.isRecentlyViewed = false});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<RestaurantController>(builder: (restController) {
      List<Restaurant>? restaurantList = isRecentlyViewed ? restController.recentlyViewedRestaurantList : restController.popularRestaurantList;
        return (restaurantList != null && restaurantList.isEmpty) ? const SizedBox() : Padding(
          padding: EdgeInsets.symmetric(vertical: ResponsiveHelper.isMobile(context) ? Dimensions.paddingSizeDefault : Dimensions.paddingSizeLarge),
          child: SizedBox(
            height: 245, width: Dimensions.webMaxWidth,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                ResponsiveHelper.isDesktop(context) ? Padding(
                  padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeLarge),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(isRecentlyViewed ? 'recently_viewed_restaurants'.tr : 'popular_restaurants'.tr,
                      style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge, fontWeight: FontWeight.w600),
                    ),

                    ArrowIconButtonWidget(onTap: () {
                      Get.toNamed(RouteHelper.getAllRestaurantRoute(isRecentlyViewed ? 'recently_viewed' : 'popular'));
                    }),
                  ]),
                ) : Padding(
                  padding: const EdgeInsets.only(left: Dimensions.paddingSizeDefault, right: Dimensions.paddingSizeDefault, bottom: Dimensions.paddingSizeLarge),
                  child: Text(isRecentlyViewed ? 'recently_viewed_restaurants'.tr : 'popular_restaurants'.tr,
                    style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge, fontWeight: FontWeight.w600),
                  ),
                ),


               restaurantList != null ? SizedBox(
                  height: 185,
                  child: ListView.builder(
                    itemCount: restaurantList.length,
                    padding: EdgeInsets.only(right: ResponsiveHelper.isMobile(context) ? Dimensions.paddingSizeDefault : 0),
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      bool isAvailable = restaurantList[index].open == 1 && restaurantList[index].active!;
                      String characteristics = '';
                      if(restaurantList[index].characteristics != null) {
                        for (var v in restaurantList[index].characteristics!) {
                          characteristics = '$characteristics${characteristics.isNotEmpty ? ', ' : ''}$v';
                        }
                      }
                      double distance = restController.getRestaurantDistance(
                        LatLng(double.parse(restaurantList[index].latitude!), double.parse(restaurantList[index].longitude!)),
                      );

                      return Padding(
                        padding: EdgeInsets.only(left: (ResponsiveHelper.isDesktop(context) && index == 0 && Get.find<LocalizationController>().isLtr) ? 0 : Dimensions.paddingSizeDefault),
                        child: CustomInkWellWidget(
                          onTap: () => Get.toNamed(RouteHelper.getRestaurantRoute(restaurantList[index].id),
                            arguments: RestaurantScreen(restaurantId: restaurantList[index].id!),
                          ),
                          radius: Dimensions.radiusLarge,
                          child: Container(
                            height: 185, width: ResponsiveHelper.isDesktop(context) ? 280 : MediaQuery.of(context).size.width * 0.75,
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                              boxShadow: [
                                BoxShadow(
                                  color: Get.isDarkMode
                                      ? Colors.black.withValues(alpha: 0.3)
                                      : Colors.grey.withValues(alpha: 0.15),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Cover Image Section with Logo
                                Container(
                                  height: 90,
                                  child: Stack(
                                    children: [
                                      // Cover Image
                                      ClipRRect(
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(Dimensions.radiusLarge),
                                          topRight: Radius.circular(Dimensions.radiusLarge)
                                        ),
                                        child: SizedBox(
                                          height: 90,
                                          width: double.infinity,
                                          child: BlurhashImageWidget(
                                            imageUrl: '${restaurantList[index].coverPhotoFullUrl}',
                                            blurhash: restaurantList[index].coverPhotoBlurhash,
                                            fit: BoxFit.cover,
                                            borderRadius: const BorderRadius.only(
                                              topLeft: Radius.circular(Dimensions.radiusLarge),
                                              topRight: Radius.circular(Dimensions.radiusLarge)
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Gradient overlay if closed
                                      if (!isAvailable)
                                        Positioned(
                                          top: 0, left: 0, right: 0, bottom: 0,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius: const BorderRadius.only(
                                                topLeft: Radius.circular(Dimensions.radiusLarge),
                                                topRight: Radius.circular(Dimensions.radiusLarge)
                                              ),
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Colors.black.withValues(alpha: 0.2),
                                                  Colors.black.withValues(alpha: 0.4),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),

                                      // Logo in top right corner
                                      Positioned(
                                        top: 10,
                                        right: 10,
                                        child: Container(
                                          height: 45,
                                          width: 45,
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.2),
                                                blurRadius: 8,
                                                spreadRadius: 0,
                                              ),
                                            ],
                                          ),
                                          child: ClipOval(
                                            child: BlurhashImageWidget(
                                              imageUrl: '${restaurantList[index].logoFullUrl}',
                                              blurhash: restaurantList[index].logoBlurhash,
                                              fit: BoxFit.cover,
                                              borderRadius: BorderRadius.circular(22.5),
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
                                    padding: const EdgeInsets.all(10),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Restaurant Name and Description
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                restaurantList[index].name ?? '',
                                                style: robotoMedium.copyWith(
                                                  fontSize: Dimensions.fontSizeDefault,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (restaurantList[index].shortDescription != null && restaurantList[index].shortDescription!.isNotEmpty) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  restaurantList[index].shortDescription!,
                                                  style: robotoRegular.copyWith(
                                                    fontSize: Dimensions.fontSizeSmall,
                                                    color: Theme.of(context).hintColor,
                                                  ),
                                                  maxLines: 1,
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
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),

                                        // Separator
                                        Container(
                                          height: 1,
                                          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                                          margin: const EdgeInsets.only(bottom: 6, top: 4),
                                        ),

                                        // Bottom Stats Row
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            // Left: ETA and Delivery
                                            Row(
                                              children: [
                                                // ETA
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    restaurantList[index].deliveryTime?.replaceAll('-min', ' min') ?? '30-45 min',
                                                    style: robotoMedium.copyWith(
                                                      fontSize: Dimensions.fontSizeSmall,
                                                      color: Theme.of(context).primaryColor,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),

                                                // Delivery Cost
                                                if (restaurantList[index].freeDelivery!) ...[
                                                  Icon(
                                                    Icons.local_shipping,
                                                    size: 14,
                                                    color: Colors.green,
                                                  ),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    'free'.tr,
                                                    style: robotoMedium.copyWith(
                                                      fontSize: Dimensions.fontSizeSmall,
                                                      color: Colors.green,
                                                    ),
                                                  ),
                                                ] else ...[
                                                  Icon(
                                                    Icons.delivery_dining,
                                                    size: 14,
                                                    color: Theme.of(context).hintColor,
                                                  ),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    '₪${restaurantList[index].deliveryFee?.toStringAsFixed(0) ?? restaurantList[index].minimumShippingCharge?.toStringAsFixed(0) ?? "5"}',
                                                    style: robotoRegular.copyWith(
                                                      fontSize: Dimensions.fontSizeSmall,
                                                      color: Theme.of(context).hintColor,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),

                                            // Right: Distance
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.near_me,
                                                  size: 12,
                                                  color: Theme.of(context).hintColor,
                                                ),
                                                const SizedBox(width: 2),
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
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ) : const PopularRestaurantShimmer()
              ],
            ),

          ),
        );
      }
    );
  }
}


class PopularRestaurantShimmer extends StatelessWidget {
  const PopularRestaurantShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 185,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.only(left: ResponsiveHelper.isMobile(context) ? Dimensions.paddingSizeDefault : 0, right: ResponsiveHelper.isMobile(context) ? Dimensions.paddingSizeDefault : 0),
        itemCount: 7,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.only(left: index == 0 ? 0 : Dimensions.paddingSizeDefault),
            height: 185, width: 253,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              border: Border.all(color: Theme.of(context).shadowColor),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 85, width: 253,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(Dimensions.radiusDefault), topRight: Radius.circular(Dimensions.radiusDefault)),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(Dimensions.radiusDefault), topRight: Radius.circular(Dimensions.radiusDefault)),
                    child: Shimmer(
                      child: Container(
                        height: 85, width: 253,
                        color: Theme.of(context).shadowColor,
                      ),
                    ),
                  ),
                ),

                Positioned(
                  top: 90, left: 10, right: 0,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                      child: Shimmer(
                        child: Container(height: 15, width: 100, decoration: BoxDecoration(borderRadius: BorderRadius.circular(Dimensions.radiusSmall), color: Theme.of(context).shadowColor)),
                      ),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeSmall),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                      child: Shimmer(
                        child: Container(height: 10, width: 120, decoration: BoxDecoration(borderRadius: BorderRadius.circular(Dimensions.radiusSmall), color: Theme.of(context).shadowColor)),
                      ),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeSmall),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                      child: Shimmer(
                        child: Container(height: 12, width: 150, decoration: BoxDecoration(borderRadius: BorderRadius.circular(Dimensions.radiusSmall), color: Theme.of(context).shadowColor)),
                      ),
                    ),

                  ]),
                ),
              ]
            ),
          );
        },
      ),
    );
  }
}

