import 'dart:convert';

import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/common/models/response_model.dart';
import 'package:godelivery_user/common/widgets/shared/feedback/custom_snackbar_widget.dart';
import 'package:godelivery_user/common/widgets/shared/text/validate_check.dart';
import 'package:godelivery_user/features/auth/controllers/auth_controller.dart';
import 'package:godelivery_user/features/auth/domain/centralize_login_enum.dart';
import 'package:godelivery_user/features/auth/widgets/sign_in/manual_login_widget.dart';
import 'package:godelivery_user/features/auth/widgets/sign_in/otp_login_widget.dart';
import 'package:godelivery_user/features/auth/widgets/social_login_widget.dart';
import 'package:godelivery_user/features/favourite/controllers/favourite_controller.dart';
import 'package:godelivery_user/features/splash/controllers/splash_controller.dart';
import 'package:godelivery_user/features/splash/domain/models/config_model.dart';
import 'package:godelivery_user/features/verification/screens/verification_screen.dart';
import 'package:godelivery_user/helper/business_logic/centralize_login_helper.dart';
import 'package:godelivery_user/helper/utilities/custom_validator.dart';
import 'package:godelivery_user/helper/ui/responsive_helper.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';

class SignInView extends StatefulWidget {
  final bool exitFromApp;
  final bool backFromThis;
  final bool fromResetPassword;
  final Function(bool val)? isOtpViewEnable;
  const SignInView({super.key, required this.exitFromApp, required this.backFromThis, this.fromResetPassword = false, this.isOtpViewEnable});

