import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/common/widgets/custom_button_widget.dart';
import 'package:godelivery_user/common/widgets/custom_text_field_widget.dart';
import 'package:godelivery_user/common/widgets/validate_check.dart';
import 'package:godelivery_user/features/auth/controllers/auth_controller.dart';
import 'package:godelivery_user/features/auth/widgets/social_login_widget.dart';
import 'package:godelivery_user/features/auth/widgets/trams_conditions_check_box_widget.dart';
import 'package:godelivery_user/features/language/controllers/localization_controller.dart';
import 'package:godelivery_user/features/splash/controllers/splash_controller.dart';
import 'package:godelivery_user/helper/ui/responsive_helper.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';

class OtpLoginWidget extends StatelessWidget {
  final TextEditingController phoneController;
  final FocusNode phoneFocus;
  final String? countryDialCode;
  final Function(CountryCode countryCode)? onCountryChanged;
  final Function() onClickLoginButton;
  final bool socialEnable;
  const OtpLoginWidget({super.key, required this.phoneController, required this.phoneFocus, required this.onCountryChanged, required this.countryDialCode, required this.onClickLoginButton, this.socialEnable = false});

  @override
  Widget build(BuildContext context) {
    bool isDesktop = ResponsiveHelper.isDesktop(context);
    return GetBuilder<AuthController>(builder: (authController) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: isDesktop ? Dimensions.paddingSizeLarge : 0),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Title
          Text(
            'Sign in to continue',
            style: robotoBold.copyWith(
              fontSize: 28,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          // Subtitle
          Text(
            'Enter your phone number to get started.',
            style: robotoRegular.copyWith(
              fontSize: Dimensions.fontSizeDefault,
              color: Theme.of(context).hintColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Dimensions.paddingSizeExtraLarge),

          // Phone number field
          CustomTextFieldWidget(
            hintText: '555-123-4567',
            controller: phoneController,
            focusNode: phoneFocus,
            inputAction: TextInputAction.done,
            inputType: TextInputType.phone,
            isPhone: true,
            onCountryChanged: onCountryChanged,
            countryDialCode: CountryCode.fromCountryCode(Get.find<SplashController>().configModel!.country!).code ?? Get.find<LocalizationController>().locale.countryCode,
            labelText: 'Phone number',
            required: false,
            validator: (value) => ValidateCheck.validateEmptyText(value, "please_enter_phone_number".tr),
          ),
          const SizedBox(height: Dimensions.paddingSizeLarge),

          // Continue button
          CustomButtonWidget(
            buttonText: 'Continue',
            isBold: true,
            isLoading: authController.isLoading,
            onPressed: onClickLoginButton,
          ),
          const SizedBox(height: Dimensions.paddingSizeLarge),

          // "or" divider
          if (socialEnable)
            Row(
              children: [
                Expanded(child: Divider(color: Theme.of(context).disabledColor.withOpacity(0.3))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                  child: Text(
                    'or',
                    style: robotoRegular.copyWith(
                      color: Theme.of(context).hintColor,
                      fontSize: Dimensions.fontSizeDefault,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: Theme.of(context).disabledColor.withOpacity(0.3))),
              ],
            ),

          if (socialEnable)
            const SizedBox(height: Dimensions.paddingSizeSmall),

          // Social login buttons
          socialEnable ? const SocialLoginWidget(onlySocialLogin: true, showWelcomeText: false) : const SizedBox(),

          const SizedBox(height: Dimensions.paddingSizeSmall),

          // Terms and Privacy - centered text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: robotoRegular.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: Theme.of(context).hintColor,
                ),
                children: [
                  const TextSpan(text: 'By continuing, you agree to our '),
                  TextSpan(
                    text: 'Terms of Service',
                    style: robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: Theme.of(context).primaryColor,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => Get.toNamed(RouteHelper.getHtmlRoute('terms-and-condition')),
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: Theme.of(context).primaryColor,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => Get.toNamed(RouteHelper.getHtmlRoute('privacy-policy')),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
          ),

          !socialEnable ? const SizedBox(height: 100) : const SizedBox(),

        ]),
      );
    });
  }
}
