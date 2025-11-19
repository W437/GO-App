import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/common/models/restaurant_model.dart';
import 'package:godelivery_user/features/home/controllers/advertisement_controller.dart';
import 'package:godelivery_user/features/home/widgets/restaurants_view_widget.dart';
import 'package:godelivery_user/features/restaurant/controllers/restaurant_controller.dart';
import 'package:godelivery_user/features/restaurant/screens/restaurant_screen.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';

class WebHighlightWidgetView extends StatefulWidget {
  const WebHighlightWidgetView({super.key});

  @override
  State<WebHighlightWidgetView> createState() => _WebHighlightWidgetViewState();
}

class _WebHighlightWidgetViewState extends State<WebHighlightWidgetView> {

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AdvertisementController>(builder: (advertisementController) {
      return advertisementController.advertisementList != null && advertisementController.advertisementList!.isNotEmpty ? Container(
        margin: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Modern Section Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).primaryColor,
                              Theme.of(context).primaryColor.withValues(alpha: 0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded, color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'SPONSORED',
                              style: robotoMedium.copyWith(
                                fontSize: Dimensions.fontSizeSmall,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                  Text(
                    'highlights_for_you'.tr,
                    style: robotoBold.copyWith(
                      fontSize: Dimensions.fontSizeOverLarge,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'see_our_most_popular_restaurant_and_foods'.tr,
                    style: robotoRegular.copyWith(
                      color: Theme.of(context).hintColor,
                      fontSize: Dimensions.fontSizeDefault,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),

            // Restaurant Cards Grid
            GetBuilder<RestaurantController>(
              builder: (restaurantController) {
                // Get restaurants from advertisements
                List<Restaurant> restaurants = advertisementController.advertisementList!
                    .where((ad) => ad.restaurant != null && ad.addType != 'video_promotion')
                    .map((ad) => ad.restaurant!)
                    .toList();

                return restaurants.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: restaurants.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: Dimensions.paddingSizeLarge,
                          crossAxisSpacing: Dimensions.paddingSizeLarge,
                          mainAxisExtent: 305,
                        ),
                        itemBuilder: (context, index) {
                          return RestaurantView(restaurant: restaurants[index]);
                        },
                      ),
                    )
                  : const SizedBox();
              },
            ),
          ],
        ),
      ) : const SizedBox();
    });
  }
}
