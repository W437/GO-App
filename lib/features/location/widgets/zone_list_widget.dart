import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/common/widgets/custom_loader_widget.dart';
import 'package:godelivery_user/features/address/domain/models/address_model.dart';
import 'package:godelivery_user/features/auth/controllers/auth_controller.dart';
import 'package:godelivery_user/features/location/controllers/location_controller.dart';
import 'package:godelivery_user/features/location/domain/models/zone_list_model.dart';
import 'package:godelivery_user/features/profile/controllers/profile_controller.dart';
import 'package:godelivery_user/helper/responsive_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class ZoneListWidget extends StatelessWidget {
  final bool isBottomSheet;

  const ZoneListWidget({super.key, this.isBottomSheet = false});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LocationController>(builder: (locationController) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isBottomSheet) ...[
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
              decoration: BoxDecoration(
                color: Theme.of(context).disabledColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'select_delivery_zone'.tr,
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
          ],

          Flexible(
            child: locationController.loadingZoneList
                ? ListView.builder(
                    shrinkWrap: true,
                    physics: isBottomSheet ? const BouncingScrollPhysics() : const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      isBottomSheet ? Dimensions.paddingSizeDefault : 0,
                      isBottomSheet ? Dimensions.paddingSizeDefault : 0,
                      isBottomSheet ? Dimensions.paddingSizeDefault : 0,
                      isBottomSheet ? Dimensions.paddingSizeLarge : 0,
                    ),
                    itemCount: 5, // Show 5 shimmer items
                    itemBuilder: (context, index) {
                      return _buildZoneShimmer(context);
                    },
                  )
                : locationController.zoneList.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.location_off, size: 50, color: Theme.of(context).disabledColor),
                              const SizedBox(height: Dimensions.paddingSizeSmall),
                              Text(
                                'no_zones_available'.tr,
                                style: robotoMedium.copyWith(color: Theme.of(context).disabledColor),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: isBottomSheet ? const BouncingScrollPhysics() : const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          isBottomSheet ? Dimensions.paddingSizeDefault : 0,
                          isBottomSheet ? Dimensions.paddingSizeDefault : 0,
                          isBottomSheet ? Dimensions.paddingSizeDefault : 0,
                          isBottomSheet ? Dimensions.paddingSizeLarge : 0,
                        ),
                        itemCount: locationController.zoneList.length,
                        itemBuilder: (context, index) {
                          ZoneListModel zone = locationController.zoneList[index];
                          return _buildZoneCard(context, zone, locationController);
                        },
                      ),
          ),
        ],
      );
    });
  }

  Widget _buildZoneShimmer(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        border: Border.all(
          color: Theme.of(context).disabledColor.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Shimmer(
                  color: Theme.of(context).disabledColor.withOpacity(0.3),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Theme.of(context).disabledColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Shimmer(
                        color: Theme.of(context).disabledColor.withOpacity(0.3),
                        child: Container(
                          height: 16,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Theme.of(context).disabledColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                Shimmer(
                  color: Theme.of(context).disabledColor.withOpacity(0.3),
                  child: Container(
                    width: 60,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Theme.of(context).disabledColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Shimmer(
              color: Theme.of(context).disabledColor.withOpacity(0.3),
              child: Container(
                width: double.infinity,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).disabledColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoneCard(BuildContext context, ZoneListModel zone, LocationController locationController) {
    bool isActive = zone.status == 1;

    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        border: Border.all(
          color: isActive
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
          onTap: isActive ? () async {
            locationController.selectZone(zone);
            if (isBottomSheet) {
              Get.back();
            }

            // Navigate after zone selection
            Get.dialog(const CustomLoaderWidget(), barrierDismissible: false);

            // Create an address from the zone's center point
            if (zone.formattedCoordinates != null && zone.formattedCoordinates!.isNotEmpty) {
              double totalLat = 0;
              double totalLng = 0;
              int count = zone.formattedCoordinates!.length;

              for (var coord in zone.formattedCoordinates!) {
                totalLat += coord.lat!;
                totalLng += coord.lng!;
              }

              double centerLat = totalLat / count;
              double centerLng = totalLng / count;

              AddressModel address = AddressModel(
                latitude: centerLat.toString(),
                longitude: centerLng.toString(),
                address: zone.displayName ?? zone.name ?? 'Selected Zone',
                addressType: 'others',
              );

              if (!Get.find<AuthController>().isGuestLoggedIn() || !Get.find<AuthController>().isLoggedIn()) {
                var response = await Get.find<AuthController>().guestLogin();
                if (response.isSuccess) {
                  Get.find<ProfileController>().setForceFullyUserEmpty();
                  locationController.saveAddressAndNavigate(address, false, null, false, ResponsiveHelper.isDesktop(Get.context));
                }
              } else {
                locationController.saveAddressAndNavigate(address, false, null, false, ResponsiveHelper.isDesktop(Get.context));
              }
            }
          } : null,
          child: Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                          if (!isActive) ...[
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
                    if (isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'available'.tr,
                          style: robotoMedium.copyWith(
                            fontSize: Dimensions.fontSizeExtraSmall,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),

                if (isActive) ...[
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                  Container(
                    padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.local_shipping,
                          size: 16,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            zone.shippingInfo,
                            style: robotoRegular.copyWith(
                              fontSize: Dimensions.fontSizeSmall,
                              color: Theme.of(context).textTheme.bodyMedium!.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}