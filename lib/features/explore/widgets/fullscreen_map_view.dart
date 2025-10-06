import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:godelivery_user/common/models/restaurant_model.dart';
import 'package:godelivery_user/features/category/controllers/category_controller.dart';
import 'package:godelivery_user/features/explore/controllers/explore_controller.dart';
import 'package:godelivery_user/features/explore/widgets/restaurant_bottom_sheet_widget.dart';
import 'package:godelivery_user/features/splash/controllers/theme_controller.dart';
import 'package:godelivery_user/util/dimensions.dart';

class FullscreenMapView extends StatefulWidget {
  final ExploreController controller;
  final LatLng initialPosition;

  const FullscreenMapView({
    super.key,
    required this.controller,
    required this.initialPosition,
  });

  @override
  State<FullscreenMapView> createState() => _FullscreenMapViewState();
}

class _FullscreenMapViewState extends State<FullscreenMapView> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _createMarkers();
  }

  Future<void> _createMarkers() async {
    _markers.clear();

    // Add user location marker
    _markers.add(
      Marker(
        markerId: const MarkerId('user_location'),
        position: widget.initialPosition,
        icon: await _getMarkerIcon('assets/image/location/my_location_marker.png', 80),
        zIndex: 1,
      ),
    );

    // Add restaurant markers
    if (widget.controller.filteredRestaurants != null) {
      for (int i = 0; i < widget.controller.filteredRestaurants!.length; i++) {
        final restaurant = widget.controller.filteredRestaurants![i];
        if (restaurant.latitude != null && restaurant.longitude != null) {
          _markers.add(
            Marker(
              markerId: MarkerId('restaurant_${restaurant.id}'),
              position: LatLng(
                double.parse(restaurant.latitude!),
                double.parse(restaurant.longitude!),
              ),
              icon: await _getMarkerIcon('assets/image/location/restaurant_marker.png', 100),
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
  }

  Future<BitmapDescriptor> _getMarkerIcon(String assetPath, int size) async {
    try {
      final ByteData data = await rootBundle.load(assetPath);
      final ui.Codec codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: size,
      );
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ByteData? byteData = await frameInfo.image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      final Uint8List resizedData = byteData!.buffer.asUint8List();
      return BitmapDescriptor.fromBytes(resizedData);
    } catch (e) {
      return BitmapDescriptor.defaultMarker;
    }
  }

  void _onMarkerTapped(Restaurant restaurant, int index) {
    widget.controller.selectRestaurant(index);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RestaurantBottomSheetWidget(
        restaurant: restaurant,
        onClose: () {
          widget.controller.clearSelectedRestaurant();
          Navigator.pop(context);
        },
      ),
    );
  }

  void _animateToUserLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Location services are not enabled
        Get.snackbar('Location', 'Please enable location services');
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Get.snackbar('Location', 'Location permissions are denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Get.snackbar('Location', 'Location permissions are permanently denied');
        return;
      }

      // Get the raw position without geocoding
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude),
            15.0,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(widget.initialPosition, 15.0),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<ExploreController>(
        builder: (controller) {
          // Update markers when filtered restaurants change
          if (controller.filteredRestaurants != null) {
            _createMarkers();
          }

          return Stack(
            children: [
              // Full Screen Map
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: widget.initialPosition,
                  zoom: 14.0,
                ),
                markers: _markers,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                onMapCreated: (GoogleMapController mapController) {
                  _mapController = mapController;
                  controller.setMapController(mapController);
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

              // Floating Back Button
              Positioned(
                top: MediaQuery.of(context).padding.top + Dimensions.paddingSizeDefault,
                left: Dimensions.paddingSizeDefault,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(100),
                      onTap: () => Navigator.pop(context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Dimensions.paddingSizeDefault,
                          vertical: Dimensions.paddingSizeSmall + 2,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.arrow_back,
                              color: Theme.of(context).textTheme.bodyMedium!.color,
                              size: 20,
                            ),
                            const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                            Text(
                              'Back',
                              style: TextStyle(
                                color: Theme.of(context).textTheme.bodyMedium!.color,
                                fontWeight: FontWeight.w600,
                                fontSize: Dimensions.fontSizeDefault,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Map Controls (Location & Zoom) - Center Right
              Positioned(
                right: Dimensions.paddingSizeDefault,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // My Location Button
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          shape: CircleBorder(),
                          child: InkWell(
                            customBorder: CircleBorder(),
                            onTap: _animateToUserLocation,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Icon(
                                Icons.my_location,
                                color: Theme.of(context).primaryColor,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeSmall),
                      // Zoom In Button
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          shape: CircleBorder(),
                          child: InkWell(
                            customBorder: CircleBorder(),
                            onTap: () {
                              if (_mapController != null) {
                                _mapController!.animateCamera(
                                  CameraUpdate.zoomIn(),
                                );
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Icon(
                                Icons.add,
                                color: Theme.of(context).textTheme.bodyMedium!.color,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeSmall),
                      // Zoom Out Button
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          shape: CircleBorder(),
                          child: InkWell(
                            customBorder: CircleBorder(),
                            onTap: () {
                              if (_mapController != null) {
                                _mapController!.animateCamera(
                                  CameraUpdate.zoomOut(),
                                );
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Icon(
                                Icons.remove,
                                color: Theme.of(context).textTheme.bodyMedium!.color,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Category Filter Chips at Bottom
              GetBuilder<CategoryController>(
                builder: (categoryController) {
                  final categories = categoryController.categoryList;
                  if (categories != null && categories.isNotEmpty) {
                    return Positioned(
                      bottom: Dimensions.paddingSizeLarge,
                      left: 0,
                      right: 0,
                      child: SizedBox(
                        height: 40,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: Dimensions.paddingSizeDefault,
                          ),
                          itemCount: categories.length + 1,
                          itemBuilder: (context, index) {
                            final isAll = index == 0;
                            final category = isAll ? null : categories[index - 1];
                            final isSelected = isAll
                                ? controller.selectedCategoryId == null
                                : controller.selectedCategoryId == category?.id;

                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(100),
                                child: BackdropFilter(
                                  filter: isSelected
                                      ? ui.ImageFilter.blur(sigmaX: 0, sigmaY: 0)
                                      : ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: Opacity(
                                    opacity: isSelected ? 1.0 : 0.4,
                                    child: FilterChip(
                                      label: Text(
                                        isAll ? 'All' : category!.name ?? '',
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium!.color,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        controller.filterByCategory(isAll ? null : category?.id);
                                      },
                                      backgroundColor: isSelected
                                          ? Theme.of(context).primaryColor
                                          : Theme.of(context).cardColor.withValues(alpha: 0.3),
                                      selectedColor: Theme.of(context).primaryColor,
                                      side: BorderSide(
                                        color: isSelected
                                            ? Theme.of(context).primaryColor
                                            : Colors.transparent,
                                        width: isSelected ? 1 : 0,
                                      ),
                                      elevation: 0,
                                      shadowColor: Colors.transparent,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}