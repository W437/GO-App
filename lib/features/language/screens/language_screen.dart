import 'package:flutter/material.dart';
import 'package:godelivery_user/common/widgets/custom_app_bar_widget.dart';
import 'package:godelivery_user/common/widgets/custom_snackbar_widget.dart';
import 'package:godelivery_user/common/widgets/menu_drawer_widget.dart';
import 'package:godelivery_user/features/language/controllers/localization_controller.dart';
import 'package:godelivery_user/features/language/screens/web_language_screen.dart';
import 'package:godelivery_user/helper/responsive_helper.dart';
import 'package:godelivery_user/helper/route_helper.dart';
import 'package:godelivery_user/util/app_constants.dart';
import 'package:godelivery_user/common/widgets/custom_button_widget.dart';
import 'package:godelivery_user/features/language/widgets/language_card_widget.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

class LanguageScreen extends StatefulWidget {
  final bool fromMenu;
  const LanguageScreen({super.key, required this.fromMenu});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: (widget.fromMenu || ResponsiveHelper.isDesktop(context)) ? CustomAppBarWidget(title: 'language'.tr, isBackButtonExist: true) : null,
      endDrawer: const MenuDrawerWidget(), endDrawerEnableOpenDragGesture: false,
      backgroundColor: Theme.of(context).cardColor,
      body: SafeArea(
        child: GetBuilder<LocalizationController>(builder: (localizationController) {
          return ResponsiveHelper.isDesktop(context) ? const WebLanguageScreen() : Column(children: [

            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Lottie animation
                      Lottie.asset(
                        'assets/language_screen_lottie.json',
                        height: 200,
                        width: 200,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: Dimensions.paddingSizeLarge),

                      // Title
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
                        child: Text(
                          'choose_your_language'.tr,
                          style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                      // Subtitle
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
                        child: Text(
                          'choose_your_language_to_proceed'.tr,
                          style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeExtraLarge),

                      // Language list
                      ListView.builder(
                        itemCount: localizationController.languages.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
                        itemBuilder: (context, index) {
                          return LanguageCardWidget(
                            languageModel: localizationController.languages[index],
                            localizationController: localizationController,
                            index: index,
                          );
                        },
                      ),
                      const SizedBox(height: Dimensions.paddingSizeSmall),

                      // Muted text
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
                        child: Text(
                          'you_can_change_this_later'.tr,
                          style: robotoRegular.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            color: Theme.of(context).hintColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Next button with safe area padding
            Padding(
              padding: EdgeInsets.only(
                left: Dimensions.paddingSizeExtraLarge,
                right: Dimensions.paddingSizeExtraLarge,
                top: Dimensions.paddingSizeDefault,
                bottom: Dimensions.paddingSizeDefault,
              ),
              child: CustomButtonWidget(
                buttonText: 'next'.tr,
                onPressed: () {
                  if(localizationController.languages.isNotEmpty && localizationController.selectedLanguageIndex != -1) {
                    localizationController.setLanguage(Locale(
                      AppConstants.languages[localizationController.selectedLanguageIndex].languageCode!,
                      AppConstants.languages[localizationController.selectedLanguageIndex].countryCode,
                    ));
                    if (widget.fromMenu) {
                      Navigator.pop(context);
                    } else {
                      Get.offNamed(RouteHelper.getWelcomeRoute());
                    }
                  }else {
                    showCustomSnackBar('select_a_language'.tr);
                  }
                },
              ),
            ),

          ]);
        }),
      ),

    );
  }
}
