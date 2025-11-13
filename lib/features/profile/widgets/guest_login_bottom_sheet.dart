import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/common/widgets/shared/buttons/custom_button_widget.dart';
import 'package:godelivery_user/common/widgets/shared/images/emoji_profile_picture.dart';
import 'package:godelivery_user/features/auth/widgets/auth_dialog_widget.dart';
import 'package:godelivery_user/helper/ui/responsive_helper.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';

class GuestLoginBottomSheet extends StatelessWidget {
  final VoidCallback onLoginSuccess;

  const GuestLoginBottomSheet({super.key, required this.onLoginSuccess});

  @override
  Widget build(BuildContext context) {
    bool isDesktop = ResponsiveHelper.isDesktop(context);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(Dimensions.radiusExtraLarge),
          topRight: Radius.circular(Dimensions.radiusExtraLarge),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + Dimensions.paddingSizeLarge,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: Dimensions.paddingSizeLarge),

          // Guest emoji profile
          const EmojiProfilePicture(
            emoji: null, // Will use default
            bgColorHex: null, // Will use default
            size: 80,
          ),

          const SizedBox(height: Dimensions.paddingSizeDefault),

          // Guest User title
          Text(
            'guest_user'.tr,
            style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge),
          ),

          const SizedBox(height: Dimensions.paddingSizeSmall),

          // Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraLarge),
            child: Text(
              'currently_you_are_in_guest_mode_please_login_to_view_all_the_features'.tr,
              style: robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeDefault,
                color: Theme.of(context).hintColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: Dimensions.paddingSizeExtraLarge),

          // Login Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraLarge),
            child: CustomButtonWidget(
              buttonText: 'login'.tr,
              onPressed: () async {
                Get.back(); // Close bottom sheet
                if (!isDesktop) {
                  await Get.toNamed(RouteHelper.getSignInRoute(Get.currentRoute))?.then((value) {
                    onLoginSuccess();
                  });
                } else {
                  Get.dialog(const Center(child: AuthDialogWidget(exitFromApp: false, backFromThis: false)))
                      .then((value) {
                    onLoginSuccess();
                  });
                }
              },
            ),
          ),

          const SizedBox(height: Dimensions.paddingSizeDefault),
        ],
      ),
    );
  }
}
