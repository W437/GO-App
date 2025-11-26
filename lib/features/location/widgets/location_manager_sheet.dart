import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:godelivery_user/common/widgets/shared/buttons/rounded_icon_button_widget.dart';
import 'package:godelivery_user/common/widgets/shared/sheets/custom_sheet.dart';
import 'package:godelivery_user/features/address/domain/models/address_model.dart';
import 'package:godelivery_user/features/address/controllers/address_controller.dart';
import 'package:godelivery_user/features/location/controllers/location_controller.dart';
import 'package:godelivery_user/features/location/screens/pick_map_screen.dart';
import 'package:godelivery_user/features/location/widgets/permission_dialog.dart';
import 'package:godelivery_user/helper/business_logic/address_helper.dart';
import 'package:godelivery_user/common/widgets/shared/feedback/custom_snackbar_widget.dart';
import 'package:godelivery_user/common/widgets/shared/buttons/custom_button_widget.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';

/// Location Manager Sheet - A self-contained bottom sheet for managing user locations
/// Integrates presentation logic with content for better structure and animations
class LocationManagerSheet extends StatefulWidget {
  const LocationManagerSheet._();

  /// Show the location manager bottom sheet
  static Future<void> show(BuildContext context) async {
    CustomSheet.show(
      context: context,
      child: const _LocationManagerSheetContent(),
      showHandle: true,
      padding: EdgeInsets.zero,
      enableDrag: true,
    );
  }

  @override
  State<LocationManagerSheet> createState() => _LocationManagerSheetState();
}

class _LocationManagerSheetState extends State<LocationManagerSheet> {
  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

/// Content of the location manager sheet
class _LocationManagerSheetContent extends StatefulWidget {
  const _LocationManagerSheetContent();

