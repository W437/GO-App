import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/common/widgets/shared/buttons/custom_button_widget.dart';
import 'package:godelivery_user/common/widgets/shared/images/custom_image_widget.dart';
import 'package:godelivery_user/common/widgets/shared/feedback/custom_toast_widget.dart';
import 'package:godelivery_user/common/widgets/shared/forms/modern_input_field_widget.dart';
import 'package:godelivery_user/common/widgets/adaptive/navigation/unified_header_widget.dart';
import 'package:godelivery_user/common/widgets/shared/text/validate_check.dart';
import 'package:godelivery_user/features/auth/controllers/auth_controller.dart';
import 'package:godelivery_user/features/auth/domain/centralize_login_enum.dart';
import 'package:godelivery_user/features/language/controllers/localization_controller.dart';
import 'package:godelivery_user/features/splash/controllers/splash_controller.dart';
import 'package:godelivery_user/helper/utilities/custom_validator.dart';
import 'package:godelivery_user/helper/ui/responsive_helper.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/images.dart';
import 'package:godelivery_user/util/styles.dart';

class NewUserSetupScreen extends StatefulWidget {
  final String name;
  final String loginType;
  final String? phone;
  final String? email;
  const NewUserSetupScreen({super.key, required this.name, required this.loginType, required this.phone, required this.email});

  @override
  State<NewUserSetupScreen> createState() => _NewUserSetupScreenState();
}

class _NewUserSetupScreenState extends State<NewUserSetupScreen> {
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _referCodeFocus = FocusNode();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _referCodeController = TextEditingController();
  String? _countryDialCode;
  GlobalKey<FormState>? _formKeyInfo;

  bool _isSocial = false;

