import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:godelivery_user/common/models/restaurant_model.dart';
import 'package:godelivery_user/features/explore/controllers/explore_controller.dart';
import 'package:godelivery_user/features/explore/widgets/explore_rest_floating_badge.dart';
import 'package:godelivery_user/common/widgets/shared/feedback/custom_toast_widget.dart';
import 'package:godelivery_user/features/splash/controllers/splash_controller.dart';
import 'package:godelivery_user/features/splash/controllers/theme_controller.dart';
import 'package:godelivery_user/helper/business_logic/address_helper.dart';
import 'package:godelivery_user/helper/ui/marker_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/images.dart';

class ExploreMapViewWidget extends StatefulWidget {
  final ExploreController exploreController;

  const ExploreMapViewWidget({
    super.key,
    required this.exploreController,
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
        imagePath: Images.mapPin,
      );
      final myLocationMarkerIcon = await MarkerHelper.convertAssetToBitmapDescriptor(
        width: 50,
        imagePath: Images.pickLocationMapPin,
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
    // Show restaurant card immediately
    _showRestaurantBottomSheet(index);
  }

  void _showRestaurantBottomSheet(int initialIndex) {
    final restaurants = widget.exploreController.filteredRestaurants;
    if (restaurants == null || restaurants.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent, // Remove background overlay
      builder: (context) => GestureDetector(
        onTap: () {
          // Close on tap outside
          widget.exploreController.clearSelectedRestaurant();
          Navigator.pop(context);
        },
        child: Container(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: () {}, // Prevent taps on badge from closing
            child: ExploreRestFloatingBadge(
              restaurants: restaurants,
              initialIndex: initialIndex,
              onClose: () {
                widget.exploreController.clearSelectedRestaurant();
                Navigator.pop(context);
              },
              onRestaurantChanged: (index) {
                // Update controller selection when user swipes
                widget.exploreController.selectRestaurant(index);

                // Animate map to the new restaurant
                final restaurant = restaurants[index];
                if (_mapController != null &&
                    restaurant.latitude != null &&
                    restaurant.longitude != null) {
                  _mapController!.animateCamera(
                    CameraUpdate.newLatLng(
                      LatLng(
                        double.parse(restaurant.latitude!),
                        double.parse(restaurant.longitude!),
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        ),
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
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
