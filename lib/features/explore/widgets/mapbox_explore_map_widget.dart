import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as google;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:godelivery_user/common/models/restaurant_model.dart';
import 'package:godelivery_user/config/environment.dart';
import 'package:godelivery_user/features/explore/controllers/explore_controller.dart';
import 'package:godelivery_user/features/explore/widgets/restaurant_bottom_sheet_widget.dart';
import 'package:godelivery_user/common/widgets/shared/feedback/custom_snackbar_widget.dart';
import 'package:godelivery_user/features/splash/controllers/splash_controller.dart';
import 'package:godelivery_user/helper/business_logic/address_helper.dart';
import 'package:godelivery_user/helper/ui/map_utils.dart';
import 'package:godelivery_user/util/dimensions.dart';

class MapboxExploreMapWidget extends StatefulWidget {
  final ExploreController exploreController;
  final VoidCallback? onFullscreenToggle;
  final Animation<Offset>? topButtonsAnimation;
  final Animation<double>? topButtonsFadeAnimation;

  const MapboxExploreMapWidget({
    super.key,
    required this.exploreController,
    this.onFullscreenToggle,
    this.topButtonsAnimation,
    this.topButtonsFadeAnimation,
  });

  @override
  State<MapboxExploreMapWidget> createState() => _MapboxExploreMapWidgetState();
}

class _MapboxExploreMapWidgetState extends State<MapboxExploreMapWidget> {
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _markerManager;
  google.LatLng? _initialPosition;
  int _lastRestaurantCount = -1;

  // Track annotations for tap handling
  final Map<String, int> _annotationToRestaurantIndex = {};
  Uint8List? _restaurantMarkerBytes;
  Uint8List? _userLocationMarkerBytes;
  bool _mapReady = false;
  bool _styleReady = false;
  Timer? _idleTimer;

  @override
  void initState() {
    super.initState();
    MapboxOptions.setAccessToken(Environment.mapboxToken);
    _initializeMap();
    _loadMarkerImages();
  }

  void _initializeMap() {
    // Priority: 1) Saved map position, 2) User address, 3) Default location
    if (widget.exploreController.savedMapPosition != null) {
      _initialPosition = widget.exploreController.savedMapPosition;
      return;
    }

    // Fall back to user's current address
    final addressModel = AddressHelper.getAddressFromSharedPref();
    if (addressModel != null &&
        addressModel.latitude != null &&
        addressModel.longitude != null) {
      _initialPosition = google.LatLng(
        double.parse(addressModel.latitude!),
        double.parse(addressModel.longitude!),
      );
    } else {
      // Fall back to default location
      _initialPosition = google.LatLng(
        double.parse(Get.find<SplashController>().configModel!.defaultLocation!.lat ?? '37.7749'),
        double.parse(Get.find<SplashController>().configModel!.defaultLocation!.lng ?? '-122.4194'),
      );
    }
  }

  Future<void> _loadMarkerImages() async {
    try {
      // Create emoji markers
      _userLocationMarkerBytes = await _createEmojiMarkerIcon('📍', size: 120);
      _restaurantMarkerBytes = await _createEmojiMarkerIcon('🍎', size: 120);
    } catch (e) {
      debugPrint('Error creating marker images: $e');
    }
  }

