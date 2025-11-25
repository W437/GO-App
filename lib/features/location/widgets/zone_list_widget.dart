import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/features/location/controllers/location_controller.dart';
import 'package:godelivery_user/features/location/domain/models/zone_list_model.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class ZoneListWidget extends StatelessWidget {
  final bool isBottomSheet;
  /// Optional callback when a zone is selected.
  /// If provided, this is called instead of the default behavior.
  /// If not provided, uses LocationController.changeZone() which
  /// updates the active zone and refreshes all app data.
  final Future<void> Function(ZoneListModel zone)? onZoneSelected;

  const ZoneListWidget({
    super.key,
    this.isBottomSheet = false,
    this.onZoneSelected,
  });

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
                    : Padding(
                        padding: EdgeInsets.fromLTRB(
                          isBottomSheet ? Dimensions.paddingSizeDefault : 0,
                          isBottomSheet ? Dimensions.paddingSizeDefault : 0,
                          isBottomSheet ? Dimensions.paddingSizeDefault : 0,
                          isBottomSheet ? Dimensions.paddingSizeLarge : 0,
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: isBottomSheet ? const BouncingScrollPhysics() : const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          itemCount: locationController.zoneList.length,
                          itemBuilder: (context, index) {
                            ZoneListModel zone = locationController.zoneList[index];
                            return _buildZoneListItem(context, zone, locationController, index, locationController.zoneList.length);
                          },
                        ),
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

  Widget _buildZoneListItem(BuildContext context, ZoneListModel zone, LocationController locationController, int index, int totalCount) {
    bool isActive = zone.status == 1;
    bool isFirst = index == 0;
    bool isLast = index == totalCount - 1;

    return _ZoneListItemStateful(
      zone: zone,
      locationController: locationController,
      isActive: isActive,
      isFirst: isFirst,
      isLast: isLast,
      isBottomSheet: isBottomSheet,
      onZoneSelected: onZoneSelected,
    );
  }
}

class _ZoneListItemStateful extends StatefulWidget {
  final ZoneListModel zone;
  final LocationController locationController;
  final bool isActive;
  final bool isFirst;
  final bool isLast;
  final bool isBottomSheet;
  final Future<void> Function(ZoneListModel zone)? onZoneSelected;

  const _ZoneListItemStateful({
    required this.zone,
    required this.locationController,
    required this.isActive,
    required this.isFirst,
    required this.isLast,
    required this.isBottomSheet,
    this.onZoneSelected,
  });

  @override
  State<_ZoneListItemStateful> createState() => _ZoneListItemStatefulState();
}

class _ZoneListItemStatefulState extends State<_ZoneListItemStateful> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pressedColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.04);

    return GestureDetector(
      onTapDown: widget.isActive ? (_) {
        setState(() => _isPressed = true);
      } : null,
      onTapUp: widget.isActive ? (_) async {
        // Small delay to show pressed state
        await Future.delayed(const Duration(milliseconds: 80));

        if (mounted) {
          setState(() => _isPressed = false);

          // Close bottom sheet if open
          if (widget.isBottomSheet) {
            Get.back();
          }

          // Use callback if provided, otherwise use centralized changeZone
          if (widget.onZoneSelected != null) {
            await widget.onZoneSelected!(widget.zone);
          } else {
            // Default behavior: change zone and refresh data
            await widget.locationController.changeZone(widget.zone);
          }
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
        child: Container(
          margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeExtraSmall),
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeDefault,
            vertical: Dimensions.paddingSizeDefault,
          ),
          decoration: BoxDecoration(
            color: widget.isActive
                ? Theme.of(context).cardColor
                : Theme.of(context).disabledColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: widget.isActive
                      ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                      : Theme.of(context).disabledColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.location_city_rounded,
                  color: widget.isActive
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).disabledColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: Dimensions.paddingSizeDefault),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.zone.displayName ?? widget.zone.name ?? 'Unknown Zone',
                      style: robotoBold.copyWith(
                        fontSize: Dimensions.fontSizeDefault,
                        color: widget.isActive
                            ? Theme.of(context).textTheme.bodyLarge!.color
                            : Theme.of(context).disabledColor,
                      ),
                    ),
                    if (!widget.isActive)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'not_available'.tr,
                          style: robotoRegular.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            color: Theme.of(context).disabledColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (widget.isActive)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Theme.of(context).hintColor,
                ),
            ],
          ),
        ),
      ),
    );
  }
}