import 'package:godelivery_user/common/widgets/custom_snackbar_widget.dart';
import 'package:godelivery_user/features/splash/controllers/splash_controller.dart';
import 'package:godelivery_user/features/address/domain/models/address_model.dart';
import 'package:godelivery_user/features/location/controllers/location_controller.dart';
import 'package:godelivery_user/features/location/domain/models/zone_list_model.dart';
import 'package:godelivery_user/features/location/widgets/location_search_dialog.dart';
import 'package:godelivery_user/features/location/widgets/permission_dialog.dart';
import 'package:godelivery_user/features/location/widgets/zone_list_widget.dart';
import 'package:godelivery_user/features/splash/controllers/theme_controller.dart';
import 'package:godelivery_user/helper/responsive_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/images.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:godelivery_user/common/widgets/custom_button_widget.dart';
import 'package:godelivery_user/common/widgets/web_menu_bar.dart';
import 'package:flutter/material.dart';
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
  const PickMapScreen({
    super.key, required this.fromSignUp, required this.fromAddAddress, required this.canRoute,
    required this.route, this.googleMapController, required this.fromSplash,
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
    Get.find<LocationController>().getZoneList();

    if(widget.fromAddAddress) {
      Get.find<LocationController>().setPickData();
    }
    _initialPosition = LatLng(
      double.parse(Get.find<SplashController>().configModel!.defaultLocation!.lat ?? '37.7749'),
      double.parse(Get.find<SplashController>().configModel!.defaultLocation!.lng ?? '-122.4194'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ResponsiveHelper.isDesktop(context) ? const WebMenuBar() : null,
      body: SafeArea(child: Center(child: SizedBox(
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

            Center(child: !locationController.loading ? Image.asset(Images.pickMarker, height: 50, width: 50)
                : const CircularProgressIndicator()),

            Positioned(
              top: Dimensions.paddingSizeLarge, left: Dimensions.paddingSizeSmall, right: Dimensions.paddingSizeSmall,
              child: Row(
                children: [
                  Expanded(
                    child: LocationSearchDialog(mapController: _mapController, pickedLocation: locationController.pickAddress!),
                  ),
                  const SizedBox(width: Dimensions.paddingSizeSmall),
                  Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                        onTap: () => _showZoneSelectionActionSheet(context),
                        child: const Icon(
                          Icons.list_alt,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Positioned(
              bottom: 80, right: Dimensions.paddingSizeSmall,
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

            Positioned(
              bottom: Dimensions.paddingSizeLarge, left: Dimensions.paddingSizeSmall, right: Dimensions.paddingSizeSmall,
              child: CustomButtonWidget(
                buttonText: locationController.inZone ? widget.fromAddAddress ? 'pick_address'.tr : 'pick_location'.tr
                    : 'service_not_available_in_this_area'.tr,
                isLoading: locationController.isLoading,
                onPressed: (locationController.buttonDisabled || locationController.loading) ? null
                    : () => _onPickAddressButtonPressed(locationController),
              ),
            ),

          ]);
        }),
      ))),
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
    ZoneListModel? selectedZone;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(Dimensions.radiusExtraLarge),
              topRight: Radius.circular(Dimensions.radiusExtraLarge),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
                decoration: BoxDecoration(
                  color: Theme.of(context).disabledColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'select_zone'.tr,
                      style: robotoBold.copyWith(
                        fontSize: Dimensions.fontSizeLarge,
                        color: Theme.of(context).textTheme.bodyLarge!.color,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: Icon(Icons.close, color: Theme.of(context).disabledColor),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Zone list
              Expanded(
                child: GetBuilder<LocationController>(builder: (locationController) {
                  if (locationController.loadingZoneList) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (locationController.zoneList.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.location_off, size: 50, color: Theme.of(context).disabledColor),
                          const SizedBox(height: Dimensions.paddingSizeSmall),
                          Text(
                            'no_zones_available'.tr,
                            style: robotoMedium.copyWith(color: Theme.of(context).disabledColor),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                    itemCount: locationController.zoneList.length,
                    itemBuilder: (context, index) {
                      ZoneListModel zone = locationController.zoneList[index];
                      bool isSelected = selectedZone?.id == zone.id;
                      bool isActive = zone.status == 1;

                      return Container(
                        margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).primaryColor.withOpacity(0.1)
                              : Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : isActive
                                    ? Theme.of(context).primaryColor.withOpacity(0.3)
                                    : Theme.of(context).disabledColor.withOpacity(0.3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                            onTap: isActive ? () {
                              setState(() {
                                selectedZone = zone;
                              });
                            } : null,
                            child: Padding(
                              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? Theme.of(context).primaryColor.withOpacity(0.1)
                                          : Theme.of(context).disabledColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.location_on,
                                      color: isActive
                                          ? Theme.of(context).primaryColor
                                          : Theme.of(context).disabledColor,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: Dimensions.paddingSizeSmall),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          zone.displayName ?? zone.name ?? 'Unknown Zone',
                                          style: robotoBold.copyWith(
                                            fontSize: Dimensions.fontSizeDefault,
                                            color: isActive
                                                ? Theme.of(context).textTheme.bodyLarge!.color
                                                : Theme.of(context).disabledColor,
                                          ),
                                        ),
                                        if (isActive) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            zone.shippingInfo,
                                            style: robotoRegular.copyWith(
                                              fontSize: Dimensions.fontSizeSmall,
                                              color: Theme.of(context).textTheme.bodyMedium!.color,
                                            ),
                                          ),
                                        ] else ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            'service_unavailable'.tr,
                                            style: robotoRegular.copyWith(
                                              fontSize: Dimensions.fontSizeSmall,
                                              color: Theme.of(context).colorScheme.error,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(
                                      Icons.check_circle,
                                      color: Theme.of(context).primaryColor,
                                      size: 24,
                                    )
                                  else if (isActive)
                                    Icon(
                                      Icons.radio_button_unchecked,
                                      color: Theme.of(context).primaryColor.withOpacity(0.5),
                                      size: 24,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),

              // Fixed confirm button at bottom
              Container(
                padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).dividerColor,
                      width: 1,
                    ),
                  ),
                ),
                child: SafeArea(
                  child: CustomButtonWidget(
                    buttonText: 'confirm'.tr,
                    isLoading: false,
                    onPressed: selectedZone != null ? () {
                      Get.find<LocationController>().selectZone(selectedZone!);
                      Get.back();
                      // Auto-trigger the location confirmation after a brief delay
                      Future.delayed(const Duration(milliseconds: 300), () {
                        _onPickAddressButtonPressed(Get.find<LocationController>());
                      });
                    } : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
