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
                      return Padding(
                        padding: EdgeInsets.only(left: (ResponsiveHelper.isDesktop(context) && index == 0 && Get.find<LocalizationController>().isLtr) ? 0 : Dimensions.paddingSizeDefault),
                        child: Container(
                          height: 185, width: ResponsiveHelper.isDesktop(context) ? 253 : MediaQuery.of(context).size.width * 0.7,
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
                          child: CustomInkWellWidget(
                            onTap: () => Get.toNamed(RouteHelper.getRestaurantRoute(restaurantList[index].id),
                              arguments: RestaurantScreen(restaurant: restaurantList[index]),
                            ),
                            radius: Dimensions.radiusLarge,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  height: 95, width: ResponsiveHelper.isDesktop(context) ? 253 : MediaQuery.of(context).size.width * 0.7,
                                  decoration: const BoxDecoration(
                                    borderRadius: BorderRadius.only(topLeft: Radius.circular(Dimensions.radiusLarge), topRight: Radius.circular(Dimensions.radiusLarge)),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(Dimensions.radiusLarge), topRight: Radius.circular(Dimensions.radiusLarge)),
                                    child: Stack(
                                      children: [
                                        SizedBox(
                                          height: 95,
                                          width: ResponsiveHelper.isDesktop(context) ? 253 : MediaQuery.of(context).size.width * 0.7,
                                          child: BlurhashImageWidget(
                                            imageUrl: '${restaurantList[index].coverPhotoFullUrl}',
                                            blurhash: restaurantList[index].coverPhotoBlurhash,
                                            fit: BoxFit.cover,
                                            borderRadius: const BorderRadius.only(topLeft: Radius.circular(Dimensions.radiusLarge), topRight: Radius.circular(Dimensions.radiusLarge)),
                                          ),
                                        ),

                                        !isAvailable ? Positioned(
                                          top: 0, left: 0, right: 0, bottom: 0,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius: const BorderRadius.only(topLeft: Radius.circular(Dimensions.radiusLarge), topRight: Radius.circular(Dimensions.radiusLarge)),
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Colors.black.withValues(alpha: 0.4),
                                                  Colors.black.withValues(alpha: 0.6),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ) : const SizedBox(),
                                      ],
                                    ),
                                  ),
                                ),

                                !isAvailable ? Positioned(top: 35, left: 0, right: 0, child: Center(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).cardColor.withValues(alpha: 0.95),
                                      borderRadius: BorderRadius.circular(30),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.2),
                                          blurRadius: 10,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.schedule_rounded, size: 14, color: Theme.of(context).colorScheme.error),
                                        const SizedBox(width: 6),
                                        Text('closed_now'.tr.toUpperCase(),
                                          style: robotoMedium.copyWith(
                                            color: Theme.of(context).colorScheme.error,
                                            fontSize: 11,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )) : const SizedBox(),

                                Positioned(
                                  top: 100, left: 85, right: 0,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(height: characteristics == '' ? Dimensions.paddingSizeSmall : 0),

                                      Text(restaurantList[index].name!, overflow: TextOverflow.ellipsis, maxLines: 1, style: robotoBold),

                                      Text(
                                        characteristics,
                                        overflow: TextOverflow.ellipsis, maxLines: 1,
                                        style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor),
                                      ),
                                    ],
                                  ),
                                ),


                                Positioned(
                                  bottom: 15, left: 0, right: 0,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [

                                      restaurantList[index].ratingCount! > 0 ? IconWithTextRowWidget(
                                        icon: Icons.star_border,
                                        text: restaurantList[index].avgRating!.toStringAsFixed(1),
                                        style: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall),
                                      ) : const SizedBox(),
                                      SizedBox(width: restaurantList[index].ratingCount! > 0 ? Dimensions.paddingSizeDefault : 0),

                                      restaurantList[index].freeDelivery! ? ImageWithTextRowWidget(
                                        widget: Image.asset(Images.deliveryIcon, height: 20, width: 20),
                                        text: 'free'.tr,
                                        style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
                                      ): const SizedBox(),
                                      restaurantList[index].freeDelivery! ? const SizedBox(width: Dimensions.paddingSizeDefault) : const SizedBox(),

                                      IconWithTextRowWidget(
                                        icon: Icons.access_time_outlined,
                                        text: '${restaurantList[index].deliveryTime}',
                                        style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.bodyLarge!.color),
                                      ),

                                    ],
                                  ),
                                ),


                                Positioned(
                                  top: Dimensions.paddingSizeSmall, right: Dimensions.paddingSizeSmall,
                                  child: GetBuilder<FavouriteController>(builder: (favouriteController) {
                                    bool isWished = favouriteController.wishRestIdList.contains(restaurantList[index].id);
                                      return CustomFavouriteWidget(
                                        isWished: isWished,
                                        isRestaurant: true,
                                        restaurant: restaurantList[index],
                                      );
                                    }
                                  ),
                                ),

                                Positioned(
                                  top: 10, right: 10,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).cardColor.withValues(alpha: 0.95),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.15),
                                          blurRadius: 8,
                                          spreadRadius: 0,
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.location_on_rounded,
                                          size: 12,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          '${restController.getRestaurantDistance(
                                            LatLng(double.parse(restaurantList[index].latitude!), double.parse(restaurantList[index].longitude!)),
                                          ).toStringAsFixed(1)} km',
                                          style: robotoBold.copyWith(
                                            fontSize: 11,
                                            color: Theme.of(context).textTheme.bodyLarge!.color,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                Positioned(
                                  top: 70, left: Dimensions.paddingSizeSmall,
                                  child: Container(
                                    height: 68, width: 68,
                                    padding: const EdgeInsets.all(2),
                                    decoration:  BoxDecoration(
                                      color: Theme.of(context).cardColor,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Get.isDarkMode
                                              ? Colors.black.withValues(alpha: 0.3)
                                              : Colors.grey.withValues(alpha: 0.2),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: BlurhashImageWidget(
                                      imageUrl: '${restaurantList[index].logoFullUrl}',
                                      blurhash: restaurantList[index].logoBlurhash,
                                      fit: BoxFit.cover,
                                      borderRadius: BorderRadius.circular(14),
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

