import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:godelivery_user/common/widgets/shared/buttons/circular_back_button_widget.dart';
import 'package:godelivery_user/common/widgets/shared/buttons/custom_tabbed_button.dart';
import 'package:godelivery_user/common/widgets/shared/feedback/custom_toast_widget.dart';
import 'package:godelivery_user/common/widgets/mobile/draggable_bottom_sheet_widget.dart';
import 'package:godelivery_user/common/widgets/shared/sheets/custom_sheet.dart';
import 'package:godelivery_user/features/splash/controllers/splash_controller.dart';
import 'package:godelivery_user/features/address/domain/models/address_model.dart';
import 'package:godelivery_user/features/address/controllers/address_controller.dart';
import 'package:godelivery_user/features/auth/controllers/auth_controller.dart';
import 'package:godelivery_user/features/location/controllers/location_controller.dart';
import 'package:godelivery_user/features/location/domain/models/zone_list_model.dart';
import 'package:godelivery_user/features/location/helper/zone_polygon_helper.dart';
import 'package:godelivery_user/features/location/helper/mapbox_zone_polygon_helper.dart';
import 'package:godelivery_user/features/location/widgets/permission_dialog.dart';
import 'package:godelivery_user/features/location/widgets/mapbox_pick_map_widget.dart';
import 'package:godelivery_user/config/environment.dart';
import 'package:godelivery_user/features/location/widgets/zone_list_widget.dart';
import 'package:godelivery_user/features/location/widgets/location_manager_sheet.dart';
import 'package:godelivery_user/features/location/widgets/location_permission_overlay.dart';
import 'package:godelivery_user/features/location/widgets/zone_floating_badge.dart';
import 'package:godelivery_user/features/location/widgets/address_floating_badge.dart';
import 'package:godelivery_user/features/splash/controllers/theme_controller.dart';
import 'package:godelivery_user/helper/business_logic/address_helper.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:godelivery_user/helper/ui/responsive_helper.dart';
import 'package:godelivery_user/util/app_constants.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/images.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:godelivery_user/common/widgets/shared/buttons/custom_button_widget.dart';
import 'package:godelivery_user/common/widgets/web/web_menu_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Map mode enum
enum MapMode {
  zoneSelection,
  addressSelection,
}

class PickMapScreen extends StatefulWidget {
  final bool fromSignUp;
  final bool fromSplash;
  final bool fromAddAddress;
  final bool canRoute;
  final String? route;
  final GoogleMapController? googleMapController;
  final bool showZonePolygons;
  /// Callback when user confirms zone selection in zone mode.
  /// If provided, this callback is called instead of returning via Get.back().
  final Function(ZoneListModel zone)? onZoneSelected;

  const PickMapScreen({
    super.key, required this.fromSignUp, required this.fromAddAddress, required this.canRoute,
    required this.route, this.googleMapController, required this.fromSplash,
    this.showZonePolygons = true,
    this.onZoneSelected,
  });

  @override
  State<PickMapScreen> createState() => _PickMapScreenState();
}

