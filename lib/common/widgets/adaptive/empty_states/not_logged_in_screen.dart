import 'package:godelivery_user/features/auth/widgets/auth_dialog_widget.dart';
import 'package:godelivery_user/features/order/controllers/order_controller.dart';
import 'package:godelivery_user/helper/ui/responsive_helper.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:godelivery_user/util/app_colors.dart';
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
                    const SizedBox(height: Dimensions.paddingSizeOverLarge),

                    // Icon with gradient background
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.brandPrimary.withValues(alpha: 0.1),
                            AppColors.brandPrimary.withValues(alpha: 0.05),
                          ],
                        ),
                        border: Border.all(
                          color: AppColors.brandPrimary.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.lock_outline_rounded,
                          size: 70,
                          color: AppColors.brandPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeOverLarge),

                    // Title
                    Text(
                      'welcome_back'.tr,
                      style: robotoBold.copyWith(
                        fontSize: Dimensions.fontSizeOverLarge,
                        color: AppColors.brandSecondary,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: Dimensions.paddingSizeSmall),

                    // Description
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
                      child: Text(
                        'sign_in_to_access_features'.tr,
                        style: robotoRegular.copyWith(
                          fontSize: Dimensions.fontSizeDefault,
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Login Button
                    SizedBox(
                      width: ResponsiveHelper.isDesktop(context) ? 300 : double.infinity,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveHelper.isDesktop(context) ? 0 : Dimensions.paddingSizeDefault,
                        ),
                        child: CustomButtonWidget(
                          buttonText: 'login_to_continue'.tr,
                          height: 50,
                          radius: Dimensions.radiusDefault,
                          isBold: true,
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
                    const SizedBox(height: Dimensions.paddingSizeOverLarge),
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
