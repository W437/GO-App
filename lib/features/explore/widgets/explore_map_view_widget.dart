import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:godelivery_user/common/models/restaurant_model.dart';
import 'package:godelivery_user/features/explore/controllers/explore_controller.dart';
import 'package:godelivery_user/features/explore/widgets/restaurant_bottom_sheet_widget.dart';
import 'package:godelivery_user/common/widgets/custom_snackbar_widget.dart';
import 'package:godelivery_user/features/splash/controllers/splash_controller.dart';
import 'package:godelivery_user/features/splash/controllers/theme_controller.dart';
import 'package:godelivery_user/helper/address_helper.dart';
import 'package:godelivery_user/helper/marker_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/images.dart';

class ExploreMapViewWidget extends StatefulWidget {
  final ExploreController exploreController;
  final VoidCallback? onFullscreenToggle;
  final Animation<Offset>? topButtonsAnimation;
  final Animation<double>? topButtonsFadeAnimation;

  const ExploreMapViewWidget({
    super.key,
    required this.exploreController,
    this.onFullscreenToggle,
    this.topButtonsAnimation,
    this.topButtonsFadeAnimation,
  });

  @override
  State<ExploreMapViewWidget> createState() => _ExploreMapViewWidgetState();
}

class _ExploreMapViewWidgetState extends State<ExploreMapViewWidget> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  LatLng? _initialPosition;
  int _lastRestaurantCount = -1;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  void _initializeMap() {
    // Priority: 1) Saved map position, 2) User address, 3) Default location

    // Check for saved map position first
    if (widget.exploreController.savedMapPosition != null) {
      _initialPosition = widget.exploreController.savedMapPosition;
      return;
    }

    // Fall back to user's current address
    final addressModel = AddressHelper.getAddressFromSharedPref();
    if (addressModel != null &&
        addressModel.latitude != null &&
        addressModel.longitude != null) {
      _initialPosition = LatLng(
        double.parse(addressModel.latitude!),
        double.parse(addressModel.longitude!),
      );
    } else {
      // Fall back to default location
      _initialPosition = LatLng(
        double.parse(Get.find<SplashController>().configModel!.defaultLocation!.lat ?? '37.7749'),
        double.parse(Get.find<SplashController>().configModel!.defaultLocation!.lng ?? '-122.4194'),
      );
    }
  }

  Future<void> _createMarkers() async {
    _markers.clear();

    try {
      // Create marker icons using MarkerHelper for efficiency
      final restaurantMarkerIcon = await MarkerHelper.convertAssetToBitmapDescriptor(
        width: 50,
        imagePath: Images.nearbyRestaurantMarker,
      );
      final myLocationMarkerIcon = await MarkerHelper.convertAssetToBitmapDescriptor(
        width: 50,
        imagePath: Images.myLocationMarker,
      );

      // Add user location marker
      if (_initialPosition != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('user_location'),
            position: _initialPosition!,
            icon: myLocationMarkerIcon,
            zIndex: 1,
          ),
        );
      }

      // Add restaurant markers
      if (widget.exploreController.filteredRestaurants != null) {
        for (int i = 0; i < widget.exploreController.filteredRestaurants!.length; i++) {
          final restaurant = widget.exploreController.filteredRestaurants![i];
          if (restaurant.latitude != null && restaurant.longitude != null) {
            _markers.add(
              Marker(
                markerId: MarkerId('restaurant_${restaurant.id}'),
                position: LatLng(
                  double.parse(restaurant.latitude!),
                  double.parse(restaurant.longitude!),
                ),
                icon: restaurantMarkerIcon,
                onTap: () => _onMarkerTapped(restaurant, i),
                zIndex: 2,
              ),
            );
          }
        }
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error creating markers: $e');
    }
  }

  void _onMarkerTapped(Restaurant restaurant, int index) {
    widget.exploreController.selectRestaurant(index);

    // If not in fullscreen mode, trigger fullscreen first, then show card
    if (!widget.exploreController.isFullscreenMode) {
      // Trigger fullscreen mode
      widget.onFullscreenToggle?.call();

      // Wait for fullscreen animation to complete before showing card
      Future.delayed(const Duration(milliseconds: 550), () {
        if (mounted) {
          _showRestaurantBottomSheet(restaurant);
        }
      });
    } else {
      // Already in fullscreen, show card immediately
      _showRestaurantBottomSheet(restaurant);
    }
  }

  void _showRestaurantBottomSheet(Restaurant restaurant) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RestaurantBottomSheetWidget(
        restaurant: restaurant,
        onClose: () {
          widget.exploreController.clearSelectedRestaurant();
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ExploreController>(
      builder: (controller) {
        // Update markers when filtered restaurants change
        final currentCount = controller.filteredRestaurants?.length ?? 0;
        if (currentCount != _lastRestaurantCount && currentCount > 0) {
          _lastRestaurantCount = currentCount;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _createMarkers();
          });
        }

        return Stack(
          children: [
            _initialPosition == null
                ? const Center(child: CircularProgressIndicator())
                : GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _initialPosition!,
                      zoom: widget.exploreController.savedMapZoom ?? 14.0,
                    ),
                    markers: _markers,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    onMapCreated: (GoogleMapController mapController) {
                      _mapController = mapController;
                      controller.setMapController(mapController);
                      // Create markers once map is created
                      if (controller.filteredRestaurants != null) {
                        _createMarkers();
                      }
                    },
                    onCameraMove: (CameraPosition position) {
                      controller.updateMapPosition(
                        position.target,
                        position.zoom,
                      );
                    },
                    style: Get.isDarkMode
                        ? Get.find<ThemeController>().darkMap
                        : Get.find<ThemeController>().lightMap,
                  ),

            // My Location Button
            Positioned(
              bottom: Dimensions.paddingSizeDefault,
              right: Dimensions.paddingSizeDefault,
              child: FloatingActionButton(
                heroTag: 'explore_my_location',
                mini: true,
                backgroundColor: Theme.of(context).cardColor,
                onPressed: () async {
                  try {
                    // Check if location services are enabled
                    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
                    if (!serviceEnabled) {
                      // Location services are not enabled
                      showCustomSnackBar('Please enable location services');
                      return;
                    }

                    // Check location permission
                    LocationPermission permission = await Geolocator.checkPermission();
                    if (permission == LocationPermission.denied) {
                      permission = await Geolocator.requestPermission();
                      if (permission == LocationPermission.denied) {
                        showCustomSnackBar('Location permissions are denied');
                        return;
                      }
                    }

                    if (permission == LocationPermission.deniedForever) {
                      showCustomSnackBar('Location permissions are permanently denied');
                      return;
                    }

                    // Get the raw position without geocoding
                    Position position = await Geolocator.getCurrentPosition(
                      desiredAccuracy: LocationAccuracy.high,
                    );

                    if (_mapController != null) {
                      // Animate camera to user's location
                      _mapController!.animateCamera(
                        CameraUpdate.newLatLngZoom(
                          LatLng(position.latitude, position.longitude),
                          15.0,
                        ),
                      );

                      // Update the user location marker
                      if (mounted) {
                        setState(() {
                          _initialPosition = LatLng(position.latitude, position.longitude);
                        });
                        _createMarkers();
                      }
                    }
                  } catch (e) {
                    debugPrint('Error getting location: $e');
                    // Fallback to the existing location if available
                    if (_initialPosition != null && _mapController != null) {
                      _mapController!.animateCamera(
                        CameraUpdate.newLatLngZoom(_initialPosition!, 15.0),
                      );
                    }
                  }
                },
                child: Icon(
                  Icons.my_location,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),

            // Top buttons with animation
            if (widget.topButtonsAnimation != null && widget.topButtonsFadeAnimation != null)
              FadeTransition(
                opacity: widget.topButtonsFadeAnimation!,
                child: SlideTransition(
                  position: widget.topButtonsAnimation!,
                  child: _buildTopButtons(context, controller),
                ),
              )
            else
              _buildTopButtons(context, controller),
          ],
        );
      },
    );
  }

  Widget _buildTopButtons(BuildContext context, ExploreController controller) {
    return Stack(
      children: [
        // Search/Filter Indicator (hide in fullscreen mode)
        if (!controller.isFullscreenMode)
          Positioned(
            top: MediaQuery.of(context).padding.top + Dimensions.paddingSizeDefault,
            left: Dimensions.paddingSizeDefault,
            right: Dimensions.paddingSizeDefault,
            child: Row(
              children: [
                // Search/Filter Badge
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeDefault,
                      vertical: Dimensions.paddingSizeSmall,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Theme.of(context).primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: Dimensions.paddingSizeSmall),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                AddressHelper.getAddressFromSharedPref()?.address ?? 'current_location'.tr,
                                style: TextStyle(
                                  color: Theme.of(context).textTheme.bodyMedium!.color,
                                  fontWeight: FontWeight.w600,
                                  fontSize: Dimensions.fontSizeSmall,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${controller.filteredRestaurants?.length ?? 0} ${'restaurants'.tr}',
                                style: TextStyle(
                                  color: Theme.of(context).disabledColor,
                                  fontSize: Dimensions.fontSizeExtraSmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: Dimensions.paddingSizeSmall),

                // Fullscreen Button
                InkWell(
                  onTap: widget.onFullscreenToggle,
                  borderRadius: BorderRadius.circular(100),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeDefault,
                      vertical: Dimensions.paddingSizeSmall,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      controller.isFullscreenMode ? Icons.fullscreen_exit : Icons.fullscreen,
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

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