  @override
  State<SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends State<SignInView> {
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _otpPhoneFocus = FocusNode();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _otpPhoneController = TextEditingController();
  String? _countryDialCode;
  GlobalKey<FormState>? _formKeyLogin;

  @override
  void initState() {
    super.initState();
    _formKeyLogin = GlobalKey<FormState>();
    AuthController authController  = Get.find<AuthController>();

    _countryDialCode = authController.getUserCountryCode().isNotEmpty ? authController.getUserCountryCode()
        : CountryCode.fromCountryCode(Get.find<SplashController>().configModel!.country!).dialCode;
    _phoneController.text =  authController.getUserNumber();
    _passwordController.text = authController.getUserPassword();
    _otpPhoneController.text = authController.getUserOtpPhoneNumber();

    WidgetsBinding.instance.addPostFrameCallback((_){
      bool isOtpActive = CentralizeLoginHelper.getPreferredLoginMethod(Get.find<SplashController>().configModel!.centralizeLoginSetup!, authController.isOtpViewEnable).type == CentralizeLoginType.otp
      || CentralizeLoginHelper.getPreferredLoginMethod(Get.find<SplashController>().configModel!.centralizeLoginSetup!, authController.isOtpViewEnable).type == CentralizeLoginType.otpAndSocial ;
      if(_countryDialCode != "" && _phoneController.text != "" && _phoneController.text.contains('@') && isOtpActive) {
        _phoneController.text = '';
      } else if(_countryDialCode != "" && _phoneController.text != "" && !_phoneController.text.contains('@')){
        authController.toggleIsNumberLogin(value: true);
      }else{
        authController.toggleIsNumberLogin(value: false);
      }
      authController.initCountryCode(countryCode: _countryDialCode != "" ? _countryDialCode : null);

    });

    if (!kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusScope.of(context).requestFocus(_phoneFocus);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AuthController>(builder: (authController) {
      return Form(
        key: _formKeyLogin,
        child: activeCentralizeLogin(Get.find<SplashController>().configModel!.centralizeLoginSetup!, authController),
      );
    });
  }

  Widget activeCentralizeLogin(CentralizeLoginSetup centralizeLoginSetup, AuthController authController) {
    // 🔍 DEBUG: Print login configuration
    print('═══════════════════════════════════════════════════════════');
    print('🔍 [LOGIN DEBUG] Configuration from Backend:');
    print('   Manual Login Status: ${centralizeLoginSetup.manualLoginStatus}');
    print('   OTP Login Status: ${centralizeLoginSetup.otpLoginStatus}');
    print('   Social Login Status: ${centralizeLoginSetup.socialLoginStatus}');
    print('   Google Login Status: ${centralizeLoginSetup.googleLoginStatus}');
    print('   Facebook Login Status: ${centralizeLoginSetup.facebookLoginStatus}');
    print('   Apple Login Status: ${centralizeLoginSetup.appleLoginStatus}');
    print('   isOtpViewEnable (AuthController): ${authController.isOtpViewEnable}');
    print('-----------------------------------------------------------');

    var loginMethod = CentralizeLoginHelper.getPreferredLoginMethod(centralizeLoginSetup, authController.isOtpViewEnable);
    CentralizeLoginType centralizeLogin = loginMethod.type;

    print('🎯 [LOGIN DEBUG] Selected Login Method: $centralizeLogin');
    print('   Widget Size: ${loginMethod.size}');
    print('═══════════════════════════════════════════════════════════');

    switch (centralizeLogin) {
      case CentralizeLoginType.otp:
        return OtpLoginWidget(
          phoneController: _otpPhoneController, phoneFocus: _otpPhoneFocus,
          countryDialCode: _countryDialCode,
          onCountryChanged: (CountryCode countryCode) => _countryDialCode = countryCode.dialCode,
          onClickLoginButton: () {
            _otpLogin(Get.find<AuthController>(), _countryDialCode!, CentralizeLoginType.otp);
          },
        );

      case CentralizeLoginType.manual:
        return ManualLoginWidget(
          phoneController: _phoneController, passwordController: _passwordController,
          phoneFocus: _phoneFocus, passwordFocus: _passwordFocus, onWebSubmit: (){},
          onClickLoginButton: () {
            _login(Get.find<AuthController>(), CentralizeLoginType.manual);
          },
        );

      case CentralizeLoginType.social:
        return const SocialLoginWidget(onlySocialLogin: true);

      case CentralizeLoginType.manualAndSocial:
        return ManualLoginWidget(
          phoneController: _phoneController, passwordController: _passwordController, phoneFocus: _phoneFocus, passwordFocus: _passwordFocus,
          socialEnable: true,
          onWebSubmit: (){}, onClickLoginButton: () {
            _login(Get.find<AuthController>(), CentralizeLoginType.manual);
          },
        );

      case CentralizeLoginType.manualAndOtp:
        return ManualLoginWidget(
          phoneController: _phoneController, passwordController: _passwordController, phoneFocus: _phoneFocus, passwordFocus: _passwordFocus,
          onOtpViewClick: () {
            widget.isOtpViewEnable!(true);
            if(_countryDialCode != "" && _phoneController.text != "" && _phoneController.text.contains('@')) {
              _phoneController.text = '';
            }
            setState(() {
              authController.enableOtpView(enable: true);
            });
          },
          onWebSubmit: (){},
          onClickLoginButton: () {
            _login(Get.find<AuthController>(), CentralizeLoginType.manual);
          },
        );

      case CentralizeLoginType.otpAndSocial:
        return OtpLoginWidget(
          phoneController: _otpPhoneController,
          phoneFocus: _otpPhoneFocus,
          countryDialCode: _countryDialCode,
          onCountryChanged: (CountryCode countryCode) => _countryDialCode = countryCode.dialCode,
          socialEnable: true,
          onClickLoginButton: () {
            _otpLogin(Get.find<AuthController>(), _countryDialCode!, CentralizeLoginType.otp);
          },
        );

      case CentralizeLoginType.manualAndSocialAndOtp:
        return ManualLoginWidget(
          phoneController: _phoneController, passwordController: _passwordController, phoneFocus: _phoneFocus, passwordFocus: _passwordFocus,
          onWebSubmit: (){}, socialEnable: true,
          onClickLoginButton: () {
            _login(Get.find<AuthController>(), CentralizeLoginType.manual);
          },
          onOtpViewClick: () {
            widget.isOtpViewEnable!(true);
            if(_countryDialCode != "" && _phoneController.text != "" && _phoneController.text.contains('@')) {
              _phoneController.text = '';
            }
            setState(() {
              authController.enableOtpView(enable: true);
            });
          },
        );

      }
  }


  
  void _otpLogin(AuthController authController, String countryDialCode, CentralizeLoginType loginType) async {
    String phone = _otpPhoneController.text.trim();
    String numberWithCountryCode = countryDialCode+phone;
    PhoneValid phoneValid = await CustomValidator.isPhoneValid(numberWithCountryCode);
    numberWithCountryCode = phoneValid.phone;

    if(_formKeyLogin!.currentState!.validate()) {
      if(!phoneValid.isValid) {
        showCustomSnackBar('invalid_phone_number'.tr);
      } else {
        authController.otpLogin(phone: numberWithCountryCode, otp: '', loginType: loginType.name, verified: '', alreadyInApp: widget.backFromThis).then((response) {
          if (response.isSuccess) {
            _processOtpSuccessSetup(response, authController, phone, countryDialCode);
          } else {
            showCustomSnackBar(response.message);
          }
        });
      }
    }
  }

  void _login(AuthController authController, CentralizeLoginType loginType) async {
    String phone = _phoneController.text.trim();
    String password = _passwordController.text.trim();
    String numberWithCountryCode = authController.countryDialCode + phone;
    PhoneValid phoneValid = await CustomValidator.isPhoneValid(numberWithCountryCode);
    numberWithCountryCode = phoneValid.phone;

    if(_formKeyLogin!.currentState!.validate()) {

      String isPhone = ValidateCheck.getValidPhone(authController.countryDialCode + _phoneController.text.trim(), withCountryCode: true);

      if(isPhone != "" && !phoneValid.isValid) {
        showCustomSnackBar('invalid_phone_number'.tr);
      } else {
        authController.login(
          emailOrPhone: isPhone != "" ? isPhone : phone, password: password,
          loginType: loginType.name, fieldType: isPhone !="" ? VerificationTypeEnum.phone.name : VerificationTypeEnum.email.name,
          alreadyInApp: widget.backFromThis,
        ).then((status) async {
          if (status.isSuccess) {
            _processSuccessSetup(authController, phone, isPhone, password, status);
          } else {
            showCustomSnackBar(status.message);
          }
        });
      }

    }
  }

  Future<void> _processSuccessSetup(AuthController authController, String phone, String email, String password, ResponseModel status) async {
    if (authController.isActiveRememberMe) {
      authController.saveUserNumberAndPassword(number: phone, password: password, countryCode: authController.countryDialCode, otpPoneNumber: '');
    } else {
      authController.clearUserNumberAndPassword();
    }
    if(GetPlatform.isWeb){
      await Get.find<FavouriteController>().getFavouriteList();
    }
    if(status.authResponseModel != null && !status.authResponseModel!.isPhoneVerified!) {
      List<int> encoded = utf8.encode(password);
      String data = base64Encode(encoded);
      String token = status.authResponseModel!.token??'';
      if(Get.find<SplashController>().configModel!.firebaseOtpVerification!) {
        Get.find<AuthController>().firebaseVerifyPhoneNumber(phone, token, CentralizeLoginType.manual.name, fromSignUp: true);
      } else {
        Get.toNamed(RouteHelper.getVerificationRoute(
            phone, null, token, RouteHelper.signUp, data, CentralizeLoginType.manual.name),
        );
      }
    } else if(status.authResponseModel != null && !status.authResponseModel!.isEmailVerified!) {
      List<int> encoded = utf8.encode(password);
      String data = base64Encode(encoded);
      String token = status.authResponseModel!.token??'';
      Get.toNamed(RouteHelper.getVerificationRoute(null, email, token, RouteHelper.signUp, data, CentralizeLoginType.manual.name));
    } else {
      if(widget.backFromThis) {
        if(ResponsiveHelper.isDesktop(Get.context) || widget.fromResetPassword){
          Get.offAllNamed(RouteHelper.getInitialRoute(fromSplash: false));
        } else {
          Get.back();
        }
      } else {
        Get.find<SplashController>().navigateToLocationScreen('sign-in', offNamed: true);
      }
    }
  }

  void _processOtpSuccessSetup(ResponseModel response, AuthController authController, String phone, String countryDialCode) async {
    if (authController.isActiveRememberMeForOtp) {
      authController.saveUserNumberAndPassword(number: '', password: '', countryCode: countryDialCode, otpPoneNumber: phone);
    } else {
      authController.clearUserNumberAndPassword();
    }
    if(GetPlatform.isWeb && response.authResponseModel == null){
      await Get.find<FavouriteController>().getFavouriteList();
    }
    if(response.authResponseModel != null && !response.authResponseModel!.isPhoneVerified!) {
      if(Get.find<SplashController>().configModel!.firebaseOtpVerification!) {
        Get.find<AuthController>().firebaseVerifyPhoneNumber(countryDialCode + phone, '', CentralizeLoginType.otp.name, fromSignUp: true);
      } else {
        if(ResponsiveHelper.isDesktop(Get.context)) {
          Get.back();
          Get.dialog(VerificationScreen(
            number: countryDialCode + phone, email: null, token: '', fromSignUp: true,
            fromForgetPassword: false, loginType: CentralizeLoginType.otp.name, password: '',
          ));
        } else {
          Get.toNamed(RouteHelper.getVerificationRoute(
            countryDialCode + phone, null, '', RouteHelper.signUp, null, CentralizeLoginType.otp.name,
          ));
        }
      }
    } else {
      if(widget.backFromThis) {
        if(ResponsiveHelper.isDesktop(Get.context)){
          Get.offAllNamed(RouteHelper.getInitialRoute(fromSplash: false));
        } else {
          Get.back();
        }
      }else {
        Get.find<SplashController>().navigateToLocationScreen('sign-in', offNamed: true);
      }
    }
  }
}
