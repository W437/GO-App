import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:godelivery_user/common/widgets/shared/buttons/rounded_icon_button_widget.dart';
import 'package:godelivery_user/features/address/domain/models/address_model.dart';
import 'package:godelivery_user/features/address/controllers/address_controller.dart';
import 'package:godelivery_user/features/location/controllers/location_controller.dart';
import 'package:godelivery_user/features/location/screens/pick_map_screen.dart';
import 'package:godelivery_user/features/location/widgets/permission_dialog.dart';
import 'package:godelivery_user/helper/business_logic/address_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';

/// Location Manager Sheet - A self-contained bottom sheet for managing user locations
/// Integrates presentation logic with content for better structure and animations
class LocationManagerSheet extends StatefulWidget {
  const LocationManagerSheet._();

  /// Show the location manager bottom sheet
  static Future<void> show(BuildContext context) async {
    final controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: Navigator.of(context),
    );

    final animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    controller.forward();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      transitionAnimationController: controller,
      builder: (context) => _LocationManagerSheetContent(animation: animation),
    );

    await controller.reverse();
    controller.dispose();
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
  final Animation<double> animation;

  const _LocationManagerSheetContent({required this.animation});

  @override
  State<_LocationManagerSheetContent> createState() => _LocationManagerSheetContentState();
}

class _LocationManagerSheetContentState extends State<_LocationManagerSheetContent> {
  bool _isLoadingCurrentLocation = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.animation,
      builder: (context, child) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(Dimensions.radiusExtraLarge),
              topRight: Radius.circular(Dimensions.radiusExtraLarge),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle indicator
              Container(
                margin: const EdgeInsets.only(top: Dimensions.paddingSizeDefault),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

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
              Flexible(
                child: GetBuilder<LocationController>(
                  builder: (locationController) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Current location option
                          _buildCurrentLocationOption(context),

                          const SizedBox(height: Dimensions.paddingSizeDefault),

                          // Saved addresses
                          _buildSavedAddresses(context),

                          const SizedBox(height: Dimensions.paddingSizeDefault),

                          // Explore Hopa! Zones button
                          _buildExploreZonesButton(context),

                          const SizedBox(height: Dimensions.paddingSizeDefault),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCurrentLocationOption(BuildContext context) {
    final currentAddress = AddressHelper.getAddressFromSharedPref();
    final isSelected = currentAddress?.addressType == 'current';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isLoadingCurrentLocation ? null : () => _handleUseCurrentLocation(context),
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        child: Container(
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
            border: Border.all(
              color: isSelected
                ? Theme.of(context).primaryColor.withValues(alpha: 0.3)
                : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                ),
                child: _isLoadingCurrentLocation
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Icon(
                        Icons.my_location_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
              ),
              const SizedBox(width: Dimensions.paddingSizeDefault),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isLoadingCurrentLocation
                          ? 'getting_location'.tr
                          : 'current_location'.tr,
                      style: robotoBold.copyWith(
                        fontSize: Dimensions.fontSizeDefault,
                        color: Theme.of(context).textTheme.bodyLarge!.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isLoadingCurrentLocation
                          ? 'please_wait'.tr
                          : 'app_will_use_your_current_location'.tr,
                      style: robotoRegular.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected && !_isLoadingCurrentLocation)
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSavedAddresses(BuildContext context) {
    return GetBuilder<AddressController>(
      builder: (addressController) {
        final addresses = addressController.addressList ?? [];

        if (addresses.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: Dimensions.paddingSizeExtraSmall,
                bottom: Dimensions.paddingSizeSmall,
              ),
              child: Text(
                'saved_addresses'.tr,
                style: robotoMedium.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: Theme.of(context).hintColor,
                ),
              ),
            ),
            ...addresses.take(3).map((address) {
              final currentAddress = AddressHelper.getAddressFromSharedPref();
              final isSelected = currentAddress?.id == address.id;

              return Padding(
                padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _handleSelectAddress(context, address),
                    borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                    child: Container(
                      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                      decoration: BoxDecoration(
                        color: isSelected
                          ? Theme.of(context).primaryColor.withValues(alpha: 0.05)
                          : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                        border: Border.all(
                          color: isSelected
                            ? Theme.of(context).primaryColor.withValues(alpha: 0.3)
                            : Theme.of(context).dividerColor.withValues(alpha: 0.1),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                            ),
                            child: Icon(
                              _getAddressIcon(address.addressType ?? 'other'),
                              color: Theme.of(context).hintColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: Dimensions.paddingSizeDefault),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  address.addressType?.tr ?? 'other'.tr,
                                  style: robotoBold.copyWith(
                                    fontSize: Dimensions.fontSizeDefault,
                                    color: Theme.of(context).textTheme.bodyLarge!.color,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  address.address ?? '',
                                  style: robotoRegular.copyWith(
                                    fontSize: Dimensions.fontSizeSmall,
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
                              Icons.check_circle,
                              color: Theme.of(context).primaryColor,
                              size: 24,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildExploreZonesButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleExploreZones(context),
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: Dimensions.paddingSizeDefault + 4,
            horizontal: Dimensions.paddingSizeDefault,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.explore_rounded,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Text(
                'explore_hopa_zones'.tr,
                style: robotoBold.copyWith(
                  fontSize: Dimensions.fontSizeDefault,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
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
      Get.snackbar(
        'permission_required'.tr,
        'location_permission_required'.tr,
      );
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

        // Check if location is in a valid zone
        if (addressModel.zoneId != null && addressModel.zoneId != 0) {
          // Save to SharedPreferences
          addressModel.addressType = 'current';
          AddressHelper.saveAddressInSharedPref(addressModel);

          // Close sheet and show success
          Get.back();
          Get.snackbar(
            'location_set'.tr,
            addressModel.address ?? 'current_location'.tr,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
        } else {
          // Location not in service zone
          Get.snackbar(
            'location_not_available'.tr,
            'current_location_not_in_zone'.tr,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
        }
      } catch (e) {
        print('❌ [CURRENT_LOCATION] Error: $e');
        if (!mounted) return;

        setState(() {
          _isLoadingCurrentLocation = false;
        });

        Get.snackbar(
          'error'.tr,
          'failed_to_get_location'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
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