  /// Create a marker icon image from an emoji
  Future<Uint8List> _createEmojiMarkerIcon(String emoji, {double size = 100}) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);

    // Draw emoji
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: emoji,
      style: TextStyle(fontSize: size),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset.zero);

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(
      textPainter.width.toInt(),
      textPainter.height.toInt(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;

    // Hide map ornaments
    mapboxMap.logo.updateSettings(LogoSettings(enabled: false));
    mapboxMap.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
    mapboxMap.attribution.updateSettings(AttributionSettings(enabled: false));

    // Enable gestures
    mapboxMap.gestures.updateSettings(GesturesSettings(
      scrollEnabled: true,
      rotateEnabled: false,
      pinchToZoomEnabled: true,
      doubleTapToZoomInEnabled: true,
      doubleTouchToZoomOutEnabled: true,
      quickZoomEnabled: true,
      pitchEnabled: false,
    ));

    // Create marker annotation manager
    _markerManager = await mapboxMap.annotations.createPointAnnotationManager();

    // Set up tap listener
    _markerManager?.addOnPointAnnotationClickListener(
      _MarkerClickListener(onMarkerTapped: _onAnnotationTapped),
    );

    _mapReady = true;
    widget.exploreController.setMapboxMap(mapboxMap);

    // Create markers if restaurants are already loaded
    if (widget.exploreController.filteredRestaurants != null && _styleReady) {
      _createMarkers();
    }
  }

  void _onStyleLoaded(StyleLoadedEventData eventData) {
    _styleReady = true;

    // Create markers if map is also ready and restaurants are loaded
    if (_mapReady && widget.exploreController.filteredRestaurants != null) {
      _createMarkers();
    }
  }

  void _onCameraChange(CameraChangedEventData eventData) {
    // Get current camera state and update controller
    _mapboxMap?.getCameraState().then((cameraState) {
      final googleLatLng = MapUtils.pointToGoogleLatLng(cameraState.center);
      widget.exploreController.updateMapPosition(googleLatLng, cameraState.zoom);
    });

    // Debounce idle detection
    _idleTimer?.cancel();
    _idleTimer = Timer(const Duration(milliseconds: 100), () {
      // Camera idle - could trigger additional actions if needed
    });
  }

  Future<void> _createMarkers() async {
    if (_markerManager == null || !_mapReady || !_styleReady) return;

    // Log restaurant data
    final restaurants = widget.exploreController.filteredRestaurants;
    print('🗺️ [MAPBOX EXPLORE] Creating markers...');
    print('🗺️ [MAPBOX EXPLORE] Filtered restaurants count: ${restaurants?.length ?? 0}');
    if (restaurants != null && restaurants.isNotEmpty) {
      for (int i = 0; i < restaurants.length && i < 3; i++) {
        final r = restaurants[i];
        print('🗺️ [MAPBOX EXPLORE] Restaurant $i: ${r.name}, lat: ${r.latitude}, lng: ${r.longitude}, logo: ${r.logoFullUrl}');
      }
      if (restaurants.length > 3) {
        print('🗺️ [MAPBOX EXPLORE] ... and ${restaurants.length - 3} more restaurants');
      }
    }

    // Clear existing markers
    await _markerManager!.deleteAll();
    _annotationToRestaurantIndex.clear();

    try {
      // Add user location marker
      if (_initialPosition != null && _userLocationMarkerBytes != null) {
        await _markerManager!.create(
          PointAnnotationOptions(
            geometry: Point(
              coordinates: Position(
                _initialPosition!.longitude,
                _initialPosition!.latitude,
              ),
            ),
            image: _userLocationMarkerBytes,
            iconSize: 0.5,
          ),
        );
      }

      // Add restaurant markers
      if (widget.exploreController.filteredRestaurants != null &&
          _restaurantMarkerBytes != null) {
        for (int i = 0; i < widget.exploreController.filteredRestaurants!.length; i++) {
          final restaurant = widget.exploreController.filteredRestaurants![i];
          if (restaurant.latitude != null && restaurant.longitude != null) {
            final annotation = await _markerManager!.create(
              PointAnnotationOptions(
                geometry: Point(
                  coordinates: Position(
                    double.parse(restaurant.longitude!),
                    double.parse(restaurant.latitude!),
                  ),
                ),
                image: _restaurantMarkerBytes,
                iconSize: 0.5,
              ),
            );

            // Store mapping from annotation ID to restaurant index
            _annotationToRestaurantIndex[annotation.id] = i;
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

  void _onAnnotationTapped(PointAnnotation annotation) {
    final index = _annotationToRestaurantIndex[annotation.id];
    if (index != null &&
        widget.exploreController.filteredRestaurants != null &&
        index < widget.exploreController.filteredRestaurants!.length) {
      final restaurant = widget.exploreController.filteredRestaurants![index];
      _onMarkerTapped(restaurant, index);
    }
  }

  void _onMarkerTapped(Restaurant restaurant, int index) {
    widget.exploreController.selectRestaurant(index);

    // If not in fullscreen mode, trigger fullscreen first, then show card
    if (!widget.exploreController.isFullscreenMode) {
      widget.onFullscreenToggle?.call();

      // Wait for fullscreen animation to complete before showing card
      Future.delayed(const Duration(milliseconds: 550), () {
        if (mounted) {
          _showRestaurantBottomSheet(index);
        }
      });
    } else {
      // Already in fullscreen, show card immediately
      _showRestaurantBottomSheet(index);
    }
  }

  void _showRestaurantBottomSheet(int initialIndex) {
    final restaurants = widget.exploreController.filteredRestaurants;
    if (restaurants == null || restaurants.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RestaurantBottomSheetWidget(
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
          if (_mapboxMap != null &&
              restaurant.latitude != null &&
              restaurant.longitude != null) {
            _mapboxMap!.flyTo(
              CameraOptions(
                center: Point(
                  coordinates: Position(
                    double.parse(restaurant.longitude!),
                    double.parse(restaurant.latitude!),
                  ),
                ),
              ),
              MapAnimationOptions(duration: 300),
            );
          }
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
                : MapWidget(
                    key: const ValueKey('mapbox_explore_map'),
                    styleUri: Get.isDarkMode
                        ? MapboxStyles.DARK
                        : MapboxStyles.STANDARD,
                    cameraOptions: CameraOptions(
                      center: Point(
                        coordinates: Position(
                          _initialPosition!.longitude,
                          _initialPosition!.latitude,
                        ),
                      ),
                      zoom: widget.exploreController.savedMapZoom ?? 14.0,
                    ),
                    onMapCreated: _onMapCreated,
                    onStyleLoadedListener: _onStyleLoaded,
                    onCameraChangeListener: _onCameraChange,
                  ),

            // My Location Button
            Positioned(
              bottom: Dimensions.paddingSizeDefault,
              right: Dimensions.paddingSizeDefault,
              child: FloatingActionButton(
                heroTag: 'explore_my_location_mapbox',
                mini: true,
                backgroundColor: Theme.of(context).cardColor,
                onPressed: _handleMyLocationTap,
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

  Future<void> _handleMyLocationTap() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await geolocator.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        showCustomSnackBar('Please enable location services');
        return;
      }

      // Check location permission
      geolocator.LocationPermission permission = await geolocator.Geolocator.checkPermission();
      if (permission == geolocator.LocationPermission.denied) {
        permission = await geolocator.Geolocator.requestPermission();
        if (permission == geolocator.LocationPermission.denied) {
          showCustomSnackBar('Location permissions are denied');
          return;
        }
      }

      if (permission == geolocator.LocationPermission.deniedForever) {
        showCustomSnackBar('Location permissions are permanently denied');
        return;
      }

      // Get the raw position without geocoding
      geolocator.Position geoPosition = await geolocator.Geolocator.getCurrentPosition(
        locationSettings: const geolocator.LocationSettings(
          accuracy: geolocator.LocationAccuracy.high,
        ),
      );

      if (_mapboxMap != null) {
        // Animate camera to user's location
        _mapboxMap!.flyTo(
          CameraOptions(
            center: Point(
              coordinates: Position(geoPosition.longitude, geoPosition.latitude),
            ),
            zoom: 15.0,
          ),
          MapAnimationOptions(duration: 500),
        );

        // Update the user location marker
        if (mounted) {
          setState(() {
            _initialPosition = google.LatLng(geoPosition.latitude, geoPosition.longitude);
          });
          _createMarkers();
        }
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      // Fallback to the existing location if available
      if (_initialPosition != null && _mapboxMap != null) {
        _mapboxMap!.flyTo(
          CameraOptions(
            center: Point(
              coordinates: Position(
                _initialPosition!.longitude,
                _initialPosition!.latitude,
              ),
            ),
            zoom: 15.0,
          ),
          MapAnimationOptions(duration: 500),
        );
      }
    }
  }

  Widget _buildTopButtons(BuildContext context, ExploreController controller) {
    return Stack(
      children: [
        // Search/Filter Indicator (always visible, animates with topButtonsAnimation)
        Positioned(
          top: MediaQuery.of(context).padding.top + Dimensions.paddingSizeDefault,
          left: Dimensions.paddingSizeDefault,
          right: Dimensions.paddingSizeDefault,
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
                  color: Colors.black.withValues(alpha: 0.1),
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
                const SizedBox(width: Dimensions.paddingSizeSmall),
                // Fullscreen Button inside badge
                InkWell(
                  onTap: widget.onFullscreenToggle,
                  borderRadius: BorderRadius.circular(100),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      controller.isFullscreenMode ? Icons.fullscreen_exit : Icons.fullscreen,
                      color: Theme.of(context).primaryColor,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _markerManager = null;
    _mapboxMap = null;
    super.dispose();
  }
}

/// Listener for marker tap events
class _MarkerClickListener extends OnPointAnnotationClickListener {
  final void Function(PointAnnotation) onMarkerTapped;

  _MarkerClickListener({required this.onMarkerTapped});

  @override
  void onPointAnnotationClick(PointAnnotation annotation) {
    onMarkerTapped(annotation);
  }
}
