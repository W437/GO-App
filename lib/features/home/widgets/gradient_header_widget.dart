import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/common/widgets/emoji_profile_picture.dart';
import 'package:godelivery_user/features/auth/controllers/auth_controller.dart';
import 'package:godelivery_user/features/location/controllers/location_controller.dart';
import 'package:godelivery_user/features/notification/controllers/notification_controller.dart';
import 'package:godelivery_user/features/profile/controllers/profile_controller.dart';
import 'package:godelivery_user/features/profile/widgets/guest_login_bottom_sheet.dart';
import 'package:godelivery_user/helper/address_helper.dart';
import 'package:godelivery_user/helper/auth_helper.dart';
import 'package:godelivery_user/helper/route_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/images.dart';
import 'package:godelivery_user/util/styles.dart';

class GradientHeaderWidget extends StatelessWidget {
  const GradientHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Stack(
        children: [
          // Background logo
          Positioned(
            right: -40,
            top: 60,
            child: Opacity(
              opacity: 0.15,
              child: Image.asset(
                Images.logo,
                width: 180,
                height: 180,
                color: Colors.white,
                fit: BoxFit.contain,
              ),
            ),
          ),
          SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top bar with profile, location, and refresh
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeDefault,
                vertical: Dimensions.paddingSizeSmall,
              ),
              child: Row(
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
                          size: 44,
                          borderWidth: 2,
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
                          onTap: () => Get.toNamed(RouteHelper.getAccessLocationRoute('home')),
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
                        return Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              const Icon(
                                Icons.notifications_outlined,
                                color: Colors.white,
                                size: 24,
                              ),
                              if (notificationController.hasNotification)
                                Positioned(
                                  top: -2,
                                  right: -2,
                                  child: Container(
                                    height: 10,
                                    width: 10,
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        width: 1.5,
                                        color: Theme.of(context).primaryColor,
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

            // Large heading
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Dimensions.paddingSizeLarge,
                Dimensions.paddingSizeDefault,
                Dimensions.paddingSizeLarge,
                Dimensions.paddingSizeDefault,
              ),
              child: Text(
                'what_you_like_to_eat'.tr,
                style: robotoBold.copyWith(
                  fontSize: 28,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Dimensions.paddingSizeDefault,
                0,
                Dimensions.paddingSizeDefault,
                Dimensions.paddingSizeLarge,
              ),
              child: InkWell(
                onTap: () => Get.toNamed(RouteHelper.getSearchRoute()),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeDefault,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search,
                        color: Theme.of(context).hintColor,
                        size: 22,
                      ),
                      const SizedBox(width: Dimensions.paddingSizeSmall),
                      Expanded(
                        child: Text(
                          'search_menu_restaurant_craving'.tr,
                          style: robotoRegular.copyWith(
                            fontSize: Dimensions.fontSizeDefault,
                            color: Theme.of(context).hintColor,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.tune,
                        color: Theme.of(context).hintColor,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
          ),
        ],
      ),
    );
  }
}
