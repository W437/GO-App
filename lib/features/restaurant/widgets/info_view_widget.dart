import 'package:godelivery_user/common/widgets/adaptive/custom_favourite_widget.dart';
import 'package:godelivery_user/features/restaurant/controllers/restaurant_controller.dart';
import 'package:godelivery_user/features/address/domain/models/address_model.dart';
import 'package:godelivery_user/common/models/restaurant_model.dart';
import 'package:godelivery_user/features/favourite/controllers/favourite_controller.dart';
import 'package:godelivery_user/helper/converters/price_converter.dart';
import 'package:godelivery_user/helper/ui/responsive_helper.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:godelivery_user/util/app_constants.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/images.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:godelivery_user/common/widgets/shared/images/custom_image_widget.dart';
import 'package:godelivery_user/common/widgets/shared/feedback/custom_snackbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

class InfoViewWidget extends StatelessWidget {
  final Restaurant restaurant;
  final RestaurantController restController;
  final double scrollingRate;
  const InfoViewWidget({super.key, required this.restaurant, required this.restController, required this.scrollingRate});

  @override
  Widget build(BuildContext context) {
    bool isDesktop = ResponsiveHelper.isDesktop(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Centered Logo
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Theme.of(context).cardColor, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(60),
            child: CustomImageWidget(
              image: '${restaurant.logoFullUrl}',
              height: 100 - (scrollingRate * 30),
              width: 100 - (scrollingRate * 30),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeDefault),

        // Name & Info Centered
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Restaurant Name
            Text(
              restaurant.name!,
              style: robotoBold.copyWith(
                fontSize: Dimensions.fontSizeOverLarge,
                color: Colors.black87,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Rating & Time Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${restaurant.avgRating!.toStringAsFixed(1)}',
                  style: robotoMedium.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    color: Theme.of(context).hintColor,
                  ),
                ),
                const SizedBox(width: Dimensions.paddingSizeDefault),
                Icon(Icons.access_time, color: Theme.of(context).hintColor, size: 16),
                const SizedBox(width: 4),
                Text(
                  restaurant.deliveryTime?.replaceAll('-min', ' min') ?? '30-40 min',
                  style: robotoMedium.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Description
            if (restaurant.description != null && restaurant.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                child: Text(
                  restaurant.description!,
                  style: robotoRegular.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    color: Theme.of(context).hintColor,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 12),

            // Details Button
            InkWell(
              onTap: () {
                // Show restaurant details
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeLarge,
                  vertical: Dimensions.paddingSizeSmall,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).hintColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Details',
                  style: robotoMedium.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: Dimensions.paddingSizeDefault),
      ],
    );
  }

  // Helper methods removed as they are no longer used in this simplified view
}
