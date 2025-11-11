import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/features/location/controllers/location_controller.dart';
import 'package:godelivery_user/features/location/screens/access_location_screen.dart';
import 'package:godelivery_user/features/notification/controllers/notification_controller.dart';
import 'package:godelivery_user/features/cart/controllers/cart_controller.dart';
import 'package:godelivery_user/helper/address_helper.dart';
import 'package:godelivery_user/helper/route_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';

/// Simple home header widget with location, notification, and cart
class NewHomeHeaderWidget extends StatelessWidget {
  const NewHomeHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeDefault,
            vertical: Dimensions.paddingSizeSmall,
          ),
          child: Row(
            children: [
              // Location Picker on the left
              Expanded(
                child: GetBuilder<LocationController>(
                  builder: (locationController) {
                    return InkWell(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => DraggableScrollableSheet(
                            initialChildSize: 0.9,
                            minChildSize: 0.5,
                            maxChildSize: 0.95,
                            builder: (context, scrollController) => ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(24),
                                topRight: Radius.circular(24),
                              ),
                              child: Container(
                                color: Theme.of(context).colorScheme.surface,
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: Dimensions.paddingSizeDefault,
                                        vertical: Dimensions.paddingSizeSmall,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.surface,
                                        border: Border(
                                          bottom: BorderSide(
                                            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          IconButton(
                                            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                                            icon: const Icon(Icons.keyboard_arrow_down, size: 32),
                                          ),
                                          Expanded(
                                            child: Center(
                                              child: Text(
                                                'set_location'.tr,
                                                style: robotoBold.copyWith(
                                                  fontSize: Dimensions.fontSizeLarge,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 48),
                                        ],
                                      ),
                                    ),
                                    const Expanded(
                                      child: AccessLocationScreen(
                                        fromSignUp: false,
                                        fromHome: true,
                                        route: 'home',
                                        hideAppBar: true,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).hintColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.location_on,
                              color: Theme.of(context).primaryColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              AddressHelper.getAddressFromSharedPref()!.address!,
                              style: robotoMedium.copyWith(
                                fontSize: Dimensions.fontSizeDefault,
                                color: Theme.of(context).textTheme.bodyLarge!.color,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.keyboard_arrow_down,
                            color: Theme.of(context).textTheme.bodyLarge!.color,
                            size: 20,
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
                      decoration: BoxDecoration(
                        color: Theme.of(context).hintColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            Icons.notifications_outlined,
                            color: Theme.of(context).textTheme.bodyLarge!.color,
                            size: 20,
                          ),
                          if (notificationController.hasNotification)
                            Positioned(
                              top: -4,
                              right: -4,
                              child: Container(
                                height: 10,
                                width: 10,
                                decoration: BoxDecoration(
                                  color: Colors.red,
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

              const SizedBox(width: Dimensions.paddingSizeSmall),

              // Cart Button
              GetBuilder<CartController>(
                builder: (cartController) {
                  return InkWell(
                    onTap: () => Get.toNamed(RouteHelper.getCartRoute()),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).hintColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            Icons.shopping_bag_outlined,
                            color: Theme.of(context).textTheme.bodyLarge!.color,
                            size: 20,
                          ),
                          if (cartController.cartList.isNotEmpty)
                            Positioned(
                              top: -6,
                              right: -6,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 18,
                                  minHeight: 18,
                                ),
                                child: Text(
                                  '${cartController.cartList.length}',
                                  style: robotoMedium.copyWith(
                                    fontSize: 10,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
