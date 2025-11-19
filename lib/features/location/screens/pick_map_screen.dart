import 'package:godelivery_user/common/widgets/shared/buttons/circular_back_button_widget.dart';
import 'package:godelivery_user/common/widgets/shared/feedback/custom_snackbar_widget.dart';
import 'package:godelivery_user/common/widgets/mobile/draggable_bottom_sheet_widget.dart';
import 'package:godelivery_user/features/splash/controllers/splash_controller.dart';
import 'package:godelivery_user/features/address/domain/models/address_model.dart';
import 'package:godelivery_user/features/location/controllers/location_controller.dart';
import 'package:godelivery_user/features/location/domain/models/zone_list_model.dart';
import 'package:godelivery_user/features/location/helper/zone_polygon_helper.dart';
import 'package:godelivery_user/features/location/widgets/permission_dialog.dart';
import 'package:godelivery_user/features/location/widgets/zone_list_widget.dart';
import 'package:godelivery_user/features/location/widgets/location_selection_sheet.dart';
import 'package:godelivery_user/features/location/widgets/location_permission_overlay.dart';
import 'package:godelivery_user/features/splash/controllers/theme_controller.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:godelivery_user/helper/ui/responsive_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/images.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:godelivery_user/common/widgets/shared/buttons/custom_button_widget.dart';
import 'package:godelivery_user/common/widgets/web/web_menu_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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

class _PickMapScreenState extends State<PickMapScreen> {
  GoogleMapController? _mapController;
  CameraPosition? _cameraPosition;
  late LatLng _initialPosition;
  bool _showLocationPermissionOverlay = false;
  int? _currentZoneId;

