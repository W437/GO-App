import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/features/auth/controllers/auth_controller.dart';
import 'package:godelivery_user/features/location/controllers/location_controller.dart';
import 'package:godelivery_user/features/notification/controllers/notification_controller.dart';
import 'package:godelivery_user/helper/address_helper.dart';
import 'package:godelivery_user/helper/auth_helper.dart';
import 'package:godelivery_user/helper/route_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';

class SimpleAppBarWidget extends StatelessWidget {
  const SimpleAppBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: Dimensions.paddingSizeDefault,
        right: Dimensions.paddingSizeDefault,
        bottom: Dimensions.paddingSizeSmall,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Search Button
          InkWell(
            onTap: () => Get.toNamed(RouteHelper.getSearchRoute()),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.search,
                size: 26,
                color: Theme.of(context).textTheme.bodyLarge!.color,
              ),
            ),
          ),

          const SizedBox(width: Dimensions.paddingSizeSmall),

          // Location Picker (Center)
          Expanded(
            child: GetBuilder<LocationController>(
              builder: (locationController) {
                return InkWell(
                  onTap: () => Get.toNamed(RouteHelper.getAccessLocationRoute('home')),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Location',
                        style: robotoRegular.copyWith(
                          fontSize: Dimensions.fontSizeExtraSmall,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            AuthHelper.isLoggedIn()
                                ? (AddressHelper.getAddressFromSharedPref()!.addressType == 'home'
                                    ? Icons.home_filled
                                    : AddressHelper.getAddressFromSharedPref()!.addressType == 'office'
                                        ? Icons.work
                                        : Icons.location_on)
                                : Icons.location_on,
                            size: 16,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              AddressHelper.getAddressFromSharedPref()!.address!,
                              style: robotoMedium.copyWith(
                                fontSize: Dimensions.fontSizeDefault,
                                color: Theme.of(context).textTheme.bodyLarge!.color,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.keyboard_arrow_down,
                            size: 20,
                            color: Theme.of(context).textTheme.bodyLarge!.color,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(width: Dimensions.paddingSizeSmall),

          // Notification Button
          InkWell(
            onTap: () => Get.toNamed(RouteHelper.getNotificationRoute()),
            child: GetBuilder<NotificationController>(
              builder: (notificationController) {
                return Container(
                  padding: const EdgeInsets.all(8),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        Icons.notifications_outlined,
                        size: 26,
                        color: Theme.of(context).textTheme.bodyLarge!.color,
                      ),
                      if (notificationController.hasNotification)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            height: 10,
                            width: 10,
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                width: 1.5,
                                color: Theme.of(context).cardColor,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
