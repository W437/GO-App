import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:godelivery_user/common/widgets/shared/buttons/circular_back_button_widget.dart';
import 'package:godelivery_user/common/widgets/shared/feedback/custom_snackbar_widget.dart';
import 'package:godelivery_user/common/widgets/mobile/draggable_bottom_sheet_widget.dart';
import 'package:godelivery_user/common/widgets/shared/sheets/custom_sheet.dart';
import 'package:godelivery_user/features/splash/controllers/splash_controller.dart';
import 'package:godelivery_user/features/address/domain/models/address_model.dart';
import 'package:godelivery_user/features/location/controllers/location_controller.dart';
import 'package:godelivery_user/features/location/domain/models/zone_list_model.dart';
import 'package:godelivery_user/features/location/helper/zone_polygon_helper.dart';
import 'package:godelivery_user/features/location/widgets/permission_dialog.dart';
import 'package:godelivery_user/features/location/widgets/zone_list_widget.dart';
import 'package:godelivery_user/features/location/widgets/location_selection_sheet.dart';
import 'package:godelivery_user/features/location/widgets/location_permission_overlay.dart';
import 'package:godelivery_user/features/location/widgets/zone_floating_badge.dart';
import 'package:godelivery_user/features/splash/controllers/theme_controller.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:godelivery_user/helper/ui/responsive_helper.dart';
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
  const PickMapScreen({
    super.key, required this.fromSignUp, required this.fromAddAddress, required this.canRoute,
    required this.route, this.googleMapController, required this.fromSplash,
    this.showZonePolygons = true,
  });

  @override
  State<PickMapScreen> createState() => _PickMapScreenState();
}

class _PickMapScreenState extends State<PickMapScreen> with TickerProviderStateMixin {
  GoogleMapController? _mapController;
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
  MapMode _currentMode = MapMode.zoneSelection;  // Default to zone selection
  int? _selectedZoneId;  // For zone selection mode
  LatLng? _selectedZoneCenter;  // Center position of selected zone
  String? _selectedZoneName;  // Name of selected zone

