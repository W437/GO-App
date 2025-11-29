import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/common/widgets/shared/buttons/custom_ink_well_widget.dart';
import 'package:godelivery_user/features/home/widgets/blurhash_image_widget.dart';
import 'package:godelivery_user/common/models/restaurant_model.dart';
import 'package:godelivery_user/features/restaurant/screens/restaurant_screen.dart';
import 'package:godelivery_user/helper/converters/date_converter.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';

class RestSponsoredCard extends StatelessWidget {
  final Restaurant restaurant;
  const RestSponsoredCard({super.key, required this.restaurant});

  @override
  Widget build(BuildContext context) {
    // If 'open' field is null, assume restaurant is open (backend returns incomplete data)
    bool isAvailable = (restaurant.open == null || restaurant.open == 1) && (restaurant.active ?? false);

    String openUntil = restaurant.currentOpeningTime ??
                       (restaurant.restaurantOpeningTime != null
                         ? DateConverter.convertTimeToTime(restaurant.restaurantOpeningTime!)
                         : '23:00');

    return CustomInkWellWidget(
      onTap: () {
        Get.toNamed(
          RouteHelper.getRestaurantRoute(restaurant.id),
          arguments: RestaurantScreen(restaurantId: restaurant.id!),
        );
      },
      radius: 20,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Get.isDarkMode
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              children: [
                // Top - Cover Image with Gradual Blur (fills remaining space)
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Layer 1: Clear image (bottom layer)
                        BlurhashImageWidget(
                          imageUrl: restaurant.coverPhotoFullUrl ?? '',
                          blurhash: restaurant.coverPhotoBlurhash,
                          fit: BoxFit.cover,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        ),

                        // Layer 2: Blurred image with gradient mask (top layer)
                        ShaderMask(
                          shaderCallback: (rect) {
                            return const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent, // Top stays clear
                                Colors.black,       // Bottom gets blurred
                              ],
                              stops: [0.3, 1.0], // Blur starts at 30% down
                            ).createShader(rect);
                          },
                          blendMode: BlendMode.dstIn,
                          child: ImageFiltered(
                            imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                            child: BlurhashImageWidget(
                              imageUrl: restaurant.coverPhotoFullUrl ?? '',
                              blurhash: restaurant.coverPhotoBlurhash,
                              fit: BoxFit.cover,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom - White Background (wraps content)
                Container(
                  padding: const EdgeInsets.fromLTRB(8, 32, 8, 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        // Restaurant Name (centered)
                        Text(
                          restaurant.name ?? '',
                          style: robotoBold.copyWith(
                            fontSize: Dimensions.fontSizeDefault,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 2),

                        // Open Status
                        if (isAvailable)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.schedule_rounded,
                                  size: 10,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  'Open until $openUntil',
                                  style: robotoRegular.copyWith(
                                    fontSize: 9,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'closed_now'.tr.toUpperCase(),
                              style: robotoMedium.copyWith(
                                fontSize: 9,
                                color: Theme.of(context).colorScheme.error,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        const SizedBox(height: 2),

                        // Rating - Always show
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).hintColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star_rounded,
                                size: 12,
                                color: const Color(0xFFFFB800),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${restaurant.avgRating?.toStringAsFixed(1) ?? "0.0"}',
                                style: robotoBold.copyWith(
                                  fontSize: 11,
                                ),
                              ),
                              if (restaurant.ratingCount != null && restaurant.ratingCount! > 0) ...[
                                const SizedBox(width: 2),
                                Text(
                                  '(${restaurant.ratingCount})',
                                  style: robotoRegular.copyWith(
                                    fontSize: 9,
                                    color: Theme.of(context).hintColor,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                  ),
                ),
              ],
            ),

            // Centered Logo - Positioned at junction (overlapping image and content)
            Positioned(
              bottom: 72, // Position from bottom to overlap perfectly
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: BlurhashImageWidget(
                      imageUrl: restaurant.logoFullUrl ?? '',
                      blurhash: restaurant.logoBlurhash,
                      fit: BoxFit.cover,
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
