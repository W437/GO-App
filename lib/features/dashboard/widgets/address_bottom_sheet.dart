import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/common/widgets/shared/buttons/custom_button_widget.dart';
import 'package:godelivery_user/common/widgets/shared/buttons/rounded_icon_button_widget.dart';
import 'package:godelivery_user/common/widgets/shared/feedback/custom_snackbar_widget.dart';
import 'package:godelivery_user/common/widgets/shared/sheets/custom_sheet.dart';
import 'package:godelivery_user/features/address/controllers/address_controller.dart';
import 'package:godelivery_user/features/address/domain/models/address_model.dart';
import 'package:godelivery_user/features/location/controllers/location_controller.dart';
import 'package:godelivery_user/features/location/widgets/permission_dialog.dart';
import 'package:godelivery_user/helper/business_logic/address_helper.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';

/// Address Bottom Sheet - Modern welcome sheet for selecting delivery location
/// Used on first app launch after splash screen
class AddressBottomSheet extends StatefulWidget {
  const AddressBottomSheet._();

  /// Show the address bottom sheet using CustomSheet
  static Future<void> show(BuildContext context) async {
    CustomSheet.show(
      context: context,
      child: const _AddressBottomSheetContent(),
      showHandle: true,
      padding: EdgeInsets.zero,
      enableDrag: true,
    );
  }

  @override
  State<AddressBottomSheet> createState() => _AddressBottomSheetState();
}

class _AddressBottomSheetState extends State<AddressBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

/// Content of the address bottom sheet
class _AddressBottomSheetContent extends StatefulWidget {
  const _AddressBottomSheetContent();

  @override
  State<_AddressBottomSheetContent> createState() => _AddressBottomSheetContentState();
}

class _AddressBottomSheetContentState extends State<_AddressBottomSheetContent> {
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'hey_welcome_back'.tr,
                      style: robotoMedium.copyWith(
                        fontSize: Dimensions.fontSizeDefault,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'which_location_do_you_want_to_select'.tr,
                      style: robotoBold.copyWith(
                        fontSize: Dimensions.fontSizeExtraLarge,
                        color: Theme.of(context).textTheme.bodyLarge!.color,
                      ),
                    ),
                  ],
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
        GetBuilder<AddressController>(
          builder: (addressController) {
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
                  // Current location option
                  _buildCurrentLocationOption(context),

                  const SizedBox(height: Dimensions.paddingSizeSmall),

                  // Saved addresses list
                  _buildSavedAddresses(context, addressController),

                  const SizedBox(height: Dimensions.paddingSizeDefault),

                  // Add new address button
                  _buildAddNewAddressButton(context),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCurrentLocationOption(BuildContext context) {
    final locationController = Get.find<LocationController>();
    final locationResult = locationController.lastCurrentLocationResult;
    final inZone = locationController.lastCurrentLocationInZone;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Result badge - shows after getting location
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
          height: 48,
          radius: Dimensions.radiusDefault,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
            child: Row(
              children: [
                if (_isLoadingCurrentLocation)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).primaryColor,
                    ),
                  )
                else
                  Icon(
                    Icons.my_location_rounded,
                    color: Theme.of(context).primaryColor,
                    size: 22,
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
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSavedAddresses(BuildContext context, AddressController addressController) {
    final addresses = addressController.addressList ?? [];
    final currentAddress = AddressHelper.getAddressFromSharedPref();

    if (addressController.addressList == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (addresses.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: addresses.take(5).map((address) {
        final isSelected = currentAddress?.id == address.id;
        return _buildAddressItem(context, address, isSelected);
      }).toList(),
    );
  }

  Widget _buildAddressItem(BuildContext context, AddressModel address, bool isSelected) {
    return CustomButtonWidget(
      onPressed: () => _handleSelectAddress(context, address),
      transparent: true,
      height: 56,
      radius: Dimensions.radiusDefault,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                    : Theme.of(context).hintColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
              ),
              child: Icon(
                _getAddressIcon(address.addressType ?? 'other'),
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).hintColor,
                size: 20,
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    (address.addressType ?? 'other').tr.capitalizeFirst ?? '',
                    style: robotoMedium.copyWith(
                      fontSize: Dimensions.fontSizeDefault,
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).textTheme.bodyLarge!.color,
                    ),
                  ),
                  const SizedBox(height: 2),
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
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddNewAddressButton(BuildContext context) {
    return CustomButtonWidget(
      onPressed: () {
        Get.back();
        Get.toNamed(RouteHelper.getAddAddressRoute(false, 0));
      },
      buttonText: 'add_new_address'.tr,
      icon: Icons.add_rounded,
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

  Future<void> _handleUseCurrentLocation(BuildContext context) async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      showCustomSnackBar('location_permission_required'.tr, isError: true);
    } else if (permission == LocationPermission.deniedForever) {
      Get.dialog(const PermissionDialog());
    } else {
      setState(() {
        _isLoadingCurrentLocation = true;
      });

      try {
        final addressModel = await Get.find<LocationController>().getCurrentLocation(true);

        if (!mounted) return;

        setState(() {
          _isLoadingCurrentLocation = false;
        });

        final isInZone = addressModel.zoneId != null && addressModel.zoneId != 0;
        Get.find<LocationController>().setCurrentLocationResult(addressModel.address, isInZone);

        if (isInZone) {
          addressModel.addressType = 'current';
          AddressHelper.saveAddressInSharedPref(addressModel);

          Get.back();
          showCustomSnackBar(addressModel.address ?? 'location_set'.tr, isError: false);
        }
      } catch (e) {
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
    showCustomSnackBar(address.address ?? 'location_set'.tr, isError: false);
  }
}
