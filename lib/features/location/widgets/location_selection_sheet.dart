import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/common/widgets/shared/buttons/rounded_icon_button_widget.dart';
import 'package:godelivery_user/common/widgets/shared/sheets/custom_sheet.dart';
import 'package:godelivery_user/features/address/domain/models/address_model.dart';
import 'package:godelivery_user/features/address/controllers/address_controller.dart';
import 'package:godelivery_user/features/location/controllers/location_controller.dart';
import 'package:godelivery_user/features/location/widgets/all_zones_sheet.dart';
import 'package:godelivery_user/helper/business_logic/address_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';

class LocationSelectionSheet extends StatelessWidget {
  final Function(AddressModel)? onLocationSelected;
  final Function()? onAddNewLocation;
  final VoidCallback? onUseCurrentLocation;

  const LocationSelectionSheet({
    super.key,
    this.onLocationSelected,
    this.onAddNewLocation,
    this.onUseCurrentLocation,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LocationController>(builder: (locationController) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
            // Header with title and close button
            Padding(
                padding: const EdgeInsets.only(
                  bottom: Dimensions.paddingSizeDefault,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'choose_your_location'.tr,
                      style: robotoBold.copyWith(
                        fontSize: Dimensions.fontSizeExtraLarge,
                        color: Theme.of(context).textTheme.bodyLarge!.color,
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

              // Content
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Current location option
                      _buildCurrentLocationOption(context, locationController),

                      const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                      // User's saved addresses
                      _buildSavedAddresses(context, locationController),

                      const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                      // Explore service areas button
                      _buildExploreServiceAreasButton(context),

                      const SizedBox(height: Dimensions.paddingSizeDefault),

                      // Add new location button
                      _buildAddNewLocationButton(context),

                      const SizedBox(height: Dimensions.paddingSizeDefault),
                    ],
                  ),
                ),
              ),
            ],
      );
    });
  }

  Widget _buildCurrentLocationOption(BuildContext context, LocationController locationController) {
    AddressModel? currentAddress = AddressHelper.getAddressFromSharedPref();
    bool isSelected = currentAddress?.addressType == 'current';

    return _IOSStyleButton(
      onTap: onUseCurrentLocation,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeDefault,
          vertical: Dimensions.paddingSizeDefault,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.my_location_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeDefault),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'current_location'.tr,
                    style: robotoBold.copyWith(
                      fontSize: Dimensions.fontSizeDefault,
                      color: Theme.of(context).textTheme.bodyLarge!.color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'app_will_use_your_current_location'.tr,
                    style: robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: Theme.of(context).hintColor,
                    ),
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
    );
  }

  Widget _buildSavedAddresses(BuildContext context, LocationController locationController) {
    // Get user's saved addresses from AddressController
    List<AddressModel> addresses = Get.find<AddressController>().addressList ?? [];

    if (addresses.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: addresses.take(3).map((address) {
        AddressModel? currentAddress = AddressHelper.getAddressFromSharedPref();
        bool isSelected = currentAddress?.id == address.id;

        return Padding(
          padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
          child: _IOSStyleButton(
            onTap: () {
              if (onLocationSelected != null) {
                onLocationSelected!(address);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeDefault,
                vertical: Dimensions.paddingSizeDefault,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).primaryColor.withValues(alpha: 0.05)
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getAddressIcon(address.addressType ?? 'other'),
                      color: Theme.of(context).hintColor,
                      size: 20,
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
                        const SizedBox(height: 2),
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
        );
      }).toList(),
    );
  }

  Widget _buildExploreServiceAreasButton(BuildContext context) {
    return _IOSStyleButton(
      onTap: () {
        CustomSheet.show(
          context: context,
          child: const AllZonesSheet(),
          showHandle: true,
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeExtraLarge,
            vertical: Dimensions.paddingSizeDefault,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeDefault,
          vertical: Dimensions.paddingSizeDefault,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.public_rounded,
                color: Theme.of(context).hintColor,
                size: 20,
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeDefault),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'explore_our_service_areas'.tr,
                    style: robotoBold.copyWith(
                      fontSize: Dimensions.fontSizeDefault,
                      color: Theme.of(context).textTheme.bodyLarge!.color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'see_where_we_are_operating'.tr,
                    style: robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Theme.of(context).hintColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddNewLocationButton(BuildContext context) {
    return _IOSStyleButton(
      onTap: onAddNewLocation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          vertical: Dimensions.paddingSizeDefault + 2,
          horizontal: Dimensions.paddingSizeDefault,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'add_new_location'.tr,
              style: robotoBold.copyWith(
                fontSize: Dimensions.fontSizeDefault,
                color: Colors.white,
              ),
            ),
          ],
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
}

/// iOS-style button with opacity fade effect on press
class _IOSStyleButton extends StatefulWidget {
  final VoidCallback? onTap;
  final Widget child;

  const _IOSStyleButton({
    required this.onTap,
    required this.child,
  });

  @override
  State<_IOSStyleButton> createState() => _IOSStyleButtonState();
}

class _IOSStyleButtonState extends State<_IOSStyleButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: widget.onTap != null ? (_) async {
        await Future.delayed(const Duration(milliseconds: 80));
        if (mounted) {
          setState(() => _isPressed = false);
          widget.onTap!();
        }
      } : null,
      onTapCancel: () {
        if (mounted) {
          setState(() => _isPressed = false);
        }
      },
      child: AnimatedOpacity(
        opacity: _isPressed ? 0.6 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: widget.child,
      ),
    );
  }
}