class _PickMapScreenState extends State<PickMapScreen> with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  final GlobalKey<MapboxPickMapWidgetState> _mapboxKey = GlobalKey<MapboxPickMapWidgetState>();
  CameraPosition? _cameraPosition;
  late LatLng _initialPosition;
  bool _showLocationPermissionOverlay = false;
  int? _currentZoneId;
  late AnimationController _pinBounceController;
  late Animation<double> _pinBounceAnimation;
  late AnimationController _badgeBounceController;
  late Animation<double> _badgeBounceAnimation;
  late AnimationController _tapPromptWiggleController;
  late Animation<double> _tapPromptWiggleAnimation;
  late AnimationController _tapPromptBounceController;  // Uses sin() directly for smooth wiggle
  Timer? _tapPromptTimer;
  late MapMode _currentMode;  // Set in initState based on address state
  bool _isAddingNewAddress = false;  // Track if user is in "add new address" mode
  int? _selectedZoneId;  // For zone selection mode
  LatLng? _selectedZoneCenter;  // Center position of selected zone
  String? _selectedZoneName;  // Name of selected zone
  bool _mapAnimationComplete = false;  // Track when globe animation is done
  bool _isMapTouched = false;  // Track if user is touching the map
  Timer? _geocodeDebounceTimer;  // Debounce timer for geocoding
  MapAnimationMode _mapAnimationMode = MapAnimationMode.quick;  // Default to quick, will be set in initState
  int? _savedZoneIdForAnimation;  // Zone ID to fly to directly during animation
  List<AddressModel> _cachedCombinedAddressList = [];  // Cached combined address list to prevent constant rebuilds

  @override
  void initState() {
    super.initState();

    // Check for saved zone ID early (before zones load) for animation targeting
    final savedAddress = AddressHelper.getAddressFromSharedPref();
    if (savedAddress != null && savedAddress.zoneId != null && savedAddress.zoneId != 0) {
      _savedZoneIdForAnimation = savedAddress.zoneId;
      _selectedZoneId = savedAddress.zoneId;  // Also pre-select it
      print('🗺️ [PICK_MAP] Found saved zone ID for animation: $_savedZoneIdForAnimation');
    }

    // Determine initial mode based on whether user has a "real" address
    if (AddressHelper.hasRealAddress()) {
      _currentMode = MapMode.addressSelection;
      print('🗺️ [PICK_MAP] User has real address - starting in Address mode');

      // If user has address with coordinates, fly to it instead of zone
      if (savedAddress != null &&
          savedAddress.latitude != null &&
          savedAddress.longitude != null) {
        final lat = double.tryParse(savedAddress.latitude!);
        final lng = double.tryParse(savedAddress.longitude!);
        if (lat != null && lng != null) {
          _initialPosition = LatLng(lat, lng);
          print('🗺️ [PICK_MAP] Flying to saved address: $lat, $lng');
        }
      }
    } else {
      _currentMode = MapMode.zoneSelection;
      print('🗺️ [PICK_MAP] No real address - starting in Zone mode');
    }

    // Determine animation mode based on whether user has seen full animation
    _determineAnimationMode();

    // Initialize pin bounce animation
    _pinBounceController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _pinBounceAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.15)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.15, end: 0.95)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.95, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_pinBounceController);

    // Initialize badge bounce animation (spring-like)
    _badgeBounceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _badgeBounceAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.2)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 0.9)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.9, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_badgeBounceController);

    // Initialize tap prompt animations
    _tapPromptWiggleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Scale pop animation with bouncy curve
    _tapPromptWiggleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _tapPromptWiggleController,
      curve: Curves.elasticOut,
    ));

    // Gentle float animation - continuous vertical bob
    _tapPromptBounceController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    Get.find<LocationController>().makeLoadingOff();

    // Start float animation after build (delayed to ensure widget is ready)
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _currentMode == MapMode.zoneSelection && _selectedZoneId == null) {
        _tapPromptBounceController.repeat(reverse: true);
      }
    });

    // No location permissions needed - map is for zone selection only
    _showLocationPermissionOverlay = false;

    // Call after build to avoid setState during build error
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<LocationController>().getZoneList().then((_) {
        // After zones are loaded, check if user has a saved zone and pre-select it
        _checkAndSelectSavedZone();
      });
    });

    if(widget.fromAddAddress) {
      Get.find<LocationController>().setPickData();
    }
    // Center around Shefa-Amr (Northern Israel service area)
    _initialPosition = const LatLng(32.82461934938776, 35.14441039413214);
  }

  /// Check if user has a saved address with zone and fill in zone details
  void _checkAndSelectSavedZone() {
    if (_selectedZoneId == null) return;  // No saved zone

    final locationController = Get.find<LocationController>();
    final savedZone = locationController.zoneList.firstWhereOrNull(
      (zone) => zone.id == _selectedZoneId,
    );

    if (savedZone != null) {
      print('🗺️ [PICK_MAP] Filling in saved zone details: ${savedZone.displayName ?? savedZone.name} (ID: $_selectedZoneId)');
      setState(() {
        _selectedZoneName = savedZone.displayName ?? savedZone.name ?? 'Zone $_selectedZoneId';
        if (savedZone.formattedCoordinates != null) {
          _selectedZoneCenter = _calculateZoneCenter(savedZone.formattedCoordinates!);
        }
      });
    }
  }

  @override
  void dispose() {
    _pinBounceController.dispose();
    _badgeBounceController.dispose();
    _tapPromptWiggleController.dispose();
    _tapPromptBounceController.dispose();
    _tapPromptTimer?.cancel();
    _geocodeDebounceTimer?.cancel();
    super.dispose();
  }

  /// Check if it's nighttime (6 PM to 6 AM)
  bool _isNightTime() {
    final hour = DateTime.now().hour;
    return hour >= 18 || hour < 6;
  }

  /// Determine which animation mode to use based on whether user has seen full animation
  void _determineAnimationMode() {
    final prefs = Get.find<SharedPreferences>();
    final hasSeenFullAnimation = prefs.getBool(AppConstants.hasSeenMapGlobeAnimation) ?? false;

    if (hasSeenFullAnimation) {
      // Returning user - use quick fly-in animation
      _mapAnimationMode = MapAnimationMode.quick;
    } else {
      // First time user (after onboarding) - use full spinning globe animation
      _mapAnimationMode = MapAnimationMode.full;
    }
    print('🗺️ [PICK_MAP] Animation mode: $_mapAnimationMode (hasSeenFull: $hasSeenFullAnimation)');
  }

  /// Mark that user has seen the full globe animation
  void _markFullAnimationAsSeen() {
    final prefs = Get.find<SharedPreferences>();
    prefs.setBool(AppConstants.hasSeenMapGlobeAnimation, true);
    print('🗺️ [PICK_MAP] Marked full animation as seen');
  }

  /// Handle geocoding when user releases the map (pin drop)
  void _onMapTouchEnd() {
    setState(() {
      _isMapTouched = false;
    });

    // Trigger geocode when user releases touch (if in address adding mode)
    if (_cameraPosition != null && _currentMode == MapMode.addressSelection && _isAddingNewAddress) {
      _geocodeDebounceTimer?.cancel();
      _geocodeDebounceTimer = Timer(const Duration(milliseconds: 300), () {
        _triggerGeocode();
        _pinBounceController.forward(from: 0.0);
        _badgeBounceController.forward(from: 0.0);
      });
    }
  }

  /// Trigger geocoding for the current camera position
  void _triggerGeocode() {
    if (_cameraPosition == null || _currentMode != MapMode.addressSelection || !_isAddingNewAddress) {
      return;
    }

    final position = _cameraPosition!;

    // Check if inside a zone
    final zoneId = ZonePolygonHelper.getZoneIdForPoint(
      position.target,
      Get.find<LocationController>().zoneList,
    );

    if (zoneId != null) {
      Get.find<LocationController>().updatePosition(position, false);
    } else {
      // Clear address if pin is outside all zones (hides tooltip)
      Get.find<LocationController>().clearPickAddress();
    }
  }

  /// Trigger the tap prompt animation
  void _triggerTapPromptAnimation() {
    if (!_tapPromptWiggleController.isAnimating && !_tapPromptBounceController.isAnimating) {
      // Scale pop
      _tapPromptWiggleController.forward(from: 0.0).then((_) {
        _tapPromptWiggleController.reverse();
      });
      // Smooth wiggle rotation - uses sine wave so only forward needed
      _tapPromptBounceController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: ResponsiveHelper.isDesktop(context) ? const WebMenuBar() : null,
        body: WillPopScope(
          onWillPop: () async => !widget.fromSplash,
          child: SafeArea(
            top: false,
            bottom: false,
            child: Center(
              child: SizedBox(
                width: Dimensions.webMaxWidth,
                child: GetBuilder<LocationController>(builder: (locationController) {
                  return Stack(
                    children: [
                      // Conditional map rendering based on MAP_PROVIDER env
                      if (Environment.useMapbox)
                        Listener(
                          onPointerDown: (_) {
                            setState(() {
                              _isMapTouched = true;
                            });
                          },
                          onPointerUp: (_) => _onMapTouchEnd(),
                          onPointerCancel: (_) => _onMapTouchEnd(),
                          child: MapboxPickMapWidget(
                          key: _mapboxKey,
                          initialPosition: _initialPosition,
                          initialZoom: 10.43,
                          minZoom: 6.5,
                          maxZoom: 14,
                          zones: locationController.zoneList,
                          highlightedZoneId: _currentMode == MapMode.zoneSelection
                              ? _selectedZoneId
                              : AddressHelper.getAddressFromSharedPref()?.zoneId,  // Always show user's saved zone in address mode
                          savedZoneId: _savedZoneIdForAnimation,
                          savedAddresses: _currentMode == MapMode.addressSelection
                              ? _buildCombinedAddressList()
                              : [],
                          zoneBaseColor: Theme.of(context).colorScheme.primary,
                          isDarkMode: false,  // Always use light/day mode
                          animationMode: _mapAnimationMode,
                          onMapCreated: () {
                            _currentZoneId = null;
                            print('════════════════════════════════════════════');
                            print('🚀 MAPBOX MAP CREATED');
                            print('────────────────────────────────────────────');
                            print('Latitude:  ${_initialPosition.latitude}');
                            print('Longitude: ${_initialPosition.longitude}');
                            print('Zoom:      10.43');
                            print('════════════════════════════════════════════');
                          },
                          onCameraMoveStarted: () {
                            locationController.disableButton();
                          },
                          onCameraMove: (CameraPosition cameraPosition) {
                            _cameraPosition = cameraPosition;
                          },
                          onCameraIdle: () {
                            if (_cameraPosition != null && _currentMode == MapMode.addressSelection && _isAddingNewAddress) {
                              // Only geocode if user has released touch
                              if (!_isMapTouched) {
                                // Cancel any pending geocode and debounce
                                _geocodeDebounceTimer?.cancel();
                                _geocodeDebounceTimer = Timer(const Duration(milliseconds: 300), () {
                                  _triggerGeocode();
                                  // Bounce animations when geocode triggers
                                  _pinBounceController.forward(from: 0.0);
                                  _badgeBounceController.forward(from: 0.0);
                                });
                              }
                            }
                          },
                          onZoneTap: (zoneId) {
                            if (_currentMode == MapMode.zoneSelection) {
                              final selectedZone = locationController.zoneList.firstWhereOrNull(
                                (zone) => zone.id == zoneId,
                              );
                              if (selectedZone != null) {
                                setState(() {
                                  _selectedZoneId = zoneId;
                                  _selectedZoneName = selectedZone.displayName ?? selectedZone.name ?? 'Zone $zoneId';
                                  if (selectedZone.formattedCoordinates != null) {
                                    _selectedZoneCenter = _calculateZoneCenter(selectedZone.formattedCoordinates!);
                                  }
                                });
                              }
                              _moveToZoneCenter(zoneId, locationController.zoneList);
                            }
                          },
                          onAnimationComplete: () {
                            setState(() {
                              _mapAnimationComplete = true;
                            });
                            // Mark full animation as seen so next time we use quick animation
                            if (_mapAnimationMode == MapAnimationMode.full) {
                              _markFullAnimationAsSeen();
                            }
                            // Note: If savedZoneId was set, animation already flew directly to zone
                            // No need to zoom again
                          },
                        ),
                        )
                      else
                        Listener(
                          onPointerDown: (_) {
                            setState(() {
                              _isMapTouched = true;
                            });
                          },
                          onPointerUp: (_) => _onMapTouchEnd(),
                          onPointerCancel: (_) => _onMapTouchEnd(),
                          child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: _initialPosition,
                            zoom: 10.43,  // Zoom level to show Northern Israel service area
                          ),
                          minMaxZoomPreference: const MinMaxZoomPreference(6.5, 14),  // Limited zoom for zone selection
                          polygons: _zonePolygons(locationController, context, _isAddingNewAddress),
                          markers: _currentMode == MapMode.addressSelection
                              ? _buildSavedAddressMarkers(locationController)
                              : <Marker>{},
                          onMapCreated: (GoogleMapController mapController) {
                            _mapController = mapController;

                            // Map is for zone selection only, no automatic location requests
                            // Initialize without setting any specific zone as current
                            _currentZoneId = null;

                            // Log initial map position
                            print('════════════════════════════════════════════');
                            print('🚀 INITIAL MAP POSITION & ZOOM LEVEL');
                            print('────────────────────────────────────────────');
                            print('Latitude:  ${_initialPosition.latitude}');
                            print('Longitude: ${_initialPosition.longitude}');
                            print('Zoom:      10.43');
                            print('════════════════════════════════════════════');
                          },
                          zoomControlsEnabled: false,
                          onCameraMove: (CameraPosition cameraPosition) {
                            _cameraPosition = cameraPosition;
                          },
                          onCameraMoveStarted: () {
                            locationController.disableButton();
                          },
                          onCameraIdle: () {
                            if (_cameraPosition != null && _currentMode == MapMode.addressSelection && _isAddingNewAddress) {
                              // Only geocode if user has released touch
                              if (!_isMapTouched) {
                                // Cancel any pending geocode and debounce
                                _geocodeDebounceTimer?.cancel();
                                _geocodeDebounceTimer = Timer(const Duration(milliseconds: 300), () {
                                  _triggerGeocode();
                                  // Bounce animations when geocode triggers
                                  _pinBounceController.forward(from: 0.0);
                                  _badgeBounceController.forward(from: 0.0);
                                });
                              }
                            }
                          },
                          style: _isNightTime()
                              ? Get.find<ThemeController>().darkMap
                              : Get.find<ThemeController>().lightMap,
                          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                            Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
                            Factory<PanGestureRecognizer>(() => PanGestureRecognizer()),
                            Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()),
                            Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
                            Factory<VerticalDragGestureRecognizer>(() => VerticalDragGestureRecognizer()),
                          },
                        ),
                        ),
                      // Top gradient
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 160,
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.85),
                                  Colors.black.withOpacity(0.65),
                                  Colors.black.withOpacity(0.45),
                                  Colors.black.withOpacity(0.25),
                                  Colors.black.withOpacity(0.10),
                                  Colors.black.withOpacity(0.0),
                                ],
                                stops: const [0.0, 0.25, 0.45, 0.65, 0.85, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Bottom gradient
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 200,
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withOpacity(0.85),
                                  Colors.black.withOpacity(0.65),
                                  Colors.black.withOpacity(0.45),
                                  Colors.black.withOpacity(0.25),
                                  Colors.black.withOpacity(0.10),
                                  Colors.black.withOpacity(0.0),
                                ],
                                stops: const [0.0, 0.25, 0.45, 0.65, 0.85, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Zone badge overlay - disabled for now in zone mode
                      // Pin marker - only show in address selection mode
                      // Pin icon - only show when adding new address
                      if (_currentMode == MapMode.addressSelection && _isAddingNewAddress)
                        IgnorePointer(
                          child: Center(
                            child: AnimatedBuilder(
                              animation: _pinBounceAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _pinBounceAnimation.value,
                                  child: child,
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 36.0),
                                child: Icon(
                                  Icons.location_on,
                                  size: 48,
                                  color: Theme.of(context).colorScheme.primary,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Address Badge for address mode only (floating above pin) - only when adding new address
                      if (_currentMode == MapMode.addressSelection &&
                          _isAddingNewAddress &&
                          locationController.pickAddress != null &&
                          locationController.pickAddress!.isNotEmpty)
                        Positioned(
                          left: 0,
                          right: 0,
                          top: (MediaQuery.of(context).size.height / 2) - 100,
                          child: IgnorePointer(
                            child: Center(
                              child: AnimatedBuilder(
                                animation: _badgeBounceAnimation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _badgeBounceAnimation.value,
                                    child: Opacity(
                                      opacity: _badgeBounceAnimation.value.clamp(0.0, 1.0),
                                      child: child,
                                    ),
                                  );
                                },
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      constraints: BoxConstraints(
                                        maxWidth: MediaQuery.of(context).size.width - 48,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: Dimensions.paddingSizeDefault,
                                        vertical: Dimensions.paddingSizeSmall,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(100),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.15),
                                            blurRadius: 15,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.location_on,
                                            size: 18,
                                            color: Theme.of(context).primaryColor,
                                          ),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: Text(
                                              _getDisplayAddress(locationController.pickAddress ?? ''),
                                              style: robotoBold.copyWith(
                                                fontSize: Dimensions.fontSizeDefault,
                                                color: Colors.black,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Arrow pointer
                                    Transform.translate(
                                      offset: const Offset(0, -6),
                                      child: Transform.rotate(
                                        angle: 0.785398,
                                        child: Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.1),
                                                blurRadius: 4,
                                                offset: const Offset(1, 1),
                                              ),
                                            ],
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
                      if (!widget.fromSplash)
                        Positioned(
                          top: MediaQuery.of(context).viewPadding.top + Dimensions.paddingSizeDefault,
                          left: Dimensions.paddingSizeDefault,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: CircularBackButtonWidget(
                              showText: false,
                              backgroundColor: Theme.of(context).cardColor,
                            ),
                          ),
                        ),
                      // Hopa logo
                      Positioned(
                        top: MediaQuery.of(context).viewPadding.top + Dimensions.paddingSizeSmall + 8,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Image.asset(
                            Images.hopaWhiteLogo,
                            height: 32,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      // Zone count text below logo
                      Positioned(
                        top: MediaQuery.of(context).viewPadding.top + Dimensions.paddingSizeSmall + 44, // 8 + 32 (logo) + 4 spacing
                        left: 0,
                        right: 0,
                        child: Center(
                          child: RichText(
                            text: TextSpan(
                              style: robotoMedium.copyWith(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.9),
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.5),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              children: [
                                TextSpan(
                                  text: '${locationController.zoneList?.length ?? 0}',
                                  style: robotoBold.copyWith(
                                    fontSize: 17,
                                    color: Theme.of(context).primaryColor,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.5),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                                TextSpan(
                                  text: ' ${'service_zones_available'.tr}',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Mode toggle selector - fades in after map animation
                      Positioned(
                        top: MediaQuery.of(context).viewPadding.top + Dimensions.paddingSizeSmall + 88,
                        left: 0,
                        right: 0,
                        child: AnimatedOpacity(
                          opacity: (!Environment.useMapbox || _mapAnimationComplete) ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOut,
                          child: Center(
                            child: IgnorePointer(
                              ignoring: Environment.useMapbox && !_mapAnimationComplete,
                              child: CustomTabbedButton(
                                items: [
                                  const TabbedButtonItem(label: 'Zone', icon: Icons.map),
                                  TabbedButtonItem(
                                    label: 'Address',
                                    icon: Icons.location_on,
                                    showBadge: !AddressHelper.hasRealAddress(),
                                  ),
                                ],
                                selectedIndex: _currentMode == MapMode.zoneSelection ? 0 : 1,
                                onTabChanged: (index) {
                                  setState(() {
                                    _currentMode = index == 0 ? MapMode.zoneSelection : MapMode.addressSelection;
                                    if (_currentMode == MapMode.zoneSelection) {
                                      // Reset zone selection
                                      _currentZoneId = null;
                                      _selectedZoneId = null;
                                      _selectedZoneName = null;
                                      _selectedZoneCenter = null;
                                    }
                                  });
                                },
                                style: TabbedButtonStyle.dark,
                                width: 160,
                                height: 35,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // User's current saved zone display - above the floating badge in Zone mode
                      if (_currentMode == MapMode.zoneSelection)
                        Positioned(
                          bottom: 220, // Position above zone badge + buttons
                          left: 0,
                          right: 0,
                          child: Center(
                            child: AnimatedOpacity(
                              opacity: _mapAnimationComplete ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 400),
                              child: _buildCurrentZoneBadge(context, locationController),
                            ),
                          ),
                        ),
                      // Bottom controls based on mode
                      if (_currentMode == MapMode.zoneSelection)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: SafeArea(
                            child: _selectedZoneId != null
                                ? ZoneFloatingBadge(
                                    key: const ValueKey('zone_floating_badge'),
                                    selectedZone: locationController.zoneList?.firstWhereOrNull(
                                      (zone) => zone.id == _selectedZoneId,
                                    ),
                                    zones: locationController.zoneList ?? [],
                                    userSavedZoneId: AddressHelper.getAddressFromSharedPref()?.zoneId,
                                    onZoneChanged: (zone) {
                                      if (zone != null) {
                                        // Don't rebuild immediately, just update the selection
                                        _selectedZoneId = zone.id;
                                        _selectedZoneName = zone.displayName ?? zone.name ?? 'Zone ${zone.id}';
                                        if (zone.formattedCoordinates != null) {
                                          _selectedZoneCenter = _calculateZoneCenter(zone.formattedCoordinates!);
                                        }
                                        // Move camera without setState to avoid rebuild
                                        _moveToZoneCenter(zone.id!, locationController.zoneList ?? []);
                                      }
                                    },
                                    onConfirm: () => _onZoneSelected(locationController),
                                  )
                                : AnimatedOpacity(
                                    opacity: (!Environment.useMapbox || _mapAnimationComplete) ? 1.0 : 0.0,
                                    duration: const Duration(milliseconds: 500),
                                    curve: Curves.easeOut,
                                    child: AnimatedBuilder(
                                      animation: _tapPromptBounceController,
                                      builder: (context, child) {
                                        // Gentle float: vertical bob with subtle scale
                                        final t = _tapPromptBounceController.value;
                                        final floatOffset = -8.0 * Curves.easeInOut.transform(t);
                                        final scale = 1.0 + (0.02 * Curves.easeInOut.transform(t));
                                        return Transform.translate(
                                          offset: Offset(0, floatOffset),
                                          child: Transform.scale(
                                            scale: scale,
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.only(bottom: 40),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: Dimensions.paddingSizeExtraLarge,
                                          vertical: Dimensions.paddingSizeLarge,
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Tap your ',
                                              style: robotoMedium.copyWith(
                                                fontSize: 20,
                                                color: Colors.white.withOpacity(0.9),
                                                shadows: [
                                                  Shadow(
                                                    color: Colors.black.withOpacity(0.5),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 1),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Icon(
                                              Icons.location_on,
                                              size: 26,
                                              color: Theme.of(context).primaryColor,
                                              shadows: [
                                                Shadow(
                                                  color: Colors.black.withOpacity(0.5),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 1),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              ' zone to get started!',
                                              style: robotoMedium.copyWith(
                                                fontSize: 20,
                                                color: Colors.white.withOpacity(0.9),
                                                shadows: [
                                                  Shadow(
                                                    color: Colors.black.withOpacity(0.5),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 1),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      // Floating address badge for address mode
                      if (_currentMode == MapMode.addressSelection)
                        GetBuilder<AddressController>(
                          builder: (addressController) {
                            final addresses = _buildCombinedAddressList();
                            final savedAddress = AddressHelper.getAddressFromSharedPref();

                            // Auto-enable adding mode if no addresses exist
                            if (addresses.isEmpty && !_isAddingNewAddress) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) {
                                  setState(() {
                                    _isAddingNewAddress = true;
                                  });
                                }
                              });
                            }
                            return Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: SafeArea(
                                child: AddressFloatingBadge(
                                  key: ValueKey('address_floating_badge_${addresses.length}'),
                                  selectedAddress: savedAddress,
                                  addresses: addresses,
                                  onAddressChanged: (address) {
                                    if (address != null) {
                                      // Exit adding mode
                                      setState(() {
                                        _isAddingNewAddress = false;
                                      });

                                      // Smoothly fly to address location
                                      final lat = double.tryParse(address.latitude ?? '');
                                      final lng = double.tryParse(address.longitude ?? '');

                                      if (lat != null && lng != null) {
                                        if (Environment.useMapbox) {
                                          _mapboxKey.currentState?.animateCamera(
                                            LatLng(lat, lng),
                                            zoom: 15,
                                          );
                                        } else {
                                          _mapController?.animateCamera(
                                            CameraUpdate.newCameraPosition(
                                              CameraPosition(
                                                target: LatLng(lat, lng),
                                                zoom: 15,
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    } else {
                                      // Null means "Add New Address" card - enter adding mode
                                      setState(() {
                                        _isAddingNewAddress = true;
                                      });
                                    }
                                  },
                                  onAddressSelected: (address) async {
                                    // Save address to shared preferences
                                    AddressHelper.saveAddressInSharedPref(address);
                                    // Trigger rebuild to update UI
                                    setState(() {});
                                  },
                                  onAddNewAddress: () => _onPickAddressButtonPressed(locationController),
                                ),
                              ),
                            );
                          },
                        ),
                      // Location permissions not needed - map is for zone selection only
                    ],
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleEnableLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      showCustomSnackBar('you_have_to_allow'.tr);
    } else if (permission == LocationPermission.deniedForever) {
      Get.dialog(const PermissionDialog());
    } else {
      // Permission granted - hide overlay and get current location
      setState(() {
        _showLocationPermissionOverlay = false;
      });

      // Get current location and move map
      if (Environment.useMapbox) {
        // For Mapbox, we'll handle this differently since LocationController expects GoogleMapController
        // Just get the location and update camera via the Mapbox widget
        Get.find<LocationController>().getCurrentLocation(false, mapController: null);
      } else if (_mapController != null) {
        Get.find<LocationController>().getCurrentLocation(false, mapController: _mapController);
      }
    }
  }

  Future<void> _onPickAddressButtonPressed(LocationController locationController) async {
    if (locationController.pickPosition.latitude == 0 || locationController.pickAddress == null || locationController.pickAddress!.isEmpty) {
      showCustomSnackBar('pick_an_address'.tr);
      return;
    }

    // Get zone ID for the current position
    final zoneId = ZonePolygonHelper.getZoneIdForPoint(
      LatLng(locationController.pickPosition.latitude, locationController.pickPosition.longitude),
      locationController.zoneList,
    );

    if (zoneId == null) {
      showCustomSnackBar('please_select_a_location_inside_a_zone'.tr);
      return;
    }

    // Create address model
    final address = AddressModel(
      latitude: locationController.pickPosition.latitude.toString(),
      longitude: locationController.pickPosition.longitude.toString(),
      addressType: 'others',
      address: locationController.pickAddress,
      zoneId: zoneId,
    );

    // Check if user is logged in
    final authController = Get.find<AuthController>();
    final addressController = Get.find<AddressController>();

    if (!authController.isLoggedIn()) {
      // For guest users, save address locally
      await AddressHelper.saveAddressInSharedPref(address);

      // Also add to AddressController so GetBuilder widgets update
      addressController.addAddressLocally(address);

      // Clear the pick address (hides tooltip) and exit adding mode
      locationController.clearPickAddress();

      // Exit adding mode and update UI
      if (mounted) {
        setState(() {
          _isAddingNewAddress = false;
        });
      }

      // Animate camera to the new address
      final lat = double.tryParse(address.latitude ?? '');
      final lng = double.tryParse(address.longitude ?? '');
      if (lat != null && lng != null) {
        if (Environment.useMapbox) {
          _mapboxKey.currentState?.animateCamera(
            LatLng(lat, lng),
            zoom: 15,
          );
        } else {
          _mapController?.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(lat, lng),
                zoom: 15,
              ),
            ),
          );
        }
      }

      showCustomSnackBar('address_saved'.tr, isError: false);
      return;
    }

    // Save address to backend for logged-in users
    final response = await addressController.addAddress(address, false, zoneId);

    if (response.isSuccess) {
      // Refresh address list
      await addressController.getAddressList();

      // Save as current address
      final savedAddresses = addressController.addressList ?? [];
      if (savedAddresses.isNotEmpty) {
        // Find the newly added address (should be the one matching our coordinates)
        final newAddress = savedAddresses.firstWhereOrNull(
          (a) => a.latitude == address.latitude && a.longitude == address.longitude,
        ) ?? savedAddresses.last;

        await AddressHelper.saveAddressInSharedPref(newAddress);
      }

      // Clear the pick address (hides tooltip)
      locationController.clearPickAddress();

      // Exit adding mode and update UI
      if (mounted) {
        setState(() {
          _isAddingNewAddress = false;
        });
      }

      // Animate camera to the new address
      final lat = double.tryParse(address.latitude ?? '');
      final lng = double.tryParse(address.longitude ?? '');
      if (lat != null && lng != null) {
        if (Environment.useMapbox) {
          _mapboxKey.currentState?.animateCamera(
            LatLng(lat, lng),
            zoom: 15,
          );
        } else {
          _mapController?.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(lat, lng),
                zoom: 15,
              ),
            ),
          );
        }
      }

      showCustomSnackBar('address_added_successfully'.tr, isError: false);
    } else {
      showCustomSnackBar(response.message ?? 'failed_to_add_address'.tr);
    }
  }

  void _checkPermission(Function onTap) async {
    LocationPermission permission = await Geolocator.checkPermission();
    if(permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if(permission == LocationPermission.denied) {
      showCustomSnackBar('you_have_to_allow'.tr);
    }else if(permission == LocationPermission.deniedForever) {
      Get.dialog(const PermissionDialog());
    }else {
      onTap();
    }
  }

  void _showZoneSelectionActionSheet(BuildContext context) {
    LocationManagerSheet.show(context);
  }

  Set<Polygon> _zonePolygons(LocationController controller, BuildContext context, bool isAddingNewAddress) {
    if (!widget.showZonePolygons || controller.zoneList.isEmpty) {
      return <Polygon>{};
    }

    final theme = Theme.of(context);

    return ZonePolygonHelper.buildPolygons(
      zones: controller.zoneList,
      baseColor: theme.colorScheme.primary,
      strokeOpacity: 0.85,
      fillOpacity: 0.15,  // Slightly reduced for better balance with thinner strokes
      highlightedZoneId: _currentMode == MapMode.zoneSelection
          ? _selectedZoneId  // Highlight selected zone in zone mode
          : AddressHelper.getAddressFromSharedPref()?.zoneId,  // Always show user's saved zone in address mode
      useEnhancedStyle: true,
      onZoneTap: (zoneId) {
        if (_currentMode == MapMode.zoneSelection) {
          // In zone selection mode, select the zone
          final selectedZone = controller.zoneList.firstWhereOrNull(
            (zone) => zone.id == zoneId,
          );

          if (selectedZone != null) {
            // Stop the float animation when zone is selected
            _tapPromptBounceController.stop();
            setState(() {
              _selectedZoneId = zoneId;
              _selectedZoneName = selectedZone.displayName ?? selectedZone.name ?? 'Zone $zoneId';
              if (selectedZone.formattedCoordinates != null) {
                _selectedZoneCenter = _calculateZoneCenter(selectedZone.formattedCoordinates!);
              }
            });
          }
        }
        // Move to zone center
        _moveToZoneCenter(zoneId, controller.zoneList);
      },
    );
  }

  void _moveToZoneCenter(int zoneId, List<ZoneListModel> zones) {
    // Find the zone with this ID
    ZoneListModel? zone;
    for (var z in zones) {
      if (z.id == zoneId) {
        zone = z;
        break;
      }
    }

    if (zone != null && zone.formattedCoordinates != null && zone.formattedCoordinates!.isNotEmpty) {
      // Calculate the bounding box of the zone
      double minLat = double.infinity;
      double maxLat = double.negativeInfinity;
      double minLng = double.infinity;
      double maxLng = double.negativeInfinity;
      int count = 0;

      for (final coord in zone.formattedCoordinates!) {
        if (coord.lat != null && coord.lng != null) {
          minLat = min(minLat, coord.lat!);
          maxLat = max(maxLat, coord.lat!);
          minLng = min(minLng, coord.lng!);
          maxLng = max(maxLng, coord.lng!);
          count++;
        }
      }

      if (count > 0) {
        // Create bounds with padding
        final bounds = LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        );

        // Zoom to fit the zone bounds with padding
        if (Environment.useMapbox) {
          _mapboxKey.currentState?.animateToBounds(bounds, padding: 60);
        } else {
          _mapController?.animateCamera(
            CameraUpdate.newLatLngBounds(bounds, 60),
          );
        }

        // Update the current zone ID
        setState(() {
          _currentZoneId = zoneId;
        });
      }
    }
  }

  // Calculate the center point of a zone
  LatLng _calculateZoneCenter(List<FormattedCoordinates> coordinates) {
    if (coordinates.isEmpty) {
      return _initialPosition;
    }

    double sumLat = 0;
    double sumLng = 0;
    int count = 0;

    for (final coord in coordinates) {
      if (coord.lat != null && coord.lng != null) {
        sumLat += coord.lat!;
        sumLng += coord.lng!;
        count++;
      }
    }

    if (count > 0) {
      return LatLng(sumLat / count, sumLng / count);
    }

    return _initialPosition;
  }


  /// Build combined address list from controller and SharedPreferences
  /// Updates cache only when addresses actually change
  List<AddressModel> _buildCombinedAddressList() {
    final controllerAddresses = Get.find<AddressController>().addressList ?? [];
    final savedAddress = AddressHelper.getAddressFromSharedPref();

    List<AddressModel> newList = [...controllerAddresses];
    if (savedAddress != null && savedAddress.latitude != null) {
      final alreadyInList = controllerAddresses.any(
        (a) => a.id == savedAddress.id ||
               (a.latitude == savedAddress.latitude && a.longitude == savedAddress.longitude)
      );
      if (!alreadyInList) {
        newList.insert(0, savedAddress);
      }
    }

    // Only update cache if list actually changed
    if (_cachedCombinedAddressList.length != newList.length ||
        !_listsEqual(_cachedCombinedAddressList, newList)) {
      _cachedCombinedAddressList = newList;
    }

    return _cachedCombinedAddressList;
  }

  /// Check if two address lists are equal (by comparing IDs and coordinates)
  bool _listsEqual(List<AddressModel> list1, List<AddressModel> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].id != list2[i].id ||
          list1[i].latitude != list2[i].latitude ||
          list1[i].longitude != list2[i].longitude) {
        return false;
      }
    }
    return true;
  }

  String _getAddressWithoutCountry(String address) {
    if (address.isEmpty) return '';
    final addressParts = address.split(',');
    return addressParts.length > 1
        ? addressParts.sublist(0, addressParts.length - 1).join(',').trim()
        : address;
  }

  /// Get display text combining zone name and address (e.g., "Shefa-Amr - 123 Main St")
  String _getDisplayAddress(String address) {
    return _getAddressWithoutCountry(address);
  }

  /// Build markers for saved addresses in Address mode
  Set<Marker> _buildSavedAddressMarkers(LocationController locationController) {
    final addresses = _buildCombinedAddressList();
    final markers = <Marker>{};

    for (final address in addresses) {
      if (address.latitude != null && address.longitude != null) {
        final lat = double.tryParse(address.latitude!);
        final lng = double.tryParse(address.longitude!);

        if (lat != null && lng != null) {
          markers.add(
            Marker(
              markerId: MarkerId('address_${address.id ?? address.latitude}'),
              position: LatLng(lat, lng),
              infoWindow: InfoWindow(
                title: address.addressType?.tr ?? 'address'.tr,
                snippet: address.address,
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueAzure,
              ),
            ),
          );
        }
      }
    }

    return markers;
  }

  /// Build badge showing user's current saved zone or empty state
  Widget _buildCurrentZoneBadge(BuildContext context, LocationController locationController) {
    // Get user's saved zone from SharedPreferences
    final savedAddress = AddressHelper.getAddressFromSharedPref();
    final savedZoneId = savedAddress?.zoneId;

    // Find zone name from zone list
    String? savedZoneName;
    if (savedZoneId != null && savedZoneId != 0) {
      final savedZone = locationController.zoneList.firstWhereOrNull(
        (zone) => zone.id == savedZoneId,
      );
      savedZoneName = savedZone?.displayName ?? savedZone?.name;
    }

    // If user has a saved zone, show it
    if (savedZoneName != null && savedZoneName.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeSmall,
          vertical: Dimensions.paddingSizeExtraSmall,
        ),
        decoration: BoxDecoration(
          color: Colors.grey[800]!.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_city_rounded,
              size: 12,
              color: Colors.white.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 4),
            Text(
              'your_zone'.tr,
              style: robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeExtraSmall,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(width: 3),
            Text(
              savedZoneName,
              style: robotoMedium.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    // Empty state - no zone saved
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeSmall,
        vertical: Dimensions.paddingSizeExtraSmall,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[800]!.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 12,
            color: Colors.amber[400],
          ),
          const SizedBox(width: 4),
          Text(
            'no_zone_selected'.tr,
            style: robotoMedium.copyWith(
              fontSize: Dimensions.fontSizeExtraSmall,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  void _onZoneSelected(LocationController locationController) {
    if (_selectedZoneId != null) {
      final selectedZone = locationController.zoneList
          ?.firstWhereOrNull((zone) => zone.id == _selectedZoneId);
      if (selectedZone != null) {
        // Priority 1: Use callback if provided (home screen flow)
        if (widget.onZoneSelected != null) {
          widget.onZoneSelected!(selectedZone);
          return;
        }

        // Priority 2: Onboarding flow - save zone and navigate to dashboard
        if (widget.fromSplash || widget.route == 'splash') {
          _handleOnboardingZoneSelection(selectedZone, locationController);
          return;
        }

        // Default: return result via navigation
        Get.back(result: selectedZone);
      }
    }
  }

  /// Handle zone selection during onboarding - save zone and navigate to home
  Future<void> _handleOnboardingZoneSelection(
    ZoneListModel zone,
    LocationController locationController,
  ) async {
    // Show loading
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      // Save zone as address
      await locationController.saveZoneAsAddress(zone, refreshData: false);

      // Close loading dialog
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      // Navigate to home
      Get.offAllNamed(RouteHelper.getInitialRoute());
    } catch (e) {
      // Close loading dialog
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      showCustomSnackBar('failed_to_save_zone'.tr);
    }
  }

  Widget _buildAddressBadge(String address) {
    // Remove country from address (last part after final comma)
    final addressParts = address.split(',');
    final addressWithoutCountry = addressParts.length > 1
        ? addressParts.sublist(0, addressParts.length - 1).join(',').trim()
        : address;

    return Container(
      constraints: const BoxConstraints(
        maxWidth: 320,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeDefault,
        vertical: Dimensions.paddingSizeSmall,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.location_on,
            size: 18,
            color: Colors.white,
          ),
          const SizedBox(width: Dimensions.paddingSizeExtraSmall),
          Flexible(
            child: Text(
              addressWithoutCountry,
              style: robotoMedium.copyWith(
                fontSize: Dimensions.fontSizeDefault,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

}
