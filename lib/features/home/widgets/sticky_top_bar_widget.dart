import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/common/widgets/emoji_profile_picture.dart';
import 'package:godelivery_user/features/location/controllers/location_controller.dart';
import 'package:godelivery_user/features/location/screens/access_location_screen.dart';
import 'package:godelivery_user/features/notification/controllers/notification_controller.dart';
import 'package:godelivery_user/features/profile/controllers/profile_controller.dart';
import 'package:godelivery_user/features/profile/widgets/guest_login_bottom_sheet.dart';
import 'package:godelivery_user/helper/address_helper.dart';
import 'package:godelivery_user/helper/auth_helper.dart';
import 'package:godelivery_user/helper/route_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';

class StickyTopBarWidget extends StatelessWidget {
  final double scrollOffset;

  const StickyTopBarWidget({super.key, this.scrollOffset = 0});

  @override
  Widget build(BuildContext context) {
    // Calculate border radius based on scroll offset
    // Start showing rounded corners after scrolling 50px, fully rounded at 100px
    final borderRadiusProgress = ((scrollOffset - 50.0) / 50.0).clamp(0.0, 1.0);
    final borderRadius = (borderRadiusProgress * 24.0).clamp(0.0, 24.0);

    // Calculate opacity and blur - starts after 200px scroll, completes at 400px
    final fadeProgress = ((scrollOffset - 200.0) / 200.0).clamp(0.0, 1.0);
    final backgroundOpacity = 1.0 - (fadeProgress * 0.25); // Goes from 1.0 to 0.75
    final blurAmount = fadeProgress * 10.0; // Blur from 0 to 10

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor.withValues(alpha: backgroundOpacity),
                Theme.of(context).primaryColor.withValues(alpha: backgroundOpacity),
              ],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(borderRadius),
              bottomRight: Radius.circular(borderRadius),
            ),
          ),
          child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeDefault,
            vertical: Dimensions.paddingSizeSmall,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Picture
              GetBuilder<ProfileController>(
                builder: (profileController) {
                  return InkWell(
                    onTap: () {
                      if (AuthHelper.isLoggedIn()) {
                        Get.toNamed(RouteHelper.getProfileRoute());
                      } else {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => GuestLoginBottomSheet(
                            onLoginSuccess: () {
                              profileController.getUserInfo();
                            },
                          ),
                        );
                      }
                    },
                    child: EmojiProfilePicture(
                      emoji: AuthHelper.isLoggedIn() ? profileController.userInfoModel?.profileEmoji : null,
                      bgColorHex: AuthHelper.isLoggedIn() ? profileController.userInfoModel?.profileBgColor : null,
                      size: 53,
                      borderWidth: 2.4,
                      borderColor: Colors.white.withValues(alpha: 0.3),
                    ),
                  );
                },
              ),

              const SizedBox(width: Dimensions.paddingSizeSmall),

              // Location Picker
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
                                    // Sheet header with drag handle and close button
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
                                          const SizedBox(width: 48), // Balance the back button
                                        ],
                                      ),
                                    ),
                                    // Content
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'delivery_location'.tr,
                                style: robotoRegular.copyWith(
                                  fontSize: Dimensions.fontSizeSmall,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.white.withValues(alpha: 0.9),
                                size: 16,
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Flexible(
                            child: Text(
                              AddressHelper.getAddressFromSharedPref()!.address!,
                              style: robotoMedium.copyWith(
                                fontSize: Dimensions.fontSizeDefault,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
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
                    return SizedBox(
                      width: 53,
                      height: 53,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.notifications_outlined,
                            color: Colors.white,
                            size: 26,
                          ),
                          if (notificationController.hasNotification)
                            Positioned(
                              top: 2,
                              right: 2,
                              child: Container(
                                height: 10,
                                width: 10,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    width: 1.5,
                                    color: Colors.white,
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
        ),
          ),
        ),
      ),
    );
  }
}
