import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/common/models/restaurant_model.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';

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

            // Opening Hours Section
            if (restaurant.schedules != null && restaurant.schedules!.isNotEmpty)
              _buildOpeningHoursSection(context),
            const SizedBox(height: Dimensions.paddingSizeLarge),

            // Location Section
            _buildLocationSection(context),
            const SizedBox(height: Dimensions.paddingSizeLarge),

            // Contact & Info Section
            _buildContactInfoSection(context),
            const SizedBox(height: Dimensions.paddingSizeLarge),

            // Reviews Section
            _buildReviewsSection(context),
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

  Widget _buildLocationSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'location'.tr,
          style: robotoBold.copyWith(
            fontSize: Dimensions.fontSizeExtraLarge,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeDefault),

        // Address
        Text(
          restaurant.address ?? '',
          style: robotoRegular.copyWith(
            fontSize: Dimensions.fontSizeDefault,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeDefault),

        // Map placeholder
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          ),
          child: Center(
            child: Icon(
              Icons.map,
              size: 48,
              color: Theme.of(context).hintColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactInfoSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'contact_info'.tr,
          style: robotoBold.copyWith(
            fontSize: Dimensions.fontSizeExtraLarge,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeDefault),

        // Phone
        if (restaurant.phone != null && restaurant.phone!.isNotEmpty) ...[
          Row(
            children: [
              Icon(Icons.phone, color: Theme.of(context).primaryColor, size: 20),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Text(
                restaurant.phone ?? '',
                style: robotoRegular.copyWith(
                  fontSize: Dimensions.fontSizeDefault,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),
        ],

        // Website (placeholder)
        Row(
          children: [
            Icon(Icons.language, color: Theme.of(context).primaryColor, size: 20),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Text(
              'the${restaurant.name?.toLowerCase().replaceAll(' ', '')}.com',
              style: robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeDefault,
                color: Theme.of(context).primaryColor,
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
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      ),
      child: Column(
        children: [
          // Reviews header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'reviews'.tr,
                style: robotoBold.copyWith(
                  fontSize: Dimensions.fontSizeExtraLarge,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
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
          const SizedBox(height: Dimensions.paddingSizeDefault),

          // See All Reviews button
          InkWell(
            onTap: () {
              Get.toNamed(RouteHelper.getRestaurantReviewRoute(
                restaurant.id,
                restaurant.name,
                restaurant,
              ));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: Dimensions.paddingSizeDefault,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              ),
              child: Center(
                child: Text(
                  'see_all_reviews'.tr,
                  style: robotoBold.copyWith(
                    fontSize: Dimensions.fontSizeLarge,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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