  @override
  void initState() {
    super.initState();

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

    // Swift bouncy wiggle rotation - uses sin() for natural oscillation
    _tapPromptBounceController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    Get.find<LocationController>().makeLoadingOff();

    // Start animations after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Trigger first animation immediately
      if (_currentMode == MapMode.zoneSelection && _selectedZoneId == null) {
        _triggerTapPromptAnimation();
      }

      // Start the repeating timer every 3 seconds
      _tapPromptTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        if (_currentMode == MapMode.zoneSelection && _selectedZoneId == null) {
          _triggerTapPromptAnimation();
        }
      });
    });

    // No location permissions needed - map is for zone selection only
    _showLocationPermissionOverlay = false;

    // Call after build to avoid setState during build error
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<LocationController>().getZoneList();
    });

    if(widget.fromAddAddress) {
      Get.find<LocationController>().setPickData();
    }
    // Center around Shefa-Amr (Northern Israel service area)
    _initialPosition = const LatLng(32.82461934938776, 35.14441039413214);
  }

  @override
  void dispose() {
    _pinBounceController.dispose();
    _badgeBounceController.dispose();
    _tapPromptWiggleController.dispose();
    _tapPromptBounceController.dispose();
    _tapPromptTimer?.cancel();
    super.dispose();
  }

  /// Check if it's nighttime (6 PM to 6 AM)
  bool _isNightTime() {
    final hour = DateTime.now().hour;
    return hour >= 18 || hour < 6;
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
                      GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _initialPosition,
                          zoom: 10.43,  // Zoom level to show Northern Israel service area
                        ),
                        minMaxZoomPreference: const MinMaxZoomPreference(6.5, 14),  // Limited zoom for zone selection
                        polygons: _zonePolygons(locationController, context),
                        markers: <Marker>{},  // No markers - using overlay instead
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
                          // Defer state updates to avoid layout assertion errors
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            Get.find<LocationController>().updatePosition(_cameraPosition, false);
                          });
                          // Update the current zone when camera stops moving
                          if (_cameraPosition != null) {
                            // LOG MAP POSITION FOR REFINEMENT (commented out for production)
                            // print('════════════════════════════════════════════');
                            // print('📍 MAP POSITION & ZOOM LEVEL');
                            // print('────────────────────────────────────────────');
                            // print('Latitude:  ${_cameraPosition!.target.latitude}');
                            // print('Longitude: ${_cameraPosition!.target.longitude}');
                            // print('Zoom:      ${_cameraPosition!.zoom}');
                            // print('────────────────────────────────────────────');
                            // print('Copy this for _initialPosition:');
                            // print('const LatLng(${_cameraPosition!.target.latitude}, ${_cameraPosition!.target.longitude})');
                            // print('');
                            // print('Copy this for zoom:');
                            // print('zoom: ${_cameraPosition!.zoom},');
                            // print('════════════════════════════════════════════');

                            // Only update current zone in address mode
                            if (_currentMode == MapMode.addressSelection) {
                              final newZoneId = ZonePolygonHelper.getZoneIdForPoint(
                                _cameraPosition!.target,
                                locationController.zoneList,
                              );
                              if (newZoneId != _currentZoneId) {
                                setState(() {
                                  _currentZoneId = newZoneId;
                                });
                                // Animate pin and badge when entering a valid zone
                                if (newZoneId != null) {
                                  _pinBounceController.forward(from: 0.0);
                                  _badgeBounceController.forward(from: 0.0);
                                }
                              }
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
                      if (_currentMode == MapMode.addressSelection)
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

                      // Address Badge for address mode only (floating above pin)
                      if (_currentMode == MapMode.addressSelection &&
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
                                          Text(
                                            _getAddressWithoutCountry(locationController.pickAddress ?? ''),
                                            style: robotoBold.copyWith(
                                              fontSize: Dimensions.fontSizeDefault,
                                              color: Colors.black,
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
                          top: MediaQuery.of(context).viewPadding.top + Dimensions.paddingSizeSmall,
                          left: Dimensions.paddingSizeSmall,
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
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.9),
                              ),
                              children: [
                                TextSpan(
                                  text: '${locationController.zoneList?.length ?? 0}',
                                  style: robotoBold.copyWith(
                                    fontSize: 14,
                                    color: Theme.of(context).primaryColor,
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
                      // Mode selector label
                      Positioned(
                        top: MediaQuery.of(context).viewPadding.top + Dimensions.paddingSizeSmall + 68, // Above mode selector
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Text(
                            'select_map_mode'.tr,
                            style: robotoRegular.copyWith(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.5),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      // Mode toggle selector - positioned under label
                      Positioned(
                        top: MediaQuery.of(context).viewPadding.top + Dimensions.paddingSizeSmall + 84, // Below label
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            height: 35,
                            width: 160,
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.grey[800]!.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(100),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                // Sliding indicator
                                AnimatedAlign(
                                  alignment: _currentMode == MapMode.zoneSelection
                                      ? Alignment.centerLeft
                                      : Alignment.centerRight,
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOutCubic,
                                  child: Container(
                                    width: 77,
                                    height: 29,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00BCD4),
                                      borderRadius: BorderRadius.circular(100),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF00BCD4).withOpacity(0.3),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Tab Labels
                                Row(
                                  children: [
                                    _buildModeButton(
                                      mode: MapMode.zoneSelection,
                                      icon: Icons.map,
                                      label: 'Zone',
                                    ),
                                    _buildModeButton(
                                      mode: MapMode.addressSelection,
                                      icon: Icons.location_on,
                                      label: 'Address',
                                    ),
                                  ],
                                ),
                              ],
                            ),
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
                                : AnimatedBuilder(
                                    animation: Listenable.merge([
                                      _tapPromptWiggleAnimation,
                                      _tapPromptBounceController,
                                    ]),
                                    builder: (context, child) {
                                      // Swift bouncy wiggle: 1.5 oscillations with decay
                                      final t = _tapPromptBounceController.value;
                                      final decay = 1.0 - t; // Stronger at start, fades out
                                      final wiggleAngle = sin(t * 3 * pi) * 0.12 * decay;
                                      return Transform.scale(
                                        scale: _tapPromptWiggleAnimation.value,
                                        child: Transform.rotate(
                                          angle: wiggleAngle,
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
                                              fontSize: Dimensions.fontSizeExtraLarge,
                                              color: Colors.white.withOpacity(0.9),
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                          Icon(
                                            Icons.location_on,
                                            size: 28,
                                            color: Theme.of(context).primaryColor,
                                          ),
                                          Text(
                                            ' zone!',
                                            style: robotoMedium.copyWith(
                                              fontSize: Dimensions.fontSizeExtraLarge,
                                              color: Colors.white.withOpacity(0.9),
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      // Address confirmation button for address mode
                      if (_currentMode == MapMode.addressSelection)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                Dimensions.paddingSizeExtraLarge,
                                0,
                                Dimensions.paddingSizeExtraLarge,
                                Dimensions.paddingSizeDefault,
                              ),
                              child: CustomButtonWidget(
                                buttonText: 'confirm_delivery_address'.tr,
                                isLoading: locationController.isLoading,
                                onPressed: (locationController.buttonDisabled || locationController.loading || !locationController.inZone)
                                    ? null
                                    : () => _onPickAddressButtonPressed(locationController),
                              ),
                            ),
                          ),
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
      if (_mapController != null) {
        Get.find<LocationController>().getCurrentLocation(false, mapController: _mapController);
      }
    }
  }

  void _onPickAddressButtonPressed(LocationController locationController) {
    if(locationController.pickPosition.latitude != 0 && locationController.pickAddress!.isNotEmpty) {
      if(widget.fromAddAddress) {
        if(widget.googleMapController != null) {
          widget.googleMapController!.moveCamera(CameraUpdate.newCameraPosition(CameraPosition(target: LatLng(
            locationController.pickPosition.latitude, locationController.pickPosition.longitude,
          ), zoom: 17)));
          locationController.addAddressData();
        }
        Get.back();
      }else {
        AddressModel address = AddressModel(
          latitude: locationController.pickPosition.latitude.toString(),
          longitude: locationController.pickPosition.longitude.toString(),
          addressType: 'others', address: locationController.pickAddress,
        );
        locationController.saveAddressAndNavigate(address, widget.fromSignUp, widget.route, widget.canRoute, ResponsiveHelper.isDesktop(Get.context));
      }
    }else {
      showCustomSnackBar('pick_an_address'.tr);
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
    CustomSheet.show(
      context: context,
      child: LocationSelectionSheet(
        onUseCurrentLocation: null,  // Disabled - map is for zone selection only
        onLocationSelected: (address) {
          Get.back();
          if (_mapController != null) {
            _mapController!.moveCamera(CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(
                  double.parse(address.latitude ?? '0'),
                  double.parse(address.longitude ?? '0'),
                ),
                zoom: 12,  // Zoom in closer when selecting a specific location
              ),
            ));
          }
        },
        onAddNewLocation: () {
          Get.back();
          // Keep the current map screen - user can pick location on map
        },
      ),
      showHandle: true,
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeExtraLarge,
        vertical: Dimensions.paddingSizeDefault,
      ),
    );
  }

  Set<Polygon> _zonePolygons(LocationController controller, BuildContext context) {
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
          : _currentZoneId,  // Highlight current zone in address mode
      useEnhancedStyle: true,
      onZoneTap: (zoneId) {
        if (_currentMode == MapMode.zoneSelection) {
          // In zone selection mode, select the zone
          final selectedZone = controller.zoneList.firstWhereOrNull(
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
      // Calculate the center of the zone
      double sumLat = 0;
      double sumLng = 0;
      int count = 0;

      for (final coord in zone.formattedCoordinates!) {
        if (coord.lat != null && coord.lng != null) {
          sumLat += coord.lat!;
          sumLng += coord.lng!;
          count++;
        }
      }

      if (count > 0) {
        final centerLat = sumLat / count;
        final centerLng = sumLng / count;

        // Move the camera to the zone center without changing zoom
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(centerLat, centerLng),
          ),
        );

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


  String _getAddressWithoutCountry(String address) {
    if (address.isEmpty) return '';
    final addressParts = address.split(',');
    return addressParts.length > 1
        ? addressParts.sublist(0, addressParts.length - 1).join(',').trim()
        : address;
  }

  void _onZoneSelected(LocationController locationController) {
    if (_selectedZoneId != null) {
      final selectedZone = locationController.zoneList
          ?.firstWhereOrNull((zone) => zone.id == _selectedZoneId);
      if (selectedZone != null) {
        Get.back(result: selectedZone);
      }
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

  Widget _buildModeButton({
    required MapMode mode,
    required IconData icon,
    required String label,
  }) {
    final bool isSelected = _currentMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentMode = mode;
            if (mode == MapMode.zoneSelection) {
              // Reset zone selection
              _currentZoneId = null;
              _selectedZoneId = null;
              _selectedZoneName = null;
              _selectedZoneCenter = null;
            }
          });
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : Colors.white60,
              ),
              const SizedBox(width: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                style: robotoMedium.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: isSelected ? Colors.white : Colors.white60,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
