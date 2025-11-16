import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:godelivery_user/features/location/controllers/location_controller.dart';
import 'package:godelivery_user/features/location/widgets/location_selection_sheet.dart';
import 'package:godelivery_user/features/location/widgets/permission_dialog.dart';
import 'package:godelivery_user/helper/business_logic/address_helper.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';

/// Helper to open the location selection bottom sheet anywhere in the app.
class LocationSheetHelper {
  static void showSelectionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LocationSelectionSheet(
        onUseCurrentLocation: () {
          _checkPermission(context, () {
            Get.back();
            Get.find<LocationController>().getCurrentLocation(true);
          });
        },
        onLocationSelected: (address) {
          Get.back();
          AddressHelper.saveAddressInSharedPref(address);
          Get.find<LocationController>().updatePosition(
            CameraPosition(
              target: LatLng(
                double.parse(address.latitude ?? '0'),
                double.parse(address.longitude ?? '0'),
              ),
              zoom: 16,
            ),
            true,
          );
        },
        onAddNewLocation: () {
          Get.back();
          Get.toNamed(RouteHelper.getPickMapRoute('home', false));
        },
      ),
    );
  }

  static Future<void> _checkPermission(BuildContext context, Function onTap) async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      Get.snackbar('Permission Required', 'Location permission is required to use this feature');
    } else if (permission == LocationPermission.deniedForever) {
      Get.dialog(const PermissionDialog());
    } else {
      onTap();
    }
  }
}
