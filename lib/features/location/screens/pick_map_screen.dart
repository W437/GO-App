import 'package:godelivery_user/common/widgets/shared/buttons/circular_back_button_widget.dart';
import 'package:godelivery_user/common/widgets/shared/feedback/custom_snackbar_widget.dart';
import 'package:godelivery_user/common/widgets/mobile/draggable_bottom_sheet_widget.dart';
import 'package:godelivery_user/features/splash/controllers/splash_controller.dart';
import 'package:godelivery_user/features/address/domain/models/address_model.dart';
import 'package:godelivery_user/features/location/controllers/location_controller.dart';
import 'package:godelivery_user/features/location/helper/zone_polygon_helper.dart';
import 'package:godelivery_user/features/location/widgets/location_search_dialog.dart';
import 'package:godelivery_user/features/location/widgets/permission_dialog.dart';
import 'package:godelivery_user/features/location/widgets/zone_list_widget.dart';
import 'package:godelivery_user/features/splash/controllers/theme_controller.dart';
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

  @override
  void initState() {
    super.initState();

    Get.find<LocationController>().makeLoadingOff();

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
        body: SafeArea(
          top: false,
          bottom: false,
          child: Center(
            child: SizedBox(
              width: Dimensions.webMaxWidth,
              child: GetBuilder<LocationController>(builder: (locationController) {
                return Stack(children: [

            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: widget.fromAddAddress ? LatLng(locationController.position.latitude, locationController.position.longitude)
                    : _initialPosition,
                zoom: 16,
              ),
              minMaxZoomPreference: const MinMaxZoomPreference(0, 16),
              polygons: _zonePolygons(locationController, context),
              onMapCreated: (GoogleMapController mapController) {
                _mapController = mapController;
                if(!widget.fromAddAddress && widget.route != 'splash') {
                  Get.find<LocationController>().getCurrentLocation(false, mapController: mapController).then((value) {
                    if(widget.fromSplash) {
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
              },
              style: Get.isDarkMode ? Get.find<ThemeController>().darkMap : Get.find<ThemeController>().lightMap,
            ),

            // Top gradient overlay to soften the transition to the sheet controls
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
                        Colors.black.withOpacity(0.35),
                        Colors.black.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            Center(child: !locationController.loading ? Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Image.asset(
                Images.pickLocationMapPin,
                height: 72,
                width: 72,
                fit: BoxFit.contain,
              ),
            ) : const CircularProgressIndicator()),

            // Back button
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
                  child: Icon(Icons.my_location, color: Theme.of(context).primaryColor),
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
            ]);
          }),
        ),
      ),
    ),
  ),
);
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
    final double bottomInset = MediaQuery.of(context).viewPadding.bottom;
    showDraggableBottomSheet(
      context: context,
      wrapContent: true,
      maxChildSize: 0.7,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            Dimensions.paddingSizeDefault,
            Dimensions.paddingSizeSmall,
            Dimensions.paddingSizeDefault,
            Dimensions.paddingSizeLarge + bottomInset,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'select_delivery_zone'.tr,
                style: robotoBold.copyWith(
                  fontSize: Dimensions.fontSizeLarge,
                  color: Theme.of(context).textTheme.bodyLarge!.color,
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeDefault),
              const Flexible(
                child: ZoneListWidget(isBottomSheet: false),
              ),
              const SizedBox(height: Dimensions.paddingSizeLarge),
            ],
          ),
        ),
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
      strokeOpacity: 0.7,
      fillOpacity: 0.1,
    );
  }
}
