import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/features/location/controllers/location_controller.dart';
import 'package:godelivery_user/features/location/domain/models/zone_list_model.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';

class ZoneListWidget extends StatelessWidget {
  final bool isBottomSheet;

  const ZoneListWidget({super.key, this.isBottomSheet = false});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LocationController>(builder: (locationController) {
      if (locationController.loadingZoneList) {
        return const Center(child: CircularProgressIndicator());
      }

      if (locationController.zoneList.isEmpty) {
        return Center(
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
        );
      }

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
            child: ListView.builder(
              shrinkWrap: true,
              physics: isBottomSheet ? const BouncingScrollPhysics() : const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.all(isBottomSheet ? Dimensions.paddingSizeDefault : 0),
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
          onTap: isActive ? () {
            locationController.selectZone(zone);
            if (isBottomSheet) {
              Get.back();
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