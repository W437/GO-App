import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:godelivery_user/common/models/restaurant_model.dart';
import 'package:godelivery_user/common/widgets/shared/images/custom_image_widget.dart';
import 'package:godelivery_user/features/explore/controllers/explore_controller.dart';
import 'package:godelivery_user/features/explore/widgets/restaurant_card_shimmer.dart';
import 'package:godelivery_user/features/explore/widgets/empty_state_widget.dart';
import 'package:godelivery_user/features/favourite/controllers/favourite_controller.dart';
import 'package:godelivery_user/helper/business_logic/address_helper.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:godelivery_user/features/restaurant/screens/restaurant_screen.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class RestaurantListViewWidget extends StatelessWidget {
  final ExploreController exploreController;
  final ScrollController? scrollController;

  const RestaurantListViewWidget({
    super.key,
    required this.exploreController,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ExploreController>(
      builder: (controller) {
        if (controller.isLoading) {
          return ListView.separated(
            controller: scrollController,
            padding: EdgeInsets.only(
              left: Dimensions.paddingSizeDefault,
              right: Dimensions.paddingSizeDefault,
              top: Dimensions.paddingSizeDefault,
              bottom: MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight + Dimensions.paddingSizeDefault,
            ),
            itemCount: 5,
            separatorBuilder: (context, index) =>
                const SizedBox(height: Dimensions.paddingSizeDefault),
            itemBuilder: (context, index) => const RestaurantCardShimmer(),
          );
        }

        if (controller.filteredRestaurants == null ||
            controller.filteredRestaurants!.isEmpty) {
          // Determine if user has active filters
          final bool hasActiveFilters = controller.activeFilterCount > 0 ||
                                        controller.searchQuery.isNotEmpty;

          return ListView(
            controller: scrollController,
            padding: EdgeInsets.only(
              left: Dimensions.paddingSizeDefault,
              right: Dimensions.paddingSizeDefault,
              top: Dimensions.paddingSizeDefault,
              bottom: MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight + Dimensions.paddingSizeDefault,
            ),
            children: [
              EmptyStateWidget(
                type: hasActiveFilters
                    ? EmptyStateType.noResults
                    : EmptyStateType.noRestaurantsNearby,
                onClearFilters: hasActiveFilters ? () {
                  controller.clearAllFilters();
                  controller.clearSearch();
                } : null,
              ),
            ],
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await controller.getNearbyRestaurants(reload: true);
            HapticFeedback.mediumImpact();
          },
          child: ListView.separated(
            controller: scrollController,
            padding: EdgeInsets.only(
              left: Dimensions.paddingSizeDefault,
              right: Dimensions.paddingSizeDefault,
              top: Dimensions.paddingSizeDefault,
              bottom: MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight + Dimensions.paddingSizeDefault,
            ),
            itemCount: controller.filteredRestaurants!.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: Dimensions.paddingSizeDefault),
            itemBuilder: (context, index) {
              final restaurant = controller.filteredRestaurants![index];
              return _StaggeredAnimation(
                index: index,
                child: _buildRestaurantCard(context, restaurant, index),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildRestaurantCard(
    BuildContext context,
    Restaurant restaurant,
    int index,
  ) {
    final distance = _calculateDistance(restaurant);
    final isOpen = restaurant.open == 1 && restaurant.active == true;

    // Create semantic label for the card
    final String semanticLabel = '${restaurant.name ?? "Restaurant"}, '
        '${restaurant.avgRating?.toStringAsFixed(1) ?? "0.0"} stars, '
        '${isOpen ? "Open now" : "Closed"}, '
        '${distance.toStringAsFixed(1)} kilometers away, '
        '${restaurant.freeDelivery == true ? "Free delivery" : "Delivery fee ${restaurant.minimumShippingCharge?.toStringAsFixed(2) ?? "unknown"} dollars"}';

    return GetBuilder<FavouriteController>(
      builder: (favouriteController) {
        final bool isFavorite = favouriteController.wishRestIdList.contains(restaurant.id);

        return Slidable(
          key: ValueKey(restaurant.id),
          endActionPane: ActionPane(
            motion: const DrawerMotion(),
            extentRatio: 0.25,
            dismissible: DismissiblePane(
              onDismissed: () {
                HapticFeedback.mediumImpact();
                if (isFavorite) {
                  favouriteController.removeFromFavouriteList(restaurant.id, true);
                } else {
                  favouriteController.addToFavouriteList(null, restaurant.id, true);
                }
              },
              confirmDismiss: () async {
                HapticFeedback.mediumImpact();
                if (isFavorite) {
                  favouriteController.removeFromFavouriteList(restaurant.id, true);
                } else {
                  favouriteController.addToFavouriteList(null, restaurant.id, true);
                }
                return false; // Don't actually dismiss, just trigger the action
              },
            ),
            children: [
              CustomSlidableAction(
                onPressed: (context) {
                  HapticFeedback.mediumImpact();
                  if (isFavorite) {
                    favouriteController.removeFromFavouriteList(restaurant.id, true);
                  } else {
                    favouriteController.addToFavouriteList(null, restaurant.id, true);
                  }
                },
                backgroundColor: Colors.grey.shade300,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(Dimensions.radiusDefault),
                  bottomRight: Radius.circular(Dimensions.radiusDefault),
                ),
                padding: EdgeInsets.zero,
                child: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Theme.of(context).primaryColor : Colors.grey.shade600,
                  size: 24,
                ),
              ),
            ],
          ),
          child: Semantics(
            label: semanticLabel,
            button: true,
            enabled: true,
            child: InkWell(
              onTap: () {
                exploreController.selectRestaurant(index);
                Get.toNamed(
                  RouteHelper.getRestaurantRoute(restaurant.id),
                  arguments: RestaurantScreen(restaurant: restaurant),
                );
              },
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              child: Container(
        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          border: Border.all(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Restaurant Logo with Discount Badge
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    child: Stack(
                      children: [
                        CustomImageWidget(
                          image: restaurant.logoFullUrl ?? '',
                          height: 70,
                          width: 70,
                          fit: BoxFit.cover,
                          isRestaurant: true,
                        ),
                        // Gradient overlay for better contrast
                        if (restaurant.discount != null && restaurant.discount!.discount! > 0)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.black.withOpacity(0.2),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Discount Badge
                if (restaurant.discount != null && restaurant.discount!.discount! > 0)
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(Dimensions.radiusDefault),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: Text(
                        '${restaurant.discount!.discount}% OFF',
                        style: robotoBold.copyWith(
                          fontSize: 9,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),

            // Restaurant Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and Status
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          restaurant.name ?? '',
                          style: robotoBold.copyWith(
                            fontSize: Dimensions.fontSizeDefault,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isOpen
                              ? const Color(0xFF1B5E20) // Dark green for better contrast
                              : Colors.red.withOpacity(0.15), // Semi-transparent red background
                          borderRadius: BorderRadius.circular(4),
                          border: isOpen
                              ? null
                              : Border.all(
                                  color: Colors.red,
                                  width: 1,
                                ),
                        ),
                        child: Text(
                          isOpen ? 'OPEN' : 'CLOSED',
                          style: robotoMedium.copyWith(
                            fontSize: 10,
                            color: isOpen ? Colors.white : Colors.red, // Red text for closed
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Rating
                  Row(
                    children: [
                      _AnimatedStarIcon(
                        delay: Duration(milliseconds: (index * 80).clamp(0, 400) + 200),
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        restaurant.avgRating?.toStringAsFixed(1) ?? '0.0',
                        style: robotoMedium.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${restaurant.ratingCount ?? 0})',
                        style: robotoRegular.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          color: Theme.of(context).disabledColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Cuisines
                  if (restaurant.cuisineNames != null &&
                      restaurant.cuisineNames!.isNotEmpty)
                    Text(
                      restaurant.cuisineNames!
                          .take(3)
                          .map((c) => c.name)
                          .join(', '),
                      style: robotoRegular.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: Theme.of(context).disabledColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),

                  // Delivery Time, Distance & Free Delivery
                  Row(
                    children: [
                      // Delivery Time
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: isOpen ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          restaurant.deliveryTime ?? '30-40 min',
                          style: robotoRegular.copyWith(
                            fontSize: Dimensions.fontSizeExtraSmall,
                            color: Theme.of(context).disabledColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: Dimensions.paddingSizeSmall),

                      // Distance
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '${distance.toStringAsFixed(1)} ${'km'.tr}',
                          style: robotoRegular.copyWith(
                            fontSize: Dimensions.fontSizeExtraSmall,
                            color: Theme.of(context).disabledColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      const SizedBox(width: 4),

                      // Delivery Fee or Free Badge
                      if (restaurant.freeDelivery == true)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.delivery_dining,
                                size: 12,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'FREE',
                                style: robotoMedium.copyWith(
                                  fontSize: 10,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (restaurant.minimumShippingCharge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '\$${restaurant.minimumShippingCharge!.toStringAsFixed(2)}',
                            style: robotoMedium.copyWith(
                              fontSize: 10,
                              color: Theme.of(context).primaryColor,
                            ),
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
          ),
        );
      },
    );
  }

  double _calculateDistance(Restaurant restaurant) {
    try {
      final address = AddressHelper.getAddressFromSharedPref();
      if (address != null &&
          restaurant.latitude != null &&
          restaurant.longitude != null) {
        return Geolocator.distanceBetween(
              double.parse(restaurant.latitude!),
              double.parse(restaurant.longitude!),
              double.parse(address.latitude!),
              double.parse(address.longitude!),
            ) /
            1000;
      }
    } catch (e) {
      // Return default distance if calculation fails
    }
    return 0.0;
  }
}

/// Staggered animation widget for restaurant cards
class _StaggeredAnimation extends StatefulWidget {
  final int index;
  final Widget child;

  const _StaggeredAnimation({
    required this.index,
    required this.child,
  });

  @override
  State<_StaggeredAnimation> createState() => _StaggeredAnimationState();
}

class _StaggeredAnimationState extends State<_StaggeredAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    // Stagger animation based on index (max 100ms per card)
    Future.delayed(
      Duration(milliseconds: (widget.index * 80).clamp(0, 400)),
      () {
        if (mounted) {
          _controller.forward();
        }
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Animated star icon that scales in
class _AnimatedStarIcon extends StatefulWidget {
  final Duration delay;
  final Color color;

  const _AnimatedStarIcon({
    required this.delay,
    required this.color,
  });

  @override
  State<_AnimatedStarIcon> createState() => _AnimatedStarIconState();
}

class _AnimatedStarIconState extends State<_AnimatedStarIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    // Delay animation start
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Icon(
        Icons.star,
        size: 16,
        color: widget.color,
      ),
    );
  }
}