  @override
  void initState() {
    super.initState();


    _isSocial = widget.loginType == CentralizeLoginType.social.name;
    _formKeyInfo = GlobalKey<FormState>();
    _countryDialCode = CountryCode.fromCountryCode(Get.find<SplashController>().configModel!.country!).dialCode;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ResponsiveHelper.isDesktop(context) ? Colors.transparent : Theme.of(context).cardColor,
      appBar: ResponsiveHelper.isDesktop(context) ? null : UnifiedHeaderWidget(
        title: 'profile_setup'.tr,
        showBackButton: true,
      ),
      body: SafeArea(child: Center(child: Align(
        alignment: Alignment.center,
        child: Container(
          width: context.width > 700 ? 500 : context.width,
          padding: context.width > 700 ? const EdgeInsets.all(50) : const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraLarge),
          margin: context.width > 700 ? const EdgeInsets.all(50) : EdgeInsets.zero,
          decoration: context.width > 700 ? BoxDecoration(
            color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
            boxShadow: ResponsiveHelper.isDesktop(context) ? null : [BoxShadow(color: Colors.grey[Get.isDarkMode ? 700 : 300]!, blurRadius: 5, spreadRadius: 1)],
          ) : null,
          child: SingleChildScrollView(
            child: Form(
              key: _formKeyInfo,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [

                ResponsiveHelper.isDesktop(context) ? Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.clear),
                  ),
                ) : const SizedBox(),

                CustomImageWidget(
                  image: Get.find<SplashController>().configModel?.logoFullUrl ?? '',
                  height: 50, width: 200, fit: BoxFit.contain,
                ),
                const SizedBox(height: Dimensions.paddingSizeLarge),

                Text('just_one_step_away'.tr, style: robotoMedium.copyWith(color: Theme.of(context).disabledColor), textAlign: TextAlign.center),
                const SizedBox(height: Dimensions.paddingSizeOverLarge),

                ModernInputFieldWidget(
                  hintText: 'enter_your_name'.tr,
                  labelText: 'user_name'.tr,
                  required: true,
                  controller: _nameController,
                  focusNode: _nameFocus,
                  nextFocus: _isSocial ? _phoneFocus : _emailFocus,
                  inputType: TextInputType.name,
                  capitalization: TextCapitalization.words,
                  prefixIcon: CupertinoIcons.person_alt_circle_fill,
                  validator: (value) => ValidateCheck.validateEmptyText(value, "please_enter_your_name".tr),
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraLarge),

                _isSocial ? ModernInputFieldWidget(
                  hintText: 'xxx-xxx-xxxxx'.tr,
                  labelText: 'phone'.tr,
                  required: true,
                  controller: _phoneController,
                  focusNode: _phoneFocus,
                  nextFocus: _referCodeFocus,
                  inputType: TextInputType.phone,
                  isPhone: true,
                  onCountryChanged: (CountryCode countryCode) {
                    _countryDialCode = countryCode.dialCode;
                  },
                  countryDialCode: _countryDialCode != null ? CountryCode.fromCountryCode(Get.find<SplashController>().configModel!.country!).code
                      : Get.find<LocalizationController>().locale.countryCode,
                  validator: (value) => ValidateCheck.validateEmptyText(value, "please_enter_phone_number".tr),
                ) : ModernInputFieldWidget(
                  hintText: 'enter_email_address'.tr,
                  labelText: 'email'.tr,
                  required: false,
                  controller: _emailController,
                  focusNode: _emailFocus,
                  nextFocus: _referCodeFocus,
                  inputType: TextInputType.emailAddress,
                  prefixIcon: CupertinoIcons.mail_solid,
                  validator: (value) => value != null && value.isNotEmpty ? ValidateCheck.validateEmail(value) : null,
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraLarge),

                (Get.find<SplashController>().configModel!.refEarningStatus == 1 ) ? ModernInputFieldWidget(
                  hintText: 'refer_code'.tr,
                  labelText: 'refer_code'.tr,
                  controller: _referCodeController,
                  focusNode: _referCodeFocus,
                  inputAction: TextInputAction.done,
                  inputType: TextInputType.text,
                  capitalization: TextCapitalization.words,
                  prefixImage : Images.referCode,
                ) : const SizedBox(),
                const SizedBox(height: Dimensions.paddingSizeExtraOverLarge),

                GetBuilder<AuthController>(builder: (authController) {
                  return CustomButtonWidget(
                    buttonText: 'done'.tr,
                    isLoading: authController.isLoading,
                    onPressed: () async {
                      String name = _nameController.text.trim();
                      String referCode = _referCodeController.text.trim();
                      String number = _phoneController.text.trim();

                      String? countryCode = _countryDialCode;
                      String numberWithCountryCode = countryCode! + number;
                      PhoneValid phoneValid = await CustomValidator.isPhoneValid(numberWithCountryCode);
                      numberWithCountryCode = phoneValid.phone;

                      if (_isSocial && number.isEmpty && !_formKeyInfo!.currentState!.validate()) {
                        showCustomSnackBar('enter_phone_number'.tr);
                      } else if (_isSocial && !phoneValid.isValid && !_formKeyInfo!.currentState!.validate()) {
                        showCustomSnackBar('invalid_phone_number'.tr);
                      } else if(referCode.isNotEmpty && referCode.length != 10){
                        showCustomSnackBar('invalid_refer_code'.tr);
                      }else if(_formKeyInfo!.currentState!.validate()) {
                        authController.updatePersonalInfo(
                          name: name.isNotEmpty ? name : widget.name, phone: (widget.phone != null && widget.phone!.isNotEmpty) ?  widget.phone : _countryDialCode! + _phoneController.text.trim(),
                          loginType: widget.loginType, email: widget.email ?? _emailController.text.trim(),
                          referCode: _referCodeController.text.trim(),
                        ).then((response) {
                          if(response.isSuccess) {
                            Get.offAllNamed(RouteHelper.getAccessLocationRoute('sign-in'));
                          } else {

                            if(response.code == 'email'){
                              FocusScope.of(Get.context!).requestFocus(_emailFocus);
                            }else if(response.code == 'phone'){
                              FocusScope.of(Get.context!).requestFocus(_phoneFocus);
                            }else if(response.code == 'ref_code'){
                              FocusScope.of(Get.context!).requestFocus(_referCodeFocus);
                            }

                            showCustomSnackBar(response.message);
                          }
                        });
                      }

                    },
                  );
                }),

              ]),
            ),
          ),

        ),
      ))),
    );
  }
}
