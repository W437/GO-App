import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/common/widgets/shared/buttons/rounded_icon_button_widget.dart';
import 'package:godelivery_user/features/location/controllers/location_controller.dart';
import 'package:godelivery_user/features/location/widgets/zone_list_widget.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';

class AllZonesSheet extends StatelessWidget {
  const AllZonesSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
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
                    'our_service_areas'.tr,
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

            const Divider(height: 1),

            // Zone list
            Expanded(
              child: GetBuilder<LocationController>(builder: (locationController) {
                return const ZoneListWidget(isBottomSheet: false);
              }),
            ),
          ],
      ),
    );
  }
}
