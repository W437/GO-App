import 'package:godelivery_user/common/widgets/adaptive/custom_favourite_widget.dart';
import 'package:godelivery_user/common/widgets/shared/buttons/custom_ink_well_widget.dart';
import 'package:godelivery_user/features/favourite/controllers/favourite_controller.dart';
import 'package:godelivery_user/features/home/widgets/icon_with_text_row_widget.dart';
import 'package:godelivery_user/features/home/widgets/overflow_container_widget.dart';
import 'package:godelivery_user/features/restaurant/controllers/restaurant_controller.dart';
import 'package:godelivery_user/features/splash/controllers/theme_controller.dart';
import 'package:godelivery_user/common/models/restaurant_model.dart';
import 'package:godelivery_user/helper/ui/responsive_helper.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/images.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:godelivery_user/features/home/widgets/blurhash_image_widget.dart';
import 'package:godelivery_user/common/widgets/adaptive/not_available_widget.dart';
import 'package:godelivery_user/features/restaurant/screens/restaurant_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class RestaurantsCardWidget extends StatelessWidget {
  final Restaurant restaurant;
  final bool? isNewOnGO;
  const RestaurantsCardWidget({super.key, this.isNewOnGO, required this.restaurant});


  @override
  Widget build(BuildContext context) {
    bool isAvailable = restaurant.open == 1 && restaurant.active! ;
    double distance = Get.find<RestaurantController>().getRestaurantDistance(
      LatLng(double.parse(restaurant.latitude!), double.parse(restaurant.longitude!)),
    );
    String characteristics = '';
    if(restaurant.characteristics != null) {
      for (var v in restaurant.characteristics!) {
        characteristics = '$characteristics${characteristics.isNotEmpty ? ', ' : ''}$v';
      }
    }

    return Stack(
      children: [
        CustomInkWellWidget(
          onTap: () {
            Get.toNamed(
              RouteHelper.getRestaurantRoute(restaurant.id),
              arguments: RestaurantScreen(restaurant: restaurant),
            );
          },
          radius: Dimensions.radiusLarge,
          child: Container(
            width: isNewOnGO! ? ResponsiveHelper.isMobile(context) ? 350 : 380  : ResponsiveHelper.isMobile(context) ? 330: 355,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
              boxShadow: [
                BoxShadow(
                  color: Get.isDarkMode
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.grey.withValues(alpha: 0.12),
                  spreadRadius: 0,
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Row(children: [
                      Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            height: isNewOnGO! ? 95 : 65, width: isNewOnGO! ? 95 : 65,
                            decoration:  BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(isNewOnGO! ? 20 : 16),
                              boxShadow: [
                                BoxShadow(
                                  color: Get.isDarkMode
                                      ? Colors.black.withValues(alpha: 0.2)
                                      : Colors.grey.withValues(alpha: 0.15),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(isNewOnGO! ? 17 : 13),
                              child: Stack(
                                children: [
                                  BlurhashImageWidget(
                                    imageUrl: '${restaurant.logoFullUrl}',
                                    blurhash: restaurant.logoBlurhash,
                                    fit: BoxFit.cover,
                                    borderRadius: BorderRadius.circular(isNewOnGO! ? 17 : 13),
                                  ),
                                  if (!isAvailable)
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(isNewOnGO! ? 17 : 13),
                                      ),
                                      child: Center(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).cardColor.withValues(alpha: 0.9),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            'closed_now'.tr.toUpperCase(),
                                            style: robotoMedium.copyWith(
                                              fontSize: 8,
                                              color: Theme.of(context).colorScheme.error,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: Dimensions.paddingSizeSmall),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              restaurant.name!,
                              overflow: TextOverflow.ellipsis, maxLines: 1,
                              style: robotoMedium.copyWith(
                                fontSize: isNewOnGO! ? Dimensions.fontSizeLarge : Dimensions.fontSizeDefault,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: isNewOnGO! ? Dimensions.paddingSizeSmall : Dimensions.paddingSizeExtraSmall),

                            (restaurant.shortDescription != null && restaurant.shortDescription!.isNotEmpty) ? Text(
                              restaurant.shortDescription!,
                              overflow: TextOverflow.ellipsis, maxLines: 1,
                              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
                            ) : characteristics != '' ? Text(
                              characteristics,
                              overflow: TextOverflow.ellipsis, maxLines: 1,
                              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
                            ) : const SizedBox(),
                            SizedBox(height: isNewOnGO! ? Dimensions.paddingSizeSmall : Dimensions.paddingSizeExtraSmall),

                            Row(mainAxisAlignment: MainAxisAlignment.start, children: [

                              if (isNewOnGO!) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.location_on_rounded,
                                        size: 14,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${distance > 100 ? '100+' : distance.toStringAsFixed(1)} km',
                                        style: robotoMedium.copyWith(
                                          fontSize: Dimensions.fontSizeSmall,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: Dimensions.paddingSizeSmall),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).hintColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.restaurant_menu_rounded,
                                        size: 14,
                                        color: Theme.of(context).hintColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${restaurant.foodsCount}+ ${'item'.tr}',
                                        style: robotoMedium.copyWith(
                                          fontSize: Dimensions.fontSizeSmall,
                                          color: Theme.of(context).hintColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else ...[
                                IconWithTextRowWidget(
                                  icon: Icons.star_rounded,
                                  text: restaurant.avgRating!.toStringAsFixed(1),
                                  style: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall),
                                ),
                                const SizedBox(width: Dimensions.paddingSizeSmall),
                                if (restaurant.freeDelivery!)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'free_delivery'.tr,
                                      style: robotoMedium.copyWith(
                                        fontSize: Dimensions.fontSizeExtraSmall,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),
                                if (restaurant.freeDelivery!)
                                  const SizedBox(width: Dimensions.paddingSizeSmall),
                                IconWithTextRowWidget(
                                  icon: Icons.schedule_rounded,
                                  text: restaurant.deliveryTime?.replaceAll('-min', ' min') ?? '30-45 min',
                                  style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
                                ),
                              ],

                            ]),
                          ],
                        ),
                      ),
                    ],
                  ),

                  isNewOnGO! ? const SizedBox() : Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    restaurant.foods != null && restaurant.foods!.isNotEmpty ? Expanded(
                      child: Stack(children: [

                        OverFlowContainerWidget(image: restaurant.foods![0].imageFullUrl ?? ''),

                        restaurant.foods!.length > 1 ? Positioned(
                          left: 22, bottom: 0,
                          child: OverFlowContainerWidget(image: restaurant.foods![1].imageFullUrl ?? ''),
                        ) : const SizedBox(),

                        restaurant.foods!.length > 2 ? Positioned(
                          left: 42, bottom: 0,
                          child: OverFlowContainerWidget(image: restaurant.foods![2].imageFullUrl ?? ''),
                        ) : const SizedBox(),

                        restaurant.foods!.length > 4 ? Positioned(
                          left: 82, bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                            height: 30, width: 80,
                            decoration:  BoxDecoration(
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${restaurant.foodsCount! > 11 ? '12 +' : restaurant.foodsCount!} ',
                                  style: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).primaryColor),
                                ),
                                Text('items'.tr, style: robotoRegular.copyWith(fontSize: 10, color: Theme.of(context).primaryColor)),
                              ],
                            ),
                          ),
                        ) : const SizedBox(),

                        restaurant.foods!.length > 3 ?  Positioned(
                          left: 62, bottom: 0,
                          child: OverFlowContainerWidget(image: restaurant.foods![3].imageFullUrl ?? ''),
                        ) : const SizedBox(),
                      ]),
                    ) : const SizedBox(),

                    Icon(Icons.arrow_forward, color: Theme.of(context).primaryColor, size: 20),
                  ]),
                ],
              ),
            ),
          ),
        ),

        Positioned(
          top: 10, right: 10,
          child: GetBuilder<FavouriteController>(builder: (favouriteController) {
            bool isWished = favouriteController.wishRestIdList.contains(restaurant.id);
            return CustomFavouriteWidget(
              isWished: isWished,
              isRestaurant: true,
              restaurant: restaurant,
            );
          }),
        ),
      ],
    );
  }
}