  @override
  void initState() {
    super.initState();

    Get.find<LocationController>().makeLoadingOff();

    // Show location permission overlay if coming from onboarding
    if (widget.route == RouteHelper.onBoarding) {
      _showLocationPermissionOverlay = true;
    }

    // Call after build to avoid setState during build error
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<LocationController>().getZoneList();
    });

    if(widget.fromAddAddress) {
      Get.find<LocationController>().setPickData();
    }
    _initialPosition = LatLng(
      double.parse(Get.find<SplashController>().configModel!.defaultLocation!.lat ?? '32.997473'),
      double.parse(Get.find<SplashController>().configModel!.defaultLocation!.lng ?? '35.144028'),
    );
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
                          target: widget.fromAddAddress
                              ? LatLng(locationController.position.latitude, locationController.position.longitude)
                              : _initialPosition,
                          zoom: 16,
                        ),
                        minMaxZoomPreference: const MinMaxZoomPreference(0, 16),
                        polygons: _zonePolygons(locationController, context),
                        // markers: _zoneMarkers(locationController),  // Removed zone name markers
                        onMapCreated: (GoogleMapController mapController) {
                          _mapController = mapController;

                          // Initialize current zone based on initial position
                          if (widget.fromAddAddress) {
                            _currentZoneId = ZonePolygonHelper.getZoneIdForPoint(
                              LatLng(locationController.position.latitude, locationController.position.longitude),
                              locationController.zoneList,
                            );
                          } else {
                            _currentZoneId = ZonePolygonHelper.getZoneIdForPoint(
                              _initialPosition,
                              locationController.zoneList,
                            );
                          }

                          // Don't auto-request location if showing permission overlay
                          if (!widget.fromAddAddress && widget.route != 'splash' && !_showLocationPermissionOverlay) {
                            Get.find<LocationController>()
                                .getCurrentLocation(false, mapController: mapController)
                                .then((value) {
                              if (widget.fromSplash) {
                                _onPickAddressButtonPressed(locationController);
                              }
                            });
                          }
                        },
                        zoomControlsEnabled: false,
                        onCameraMove: (CameraPosition cameraPosition) {
                          _cameraPosition = cameraPosition;
                        },
                        onCameraMoveStarted: () {
                          locationController.disableButton();
                        },
                        onCameraIdle: () {
                          Get.find<LocationController>().updatePosition(_cameraPosition, false);
                          // Update the current zone when camera stops moving
                          if (_cameraPosition != null) {
                            final newZoneId = ZonePolygonHelper.getZoneIdForPoint(
                              _cameraPosition!.target,
                              locationController.zoneList,
                            );
                            if (newZoneId != _currentZoneId) {
                              setState(() {
                                _currentZoneId = newZoneId;
                              });
                            }
                          }
                        },
                        style: Get.isDarkMode
                            ? Get.find<ThemeController>().darkMap
                            : Get.find<ThemeController>().lightMap,
                      ),
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 140,
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.95),
                                  Colors.black.withOpacity(0.4),
                                  Colors.black.withOpacity(0.0),
                                ],
                                stops: const [0.0, 0.6, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: locationController.loading
                            ? const CircularProgressIndicator()
                            : Padding(
                                padding: const EdgeInsets.only(bottom: 20.0),
                                child: Image.asset(
                                  Images.pickLocationMapPin,
                                  height: 72,
                                  width: 72,
                                  fit: BoxFit.contain,
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
                      Positioned(
                        right: Dimensions.paddingSizeSmall,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: FloatingActionButton(
                            heroTag: 'pick_map_screen_my_location',
                            mini: true,
                            backgroundColor: Theme.of(context).cardColor,
                            onPressed: () => _checkPermission(() {
                              Get.find<LocationController>().getCurrentLocation(false, mapController: _mapController);
                            }),
                            child: Icon(
                              Icons.my_location,
                              color: Theme.of(context).textTheme.bodyLarge!.color,
                            ),
                          ),
                        ),
                      ),
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
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CustomButtonWidget(
                                  buttonText: 'select_zone'.tr,
                                  icon: Icons.list_alt,
                                  color: Theme.of(context).cardColor,
                                  textColor: Theme.of(context).textTheme.bodyLarge!.color,
                                  iconColor: Colors.black,
                                  onPressed: () => _showZoneSelectionActionSheet(context),
                                ),
                                const SizedBox(height: Dimensions.paddingSizeSmall),
                                CustomButtonWidget(
                                  buttonText: locationController.inZone
                                      ? (widget.fromAddAddress ? 'pick_address'.tr : 'pick_location'.tr)
                                      : 'service_not_available_in_this_area'.tr,
                                  isLoading: locationController.isLoading,
                                  onPressed: (locationController.buttonDisabled || locationController.loading)
                                      ? null
                                      : () => _onPickAddressButtonPressed(locationController),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Location permission overlay
                      if (_showLocationPermissionOverlay)
                        Positioned.fill(
                          child: LocationPermissionOverlay(
                            onEnableLocation: _handleEnableLocation,
                            showSkip: false,
                          ),
                        ),
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
    final controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: Navigator.of(context),
    );

    final curvedAnimation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutBack,
    );

    controller.forward();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      transitionAnimationController: controller,
      builder: (context) => LocationSelectionSheet(
        onUseCurrentLocation: () {
          _checkPermission(() {
            Get.back();
            Get.find<LocationController>().getCurrentLocation(false, mapController: _mapController);
          });
        },
        onLocationSelected: (address) {
          Get.back();
          if (_mapController != null) {
            _mapController!.moveCamera(CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(
                  double.parse(address.latitude ?? '0'),
                  double.parse(address.longitude ?? '0'),
                ),
                zoom: 16,
              ),
            ));
          }
        },
        onAddNewLocation: () {
          Get.back();
          // Keep the current map screen - user can pick location on map
        },
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
      highlightedZoneId: _currentZoneId,  // Use the tracked current zone ID
      useEnhancedStyle: true,
      onZoneTap: (zoneId) {
        // When a zone is clicked, move the camera to its center
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

  // Removed zone marker methods as we're not showing zone name badges anymore
  // Set<Marker> _zoneMarkers(LocationController controller) {
  //   return <Marker>{};
  // }
}
