/// Not logged in screen widget for prompting user authentication
/// Displays login prompt when user tries to access protected features

import 'package:godelivery_user/features/auth/widgets/auth_dialog_widget.dart';
import 'package:godelivery_user/features/order/controllers/order_controller.dart';
import 'package:godelivery_user/helper/ui/responsive_helper.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:godelivery_user/common/widgets/shared/buttons/custom_button_widget.dart';
import 'package:godelivery_user/common/widgets/adaptive/navigation/footer_view_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NotLoggedInScreen extends StatelessWidget {
  final Function(bool success) callBack;
  const NotLoggedInScreen({super.key, required this.callBack});

  @override
  Widget build(BuildContext context) {
    final ScrollController scrollController = ScrollController();
    return Center(
      child: SingleChildScrollView(
        controller: scrollController,
        child: FooterViewWidget(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: ResponsiveHelper.isDesktop(context) ? 500 : double.infinity,
              ),
              child: Padding(
                padding: const EdgeInsets.all(Dimensions.paddingSizeExtraLarge),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: Dimensions.paddingSizeExtraLarge),

                    // Icon with circular background
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
                      ),
                      child: Icon(
                        Icons.lock_outline_rounded,
                        size: 60,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeExtraLarge),

                    // Title
                    Text(
                      'welcome_back'.tr,
                      style: robotoBold.copyWith(
                        fontSize: Dimensions.fontSizeOverLarge,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: Dimensions.paddingSizeSmall),

                    // Description
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                      child: Text(
                        'sign_in_to_access_features'.tr,
                        style: robotoRegular.copyWith(
                          fontSize: Dimensions.fontSizeDefault,
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                      ),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeExtraLarge),

                    // Login Button
                    SizedBox(
                      width: ResponsiveHelper.isDesktop(context) ? 280 : double.infinity,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveHelper.isDesktop(context) ? 0 : Dimensions.paddingSizeDefault,
                        ),
                        child: CustomButtonWidget(
                          buttonText: 'login_to_continue'.tr,
                          onPressed: () async {
                            if (!ResponsiveHelper.isDesktop(context)) {
                              await Get.toNamed(RouteHelper.getSignInRoute(Get.currentRoute));
                            } else {
                              Get.dialog(const Center(
                                child: AuthDialogWidget(
                                  exitFromApp: false,
                                  backFromThis: true,
                                ),
                              )).then((value) => callBack(true));
                            }
                            if (Get.find<OrderController>().showBottomSheet) {
                              Get.find<OrderController>().showRunningOrders();
                            }
                            callBack(true);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeExtraLarge),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