class RestaurantsCardShimmer extends StatelessWidget {
  final bool? isNewOnGO;
  const RestaurantsCardShimmer({super.key, this.isNewOnGO});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: isNewOnGO! ? 300 : ResponsiveHelper.isDesktop(context) ? 160 : 130,
      child: isNewOnGO! ? GridView.builder(
        padding: const EdgeInsets.only(left: 17, right: 17, bottom: 17),
        itemCount: 6,
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, mainAxisSpacing: 17, crossAxisSpacing: 17,
          mainAxisExtent: 130,
        ),
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(left: Dimensions.paddingSizeDefault),
            child: Container(
              width: 380, height: 80,
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                          height: 80, width: 80,
                          decoration:  BoxDecoration(
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                            child:  Container(
                              color: Colors.grey[Get.find<ThemeController>().darkTheme ? 700 : 300],
                              height: 80, width: 80,
                            ),
                          ),
                        ),
                        const SizedBox(width: Dimensions.paddingSizeDefault),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                height: 15, width: 100,
                                color: Colors.grey[Get.find<ThemeController>().darkTheme ? 700 : 300],
                              ),
                              const SizedBox(height: Dimensions.paddingSizeSmall),

                              Container(
                                height: 15, width: 200,
                                color: Colors.grey[Get.find<ThemeController>().darkTheme ? 700 : 300],
                              ),
                              const SizedBox(height: Dimensions.paddingSizeSmall),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Container(
                                    height: 15, width: 50,
                                    color: Colors.grey[Get.find<ThemeController>().darkTheme ? 700 : 300],
                                  ),
                                  const SizedBox(width: Dimensions.paddingSizeSmall),

                                  Container(
                                    height: 15, width: 50,
                                    color: Colors.grey[Get.find<ThemeController>().darkTheme ? 700 : 300],
                                  ),
                                  const SizedBox(width: Dimensions.paddingSizeSmall),

                                  Container(
                                    height: 15, width: 50,
                                    color: Colors.grey[Get.find<ThemeController>().darkTheme ? 700 : 300],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                  ]
              ),
            ),
          );
        },
      ) : ListView.builder(
        itemCount: 3,
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(left: Dimensions.paddingSizeDefault),
            child: Container(
              width: 355, height: 80,
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                border: Border.all(color: Theme.of(context).shadowColor),
                color: Theme.of(context).shadowColor,
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                    height: 80, width: 80,
                    decoration:  BoxDecoration(
                      borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                      child: Shimmer(
                        child: Container(
                          color: Theme.of(context).shadowColor,
                          height: 80, width: 80,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: Dimensions.paddingSizeDefault),

                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [

                      Shimmer(child: Container(height: 15, width: 100, color: Theme.of(context).shadowColor)),
                      const SizedBox(height: Dimensions.paddingSizeSmall),

                      Shimmer(child: Container(height: 15, width: 200, color: Theme.of(context).shadowColor)),
                      const SizedBox(height: Dimensions.paddingSizeSmall),

                      Row(mainAxisAlignment: MainAxisAlignment.start, children: [

                        Shimmer(child: Container(height: 15, width: 50, color: Theme.of(context).shadowColor)),
                        const SizedBox(width: Dimensions.paddingSizeSmall),

                        Shimmer(child: Container(height: 15, width: 50, color: Theme.of(context).shadowColor)),
                        const SizedBox(width: Dimensions.paddingSizeSmall),

                        Shimmer(child: Container(height: 15, width: 50, color: Theme.of(context).shadowColor)),

                      ]),
                    ]),
                  ),
                ]),
              ]),
            ),
          );
        }
      ),
    );
  }
}