  @override
  State<_LocationManagerSheetContent> createState() => _LocationManagerSheetContentState();
}

class _LocationManagerSheetContentState extends State<_LocationManagerSheetContent> {
  bool _isLoadingCurrentLocation = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'choose_your_location'.tr,
                  style: robotoBold.copyWith(
                    fontSize: Dimensions.fontSizeExtraLarge,
                    color: Theme.of(context).textTheme.bodyLarge!.color,
                  ),
                ),
              ),
              RoundedIconButtonWidget(
                icon: Icons.close_rounded,
                onPressed: () => Get.back(),
                size: 36,
                iconSize: 20,
                backgroundColor: Theme.of(context).hintColor.withValues(alpha: 0.1),
                pressedColor: Theme.of(context).hintColor.withValues(alpha: 0.2),
                iconColor: Theme.of(context).textTheme.bodyLarge!.color,
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // Content
        GetBuilder<LocationController>(
          builder: (locationController) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                Dimensions.paddingSizeDefault,
                Dimensions.paddingSizeDefault,
                Dimensions.paddingSizeDefault,
                Dimensions.paddingSizeDefault + MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Saved addresses list
                  _buildSavedAddresses(context),

                  const SizedBox(height: Dimensions.paddingSizeDefault),

                  // Explore Hopa! Zones button
                  _buildExploreZonesButton(context),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCurrentLocationOption(BuildContext context) {
    final currentAddress = AddressHelper.getAddressFromSharedPref();
    final isSelected = currentAddress?.addressType == 'current';
    final locationController = Get.find<LocationController>();
    final locationResult = locationController.lastCurrentLocationResult;
    final inZone = locationController.lastCurrentLocationInZone;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Result badge - shows after getting location with smooth animation
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: locationResult != null
              ? AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: 1.0,
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeSmall,
                      vertical: Dimensions.paddingSizeSmall,
                    ),
                    decoration: BoxDecoration(
                      color: inZone
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                      border: Border.all(
                        color: inZone
                            ? Colors.green.withValues(alpha: 0.3)
                            : Colors.orange.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          inZone
                              ? Icons.check_circle_outline_rounded
                              : Icons.warning_amber_rounded,
                          color: inZone ? Colors.green : Colors.orange,
                          size: 18,
                        ),
                        const SizedBox(width: Dimensions.paddingSizeSmall),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                locationResult,
                                style: robotoMedium.copyWith(
                                  fontSize: Dimensions.fontSizeSmall,
                                  color: Theme.of(context).textTheme.bodyLarge!.color,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (!inZone)
                                Text(
                                  'not_in_service_area'.tr,
                                  style: robotoRegular.copyWith(
                                    fontSize: Dimensions.fontSizeExtraSmall,
                                    color: Colors.orange,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Close button to dismiss result
                        GestureDetector(
                          onTap: () {
                            locationController.clearCurrentLocationResult();
                          },
                          child: Icon(
                            Icons.close_rounded,
                            color: Theme.of(context).hintColor,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),

        // Get location button
        CustomButtonWidget(
          onPressed: _isLoadingCurrentLocation ? null : () => _handleUseCurrentLocation(context),
          transparent: true,
          height: 44,
          radius: Dimensions.radiusDefault,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
            child: Row(
              children: [
                if (_isLoadingCurrentLocation)
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).primaryColor,
                    ),
                  )
                else
                  Icon(
                    Icons.my_location_rounded,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                Expanded(
                  child: Text(
                    _isLoadingCurrentLocation ? 'getting_location'.tr : 'use_current_location'.tr,
                    style: robotoMedium.copyWith(
                      fontSize: Dimensions.fontSizeDefault,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                if (isSelected && locationResult == null && !_isLoadingCurrentLocation)
                  Icon(
                    Icons.check_rounded,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSavedAddresses(BuildContext context) {
    return GetBuilder<AddressController>(
      builder: (addressController) {
        final addresses = addressController.addressList ?? [];
        final currentAddress = AddressHelper.getAddressFromSharedPref();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current location option
            _buildCurrentLocationOption(context),

            const SizedBox(height: Dimensions.paddingSizeSmall),

            // Saved addresses
            if (addresses.isNotEmpty) ...[
              ...addresses.take(5).map((address) {
                final isSelected = currentAddress?.id == address.id;
                return _buildAddressItem(context, address, isSelected);
              }),
            ] else
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeExtraSmall,
                  vertical: Dimensions.paddingSizeSmall,
                ),
                child: Text(
                  'no_saved_addresses'.tr,
                  style: robotoRegular.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildAddressItem(BuildContext context, AddressModel address, bool isSelected) {
    return CustomButtonWidget(
      onPressed: () => _handleSelectAddress(context, address),
      transparent: true,
      height: 52,
      radius: Dimensions.radiusDefault,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
        child: Row(
          children: [
            Icon(
              _getAddressIcon(address.addressType ?? 'other'),
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).hintColor,
              size: 20,
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    address.addressType?.tr ?? 'other'.tr,
                    style: robotoMedium.copyWith(
                      fontSize: Dimensions.fontSizeDefault,
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).textTheme.bodyLarge!.color,
                    ),
                  ),
                  Text(
                    address.address ?? '',
                    style: robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeExtraSmall,
                      color: Theme.of(context).hintColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_rounded,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExploreZonesButton(BuildContext context) {
    return CustomButtonWidget(
      onPressed: () => _handleExploreZones(context),
      buttonText: 'explore_hopa_zones'.tr,
      icon: Icons.explore_rounded,
      radius: Dimensions.radiusDefault,
    );
  }

  IconData _getAddressIcon(String addressType) {
    switch (addressType.toLowerCase()) {
      case 'home':
        return Icons.home_rounded;
      case 'work':
      case 'office':
        return Icons.work_rounded;
      default:
        return Icons.location_on_rounded;
    }
  }

  void _handleUseCurrentLocation(BuildContext context) async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      showCustomSnackBar('location_permission_required'.tr, isError: true);
    } else if (permission == LocationPermission.deniedForever) {
      Get.dialog(const PermissionDialog());
    } else {
      // Show loading state
      setState(() {
        _isLoadingCurrentLocation = true;
      });

      try {
        // Get current location and await result
        final addressModel = await Get.find<LocationController>().getCurrentLocation(true);

        print('📍 [CURRENT_LOCATION] Result:');
        print('   Address: ${addressModel.address}');
        print('   Lat: ${addressModel.latitude}, Lng: ${addressModel.longitude}');
        print('   Zone ID: ${addressModel.zoneId}');
        print('   In Zone: ${addressModel.zoneId != null && addressModel.zoneId != 0}');

        if (!mounted) return;

        setState(() {
          _isLoadingCurrentLocation = false;
        });

        // Store result for display in controller (persists across sheet reopens)
        final isInZone = addressModel.zoneId != null && addressModel.zoneId != 0;
        Get.find<LocationController>().setCurrentLocationResult(addressModel.address, isInZone);

        // Check if location is in a valid zone
        if (isInZone) {
          // Save to SharedPreferences
          addressModel.addressType = 'current';
          AddressHelper.saveAddressInSharedPref(addressModel);

          // Close sheet and show success
          Get.back();
          showCustomSnackBar(addressModel.address ?? 'location_set'.tr, isError: false);
        }
        // If not in zone, the result badge will show the error state
      } catch (e) {
        print('❌ [CURRENT_LOCATION] Error: $e');
        if (!mounted) return;

        setState(() {
          _isLoadingCurrentLocation = false;
        });

        showCustomSnackBar('failed_to_get_location'.tr, isError: true);
      }
    }
  }

  void _handleSelectAddress(BuildContext context, AddressModel address) {
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
  }

  void _handleExploreZones(BuildContext context) {
    Get.back();

    Future.delayed(const Duration(milliseconds: 150), () {
      // Navigate to PickMapScreen as a normal screen
      Get.to(
        () => PickMapScreen(
          fromSignUp: false,
          fromSplash: false,
          fromAddAddress: false,
          canRoute: false,
          route: 'home',
          onZoneSelected: (zone) async {
            // Close the map screen
            Get.back();

            // Change zone and refresh data (does NOT change delivery address)
            await Get.find<LocationController>().changeZone(zone);

            // Show confirmation snackbar
            Get.snackbar(
              'zone_updated'.tr,
              zone.displayName ?? zone.name ?? 'Zone ${zone.id}',
              snackPosition: SnackPosition.BOTTOM,
              duration: const Duration(seconds: 2),
            );
          },
        ),
        transition: Transition.rightToLeft,
        duration: const Duration(milliseconds: 300),
      );
    });
  }
}
