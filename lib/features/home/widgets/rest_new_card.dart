import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/common/models/restaurant_model.dart';
import 'package:godelivery_user/common/widgets/shared/buttons/custom_ink_well_widget.dart';
import 'package:godelivery_user/common/widgets/shared/images/custom_image_widget.dart';
import 'package:godelivery_user/features/restaurant/screens/restaurant_screen.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';

class CompactRestaurantWidget extends StatelessWidget {
  final Restaurant restaurant;
  const CompactRestaurantWidget({super.key, required this.restaurant});

  @override
  Widget build(BuildContext context) {
    String cuisines = '';
    if(restaurant.cuisineNames != null) {
      for(int index=0; index<restaurant.cuisineNames!.length; index++) {
        cuisines = cuisines + (index == 0 ? '' : ', ') + restaurant.cuisineNames![index].name!;
      }
    }

    return CustomInkWellWidget(
      onTap: () {
        Get.toNamed(
          RouteHelper.getRestaurantRoute(restaurant.id),
          arguments: RestaurantScreen(restaurantId: restaurant.id!),
        );
      },
      radius: Dimensions.radiusDefault,
      child: SizedBox(
        width: 80,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              child: CustomImageWidget(
                image: '${restaurant.logoFullUrl}',
                height: 80,
                width: 80,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Text(
              restaurant.name ?? '',
              style: robotoBold.copyWith(
                fontSize: Dimensions.fontSizeDefault,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              cuisines,
              style: robotoMedium.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: Theme.of(context).hintColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
