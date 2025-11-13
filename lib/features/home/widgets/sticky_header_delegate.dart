import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/common/widgets/emoji_profile_picture.dart';
import 'package:godelivery_user/features/location/controllers/location_controller.dart';
import 'package:godelivery_user/features/notification/controllers/notification_controller.dart';
import 'package:godelivery_user/features/profile/controllers/profile_controller.dart';
import 'package:godelivery_user/features/profile/widgets/guest_login_bottom_sheet.dart';
import 'package:godelivery_user/helper/business_logic/address_helper.dart';
import 'package:godelivery_user/helper/business_logic/auth_helper.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';

class StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;

  StickyHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    // Get safe area padding
    final topPadding = MediaQuery.of(context).padding.top;

    // Calculate border radius based on scroll offset (0 to 24px)
    final progress = (shrinkOffset / maxExtent).clamp(0.0, 1.0);
    final borderRadius = progress * 24.0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor,
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(borderRadius),
          bottomRight: Radius.circular(borderRadius),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          top: topPadding + 6,
          left: Dimensions.paddingSizeDefault,
          right: Dimensions.paddingSizeDefault,
          bottom: 6,
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
                      size: 36,
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
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.white.withValues(alpha: 0.9),
                                size: 14,
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            AddressHelper.getAddressFromSharedPref()!.address!,
                            style: robotoMedium.copyWith(
                              fontSize: 13,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
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
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            Icons.notifications_outlined,
                            color: Theme.of(context).primaryColor,
                            size: 20,
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
    );
  }

  @override
  bool shouldRebuild(StickyHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight || minHeight != oldDelegate.minHeight;
  }
}
