import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:godelivery_user/common/models/restaurant_model.dart';
import 'package:godelivery_user/common/widgets/adaptive/custom_favourite_widget.dart';
import 'package:godelivery_user/common/widgets/shared/images/custom_image_widget.dart';
import 'package:godelivery_user/common/widgets/shared/feedback/custom_toast_widget.dart';
import 'package:godelivery_user/common/widgets/shared/buttons/custom_button_widget.dart';
import 'package:godelivery_user/features/favourite/controllers/favourite_controller.dart';
import 'package:godelivery_user/helper/business_logic/address_helper.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:godelivery_user/features/restaurant/screens/restaurant_screen.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';

class ExploreRestFloatingBadge extends StatefulWidget {
  final List<Restaurant> restaurants;
  final int initialIndex;
  final VoidCallback onClose;
  final Function(int index)? onRestaurantChanged;

  const ExploreRestFloatingBadge({
    super.key,
    required this.restaurants,
    required this.initialIndex,
    required this.onClose,
    this.onRestaurantChanged,
  });

  @override
  State<ExploreRestFloatingBadge> createState() => _ExploreRestFloatingBadgeState();
}

class _ExploreRestFloatingBadgeState extends State<ExploreRestFloatingBadge> with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  PageController? _pageController;
  int _currentIndex = 0;
  bool _isSwipingInternally = false;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutCubic,
    ));

    // Initialize page controller
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);

    // Trigger animations
    _slideController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    _pageController?.dispose();
    super.dispose();
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

  Widget _buildRestaurantBadge(Restaurant restaurant) {
    final distance = _calculateDistance(restaurant);
    final isOpen = restaurant.open == 1 && restaurant.active == true;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[800]!.withOpacity(0.7),
              borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top section with restaurant info and status
                Stack(
                  children: [
                    Row(
                      children: [
                        // Restaurant logo circle
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child: CustomImageWidget(
                              image: restaurant.logoFullUrl ?? '',
                              height: 48,
                              width: 48,
                              fit: BoxFit.cover,
                              isRestaurant: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Restaurant details
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                restaurant.name ?? '',
                                style: robotoMedium.copyWith(
                                  fontSize: Dimensions.fontSizeDefault,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.delivery_dining,
                                    size: 14,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    restaurant.deliveryTime ?? '30-40 min',
                                    style: robotoRegular.copyWith(
                                      fontSize: Dimensions.fontSizeSmall,
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(
                                    Icons.location_on,
                                    size: 14,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${distance.toStringAsFixed(1)} ${'km'.tr}',
                                    style: robotoRegular.copyWith(
                                      fontSize: Dimensions.fontSizeSmall,
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Status indicator positioned at top right
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Open/Closed status
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isOpen
                                  ? Colors.greenAccent.withOpacity(0.2)
                                  : Colors.redAccent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 6,
                                  color: isOpen ? Colors.greenAccent : Colors.redAccent,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isOpen ? 'Open' : 'Closed',
                                  style: robotoMedium.copyWith(
                                    fontSize: 10,
                                    color: isOpen ? Colors.greenAccent : Colors.redAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Action buttons inside badge
                const SizedBox(height: 12),
                GetBuilder<FavouriteController>(
                  builder: (favouriteController) {
                    bool isWished = favouriteController.wishRestIdList.contains(restaurant.id);
                    return Row(
                      children: [
                        // Favorite icon button
                        InkWell(
                          onTap: () {
                            favouriteController.addToFavouriteList(
                              null,
                              restaurant.id,
                              true,
                            );
                          },
                          borderRadius: BorderRadius.circular(100),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isWished ? Icons.favorite : Icons.favorite_border,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // View Restaurant button
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              Get.back(); // Close bottom sheet
                              Get.toNamed(
                                RouteHelper.getRestaurantRoute(restaurant.id),
                                arguments: RestaurantScreen(restaurant: restaurant),
                              );
                            },
                            borderRadius: BorderRadius.circular(100),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Center(
                                child: Text(
                                  'view_restaurant'.tr,
                                  style: robotoMedium.copyWith(
                                    fontSize: Dimensions.fontSizeSmall,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Stack(
      children: [
        // Gradient fade overlay at bottom 200px
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.0),
                    Colors.black.withOpacity(0.4),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Floating badge
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                margin: EdgeInsets.only(bottom: bottomPadding + 80), // Position above bottom nav
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Swipeable badge
                    widget.restaurants.length <= 1
                        ? _buildRestaurantBadge(widget.restaurants[0])
                        : SizedBox(
                            height: 130, // Increased height to accommodate buttons
                            child: PageView.builder(
                              controller: _pageController,
                              physics: const BouncingScrollPhysics(),
                              pageSnapping: true,
                              itemCount: widget.restaurants.length,
                              onPageChanged: (index) {
                                if (_currentIndex != index) {
                                  setState(() {
                                    _currentIndex = index;
                                    _isSwipingInternally = true;
                                  });
                                  widget.onRestaurantChanged?.call(index);
                                }
                              },
                              itemBuilder: (context, index) {
                                return AnimatedBuilder(
                                  animation: _pageController!,
                                  builder: (context, child) {
                                    double scale = 1.0;
                                    if (_pageController!.hasClients &&
                                        _pageController!.positions.length == 1 &&
                                        _pageController!.position.haveDimensions) {
                                      final page = _pageController!.page ?? _currentIndex.toDouble();
                                      final distanceFromCurrent = (page - index).abs();
                                      scale = (1.0 - (distanceFromCurrent * 0.1)).clamp(0.9, 1.0);
                                    }
                                    return TweenAnimationBuilder<double>(
                                      tween: Tween(begin: scale, end: scale),
                                      duration: const Duration(milliseconds: 200),
                                      curve: Curves.easeOutBack,
                                      builder: (context, value, child) {
                                        return Transform.scale(
                                          scale: value,
                                          child: child,
                                        );
                                      },
                                      child: child,
                                    );
                                  },
                                  child: _buildRestaurantBadge(widget.restaurants[index]),
                                );
                              },
                            ),
                          ),
                    // Static pagination dots below
                    if (widget.restaurants.length > 1)
                      Container(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            widget.restaurants.length.clamp(0, 10),
                            (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: index == _currentIndex ? 8 : 6,
                              height: index == _currentIndex ? 8 : 6,
                              decoration: BoxDecoration(
                                color: index == _currentIndex
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
