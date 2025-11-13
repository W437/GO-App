import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/common/widgets/draggable_bottom_sheet_widget.dart';
import 'package:godelivery_user/common/widgets/rounded_icon_button_widget.dart';
import 'package:godelivery_user/features/location/controllers/location_controller.dart';
import 'package:godelivery_user/features/location/screens/access_location_screen.dart';
import 'package:godelivery_user/features/notification/controllers/notification_controller.dart';
import 'package:godelivery_user/features/cart/controllers/cart_controller.dart';
import 'package:godelivery_user/helper/business_logic/address_helper.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
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
                        showDraggableBottomSheet(
                          context: context,
                          wrapContent: true,
                          maxChildSize: 0.7,
                          child: const AccessLocationScreen(
                            fromSignUp: false,
                            fromHome: true,
                            route: 'home',
                            hideAppBar: true,
                          ),
                        );
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RoundedIconButtonWidget(
                            icon: Icons.my_location,
                            onPressed: () {
                              showDraggableBottomSheet(
                                context: context,
                                wrapContent: true,
                                maxChildSize: 0.7,
                                child: const AccessLocationScreen(
                                  fromSignUp: false,
                                  fromHome: true,
                                  route: 'home',
                                  hideAppBar: true,
                                ),
                              );
                            },
                            size: 36,
                            iconSize: 20,
                            backgroundColor: Theme.of(context).hintColor.withValues(alpha: 0.1),
                            pressedColor: Theme.of(context).hintColor.withValues(alpha: 0.25),
                            iconColor: Theme.of(context).primaryColor,
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
              GetBuilder<NotificationController>(
                builder: (notificationController) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      RoundedIconButtonWidget(
                        icon: Icons.notifications_outlined,
                        onPressed: () => Get.toNamed(RouteHelper.getNotificationRoute()),
                        size: 36,
                        iconSize: 20,
                        backgroundColor: Theme.of(context).hintColor.withValues(alpha: 0.1),
                        pressedColor: Theme.of(context).hintColor.withValues(alpha: 0.25),
                        iconColor: Theme.of(context).textTheme.bodyLarge!.color,
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
                  );
                },
              ),

              const SizedBox(width: Dimensions.paddingSizeSmall),

              // Cart Button
              GetBuilder<CartController>(
                builder: (cartController) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      RoundedIconButtonWidget(
                        icon: Icons.shopping_bag_outlined,
                        onPressed: () => Get.toNamed(RouteHelper.getCartRoute()),
                        size: 36,
                        iconSize: 20,
                        backgroundColor: Theme.of(context).hintColor.withValues(alpha: 0.1),
                        pressedColor: Theme.of(context).hintColor.withValues(alpha: 0.25),
                        iconColor: Theme.of(context).textTheme.bodyLarge!.color,
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
