import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/common/models/restaurant_model.dart';
import 'package:godelivery_user/common/widgets/shared/buttons/custom_button_widget.dart';
import 'package:godelivery_user/common/widgets/shared/separators/muted_separator_widget.dart';
import 'package:godelivery_user/features/restaurant/widgets/restaurant_location_map_widget.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:url_launcher/url_launcher.dart';

class RestaurantDetailsScreen extends StatelessWidget {
  final Restaurant restaurant;

  const RestaurantDetailsScreen({super.key, required this.restaurant});

  @override
  Widget build(BuildContext context) {
    // Calculate distance placeholder
    String distance = "1.2 mi"; // Placeholder

    // Price range placeholder
    String priceRange = "\$\$"; // Placeholder

    // Get cuisine name
    String cuisine = restaurant.cuisineNames != null && restaurant.cuisineNames!.isNotEmpty
        ? restaurant.cuisineNames!.first.name ?? ''
        : 'Restaurant';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).textTheme.bodyLarge?.color),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            _buildHeader(context, cuisine, priceRange, distance),
            const SizedBox(height: Dimensions.paddingSizeLarge),

            // Description Section
            if (restaurant.description != null && restaurant.description!.isNotEmpty)
              _buildDescriptionSection(context),
            const SizedBox(height: Dimensions.paddingSizeLarge),

            // Map Section
            RestaurantLocationMapWidget(restaurant: restaurant),
            const SizedBox(height: Dimensions.paddingSizeLarge),

            // Opening Hours Section
            if (restaurant.schedules != null && restaurant.schedules!.isNotEmpty)
              _buildOpeningHoursSection(context),
            const SizedBox(height: Dimensions.paddingSizeLarge),

            // Contact & Info Section
            _buildContactInfoSection(context),
            const SizedBox(height: Dimensions.paddingSizeLarge),

            // Reviews Section
            _buildReviewsSection(context),

            // Bottom spacing for visibility
            const SizedBox(height: Dimensions.paddingSizeExtraLarge * 2),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String cuisine, String priceRange, String distance) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Restaurant name
        Text(
          restaurant.name ?? '',
          style: robotoBold.copyWith(
            fontSize: 32,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),

        // Cuisine • Price • Distance
        Text(
          '$cuisine • $priceRange • $distance',
          style: robotoRegular.copyWith(
            fontSize: Dimensions.fontSizeDefault,
            color: Theme.of(context).hintColor,
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),

        // Rating
        Row(
          children: [
            Icon(Icons.star, color: Colors.orange, size: 20),
            const SizedBox(width: 4),
            Text(
              '${restaurant.avgRating ?? 0}',
              style: robotoBold.copyWith(
                fontSize: Dimensions.fontSizeDefault,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            Text(
              ' (${restaurant.ratingCount ?? 0} ${'reviews'.tr})',
              style: robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeDefault,
                color: Theme.of(context).hintColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),

        // Address
        Row(
          children: [
            Icon(Icons.location_on, color: Theme.of(context).hintColor, size: 18),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                restaurant.address ?? '',
                style: robotoRegular.copyWith(
                  fontSize: Dimensions.fontSizeDefault,
                  color: Theme.of(context).hintColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDescriptionSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      ),
      child: Text(
        restaurant.description ?? '',
        style: robotoRegular.copyWith(
          fontSize: Dimensions.fontSizeDefault,
          color: Theme.of(context).textTheme.bodyLarge?.color,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildOpeningHoursSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'opening_hours'.tr,
          style: robotoBold.copyWith(
            fontSize: Dimensions.fontSizeExtraLarge,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeDefault),

        // Days list
        ...List.generate(7, (index) {
          String day = _getDayName(index);
          bool isToday = DateTime.now().weekday - 1 == index;

          // Find schedule for this day
          Schedules? schedule = restaurant.schedules?.firstWhere(
            (s) => s.day == index,
            orElse: () => Schedules(day: index, openingTime: null, closingTime: null),
          );

          bool isClosed = schedule?.openingTime == null || schedule?.closingTime == null;

          return Padding(
            padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  day,
                  style: (isToday ? robotoBold : robotoRegular).copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                Text(
                  isClosed
                      ? 'closed'.tr
                      : '${_formatTime(schedule!.openingTime!)} - ${_formatTime(schedule.closingTime!)}',
                  style: robotoRegular.copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                    color: isClosed ? Theme.of(context).primaryColor : Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildContactInfoSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Buttons Row
        Row(
          children: [
            // Phone Button
            if (restaurant.phone != null && restaurant.phone!.isNotEmpty) ...[
              Expanded(
                child: CustomButtonWidget(
                  buttonText: 'Call',
                  icon: Icons.phone,
                  radius: Dimensions.radiusDefault,
                  height: 50,
                  expand: false,
                  onPressed: () async {
                    final Uri phoneUri = Uri.parse('tel:${restaurant.phone}');
                    if (await canLaunchUrl(phoneUri)) {
                      await launchUrl(phoneUri);
                    }
                  },
                ),
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),
            ],

            // Website Button
            Expanded(
              child: CustomButtonWidget(
                buttonText: 'VISIT SITE',
                icon: Icons.language,
                radius: Dimensions.radiusDefault,
                height: 50,
                expand: false,
                textColor: Theme.of(context).primaryColor,
                iconColor: Theme.of(context).primaryColor,
                transparent: true,
                border: Border.all(
                  color: Theme.of(context).primaryColor,
                  width: 1.5,
                ),
                onPressed: () async {
                  final String websiteUrl = 'https://the${restaurant.name?.toLowerCase().replaceAll(' ', '')}.com';
                  final Uri uri = Uri.parse(websiteUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: Dimensions.paddingSizeDefault),

        // Characteristics info box
        if (restaurant.characteristics != null && restaurant.characteristics!.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                Expanded(
                  child: Text(
                    restaurant.characteristics!.join(', '),
                    style: robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildReviewsSection(BuildContext context) {
    return Column(
      children: [
        // Separator line
        const MutedSeparatorWidget(),
        const SizedBox(height: Dimensions.paddingSizeLarge),

        // Reviews content
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left side: Title and rating
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'reviews'.tr,
                    style: robotoBold.copyWith(
                      fontSize: Dimensions.fontSizeExtraLarge,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.orange, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${restaurant.avgRating ?? 0}',
                        style: robotoBold.copyWith(
                          fontSize: Dimensions.fontSizeDefault,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      Text(
                        ' (${restaurant.ratingCount ?? 0})',
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
            const SizedBox(width: Dimensions.paddingSizeDefault),

            // Right side: Button
            CustomButtonWidget(
              buttonText: 'See All',
              radius: Dimensions.radiusDefault,
              height: 50,
              width: 120,
              expand: false,
              fontSize: Dimensions.fontSizeDefault,
              onPressed: () {
                Get.toNamed(RouteHelper.getRestaurantReviewRoute(
                  restaurant.id,
                  restaurant.name,
                  restaurant,
                ));
              },
            ),
          ],
        ),
      ],
    );
  }

  String _getDayName(int index) {
    const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    return days[index].tr;
  }

  String _formatTime(String time) {
    // Parse time string (assuming format like "11:00:00")
    try {
      final parts = time.split(':');
      if (parts.length >= 2) {
        int hour = int.parse(parts[0]);
        int minute = int.parse(parts[1]);

        String period = hour >= 12 ? 'PM' : 'AM';
        if (hour > 12) hour -= 12;
        if (hour == 0) hour = 12;

        return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
      }
    } catch (e) {
      // Return original if parsing fails
      return time;
    }
    return time;
  }
}
