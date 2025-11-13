import 'dart:async';
import 'package:godelivery_user/common/models/response_model.dart';
import 'package:godelivery_user/features/auth/domain/centralize_login_enum.dart';
import 'package:godelivery_user/features/auth/screens/new_user_setup_screen.dart';
import 'package:godelivery_user/features/auth/widgets/sign_in/existing_user_bottom_sheet.dart';
import 'package:godelivery_user/features/profile/controllers/profile_controller.dart';
import 'package:godelivery_user/features/profile/domain/models/update_user_model.dart';
import 'package:godelivery_user/features/splash/controllers/splash_controller.dart';
import 'package:godelivery_user/features/auth/controllers/auth_controller.dart';
import 'package:godelivery_user/features/verification/controllers/verification_controller.dart';
import 'package:godelivery_user/features/verification/domein/model/verification_data_model.dart';
import 'package:godelivery_user/features/verification/screens/new_pass_screen.dart';
import 'package:godelivery_user/helper/business_logic/auth_helper.dart';
import 'package:godelivery_user/helper/ui/responsive_helper.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:godelivery_user/common/widgets/adaptive/navigation/unified_header_widget.dart';
import 'package:godelivery_user/common/widgets/shared/buttons/custom_button_widget.dart';
import 'package:godelivery_user/common/widgets/shared/feedback/custom_snackbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

enum VerificationTypeEnum{phone, email}

class VerificationScreen extends StatefulWidget {
  final String? number;
  final String? email;
  final bool fromSignUp;
  final String? token;
  final String? password;
  final String loginType;
  final String? firebaseSession;
  final bool fromForgetPassword;
  final UpdateUserModel? userModel;
  const VerificationScreen({super.key, required this.number, required this.password, required this.fromSignUp,
    required this.token, this.email, required this.loginType, this.firebaseSession, required this.fromForgetPassword, this.userModel});

  @override
  VerificationScreenState createState() => VerificationScreenState();
}

class VerificationScreenState extends State<VerificationScreen> {
  String? _number;
  String? _email;
  Timer? _timer;
  int _seconds = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    Get.find<VerificationController>().updateVerificationCode('', canUpdate: false);
    if(widget.number != null) {
      _number = widget.number!.startsWith('+') ? widget.number : '+${widget.number!.substring(1, widget.number!.length)}';
    }
    _email = widget.email;
    _startTimer();
  }

  void _startTimer() {
    _seconds = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _seconds = _seconds - 1;
      if(_seconds == 0) {
        timer.cancel();
        _timer?.cancel();
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    super.dispose();

    _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = ResponsiveHelper.isDesktop(context);
    return Scaffold(
      appBar: isDesktop ? null : UnifiedHeaderWidget(
        title: _email != null ? 'Email Verification' : 'Phone Verification',
        showBackButton: true,
        centerTitle: true,
        showBorder: true,
      ),
      backgroundColor: isDesktop ? Colors.transparent : null,
      body: SafeArea(child: Center(child: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
        child: Center(child: Container(
          width: context.width > 700 ? 500 : context.width,
          padding: context.width > 700 ? const EdgeInsets.all(Dimensions.paddingSizeDefault) : null,
          decoration: context.width > 700 ? BoxDecoration(
            color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
          ) : null,
          child: GetBuilder<VerificationController>(builder: (verificationController) {
            return Column(children: [

              isDesktop ? Align(
                alignment: Alignment.topRight,
                child: IconButton(onPressed: ()=> Get.back(), icon: const Icon(Icons.clear)),
              ) : const SizedBox(),

              isDesktop ? Padding(
                padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeLarge),
                child: Text(
                  'otp_verification'.tr, style: robotoRegular,
                ),
              ) : const SizedBox(),

              // Larger illustration with background container - placeholder
              Container(
                width: context.width > 700 ? 350 : context.width * 0.85,
                height: context.width > 700 ? 280 : 220,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).primaryColor.withValues(alpha: 0.15),
                      Theme.of(context).primaryColor.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.mail_outline_rounded,
                        size: context.width > 700 ? 80 : 60,
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.6),
                      ),
                      const SizedBox(height: 20),
                      Icon(
                        Icons.security_rounded,
                        size: context.width > 700 ? 40 : 30,
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.4),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 50),

              // Bold heading
              Text(
                'Check your messages',
                style: robotoBold.copyWith(
                  fontSize: Dimensions.fontSizeOverLarge + 4,
                  color: Theme.of(context).textTheme.bodyLarge!.color,
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeDefault),

              // Subtitle text
              Get.find<SplashController>().configModel!.demo! ? Text(
                'for_demo_purpose'.tr, style: robotoMedium,
              ) : SizedBox(
                width: context.width > 700 ? 400 : context.width * 0.8,
                child: Text(
                  _email != null
                    ? 'We\'ve sent a 6-digit code to your email. Please enter it below.'
                    : 'We\'ve sent a 6-digit code to your phone. Please enter it below.',
                  style: robotoRegular.copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                    color: Theme.of(context).disabledColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              Container(
                constraints: BoxConstraints(
                  maxWidth: context.width > 700 ? 450 : context.width * 0.95,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 40
                ),
                child: PinCodeTextField(
                  length: 6,
                  appContext: context,
                  keyboardType: TextInputType.number,
                  animationType: AnimationType.fade,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  pinTheme: PinTheme(
                    shape: PinCodeFieldShape.box,
                    fieldHeight: context.width > 400 ? 60 : 48,
                    fieldWidth: context.width > 400 ? 50 : 38,
                    borderWidth: 1.5,
                    borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                    selectedColor: Theme.of(context).primaryColor,
                    selectedFillColor: Theme.of(context).cardColor,
                    inactiveFillColor: Theme.of(context).cardColor,
                    inactiveColor: Theme.of(context).disabledColor.withValues(alpha: 0.3),
                    activeColor: Theme.of(context).primaryColor.withValues(alpha: 0.6),
                    activeFillColor: Theme.of(context).cardColor,
                    inactiveBorderWidth: 1.5,
                    selectedBorderWidth: 2,
                    disabledBorderWidth: 1.5,
                    errorBorderWidth: 1.5,
                    activeBorderWidth: 1.5,
                  ),
                  textStyle: robotoBold.copyWith(
                    fontSize: Dimensions.fontSizeLarge,
                    color: Theme.of(context).textTheme.bodyLarge!.color,
                  ),
                  animationDuration: const Duration(milliseconds: 300),
                  backgroundColor: Colors.transparent,
                  enableActiveFill: true,
                  onChanged: verificationController.updateVerificationCode,
                  beforeTextPaste: (text) => true,
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),

              GetBuilder<ProfileController>(
                  builder: (profileController) {
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 50 : context.width > 400 ? 30 : 20),
                      child: CustomButtonWidget(
                        buttonText: 'Verify',
                        height: 55,
                        fontSize: Dimensions.fontSizeDefault + 1,
                        isLoading: verificationController.isLoading || profileController.isLoading,
                        onPressed: verificationController.verificationCode.length < 6 ? null : () {
                          if(widget.firebaseSession != null && widget.userModel == null) {
                            verificationController.verifyFirebaseOtp(
                              phoneNumber: _number!, session: widget.firebaseSession!, loginType: widget.loginType,
                              otp: verificationController.verificationCode, token: widget.token, isForgetPassPage: widget.fromForgetPassword,
                              isSignUpPage: widget.loginType == CentralizeLoginType.otp.name ? false : true,
                            ).then((value) {
                              if(value.isSuccess) {
                                _handleVerifyResponse(value, _number, _email);
                              }else {
                                showCustomSnackBar(value.message);
                              }
                            });
                          } else if(widget.userModel != null) {
                            widget.userModel!.otp = verificationController.verificationCode;
                            Get.find<ProfileController>().updateUserInfo(widget.userModel!, Get.find<AuthController>().getUserToken(), fromButton: true).then((response) async {
                              if(response.isSuccess) {
                                profileController.getUserInfo();
                                Get.back();
                                Get.back();
                                showCustomSnackBar(response.message, isError: false);
                              } else if(!response.isSuccess && response.updateProfileResponseModel != null){
                                showCustomSnackBar(response.updateProfileResponseModel!.message);
                              } else {
                                showCustomSnackBar(response.message);
                              }
                            });
                          }
                          else if(widget.fromSignUp) {
                            verificationController.verifyPhone(data: VerificationDataModel(
                              phone: _number, email: _email, verificationType: _number != null
                                ? VerificationTypeEnum.phone.name : VerificationTypeEnum.email.name,
                              otp: verificationController.verificationCode, loginType: widget.loginType,
                              guestId: AuthHelper.getGuestId(),
                            )).then((value) {
                              if(value.isSuccess) {
                                _handleVerifyResponse(value, _number, _email);
                              } else {
                                showCustomSnackBar(value.message);
                              }
                            });
                          } else {
                            verificationController.verifyToken(phone: _number, email: _email).then((value) {
                              if(value.isSuccess) {
                                if(ResponsiveHelper.isDesktop(Get.context!)){
                                  Get.back();
                                  Get.dialog(Center(child: NewPassScreen(resetToken: verificationController.verificationCode, number : _number, email: _email, fromPasswordChange: false, fromDialog: true )));
                                }else{
                                  Get.toNamed(RouteHelper.getResetPasswordRoute(phone: _number, email: _email, token: verificationController.verificationCode, page: 'reset-password'));
                                }
                              }else {
                                showCustomSnackBar(value.message);
                              }
                            });
                          }
                        },
                      ),
                    );
                  }
              ),
              const SizedBox(height: Dimensions.paddingSizeLarge * 2),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: isDesktop ? 50 : context.width > 400 ? 30 : 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Didn\'t receive a code? ',
                      style: robotoRegular.copyWith(
                        color: Theme.of(context).disabledColor,
                        fontSize: Dimensions.fontSizeDefault,
                      ),
                    ),
                    _seconds > 0
                      ? Text(
                          'Resend code in 0:${_seconds.toString().padLeft(2, '0')}',
                          style: robotoMedium.copyWith(
                            color: Theme.of(context).primaryColor,
                            fontSize: Dimensions.fontSizeDefault,
                          ),
                        )
                      : InkWell(
                          onTap: () async {
                            if(widget.firebaseSession != null) {
                              await Get.find<AuthController>().firebaseVerifyPhoneNumber(_number!, widget.token, widget.loginType, fromSignUp: widget.fromSignUp, canRoute: false);
                              _startTimer();
                            } else {
                              _resendOtp();
                            }
                          },
                          child: Text(
                            'Resend code',
                            style: robotoMedium.copyWith(
                              color: Theme.of(context).primaryColor,
                              fontSize: Dimensions.fontSizeDefault,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                  ],
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeLarge),

            ]);
          }),
        )),
      ))),
    );
  }

  void _handleVerifyResponse(ResponseModel response, String? number, String? email) {
    if(response.authResponseModel != null && response.authResponseModel!.isExistUser != null) {
      if(ResponsiveHelper.isDesktop(context)) {
        Get.back();
        Get.dialog(Center(
          child: ExistingUserBottomSheet(
            userModel: response.authResponseModel!.isExistUser!, number: _number, email: _email,
            loginType: widget.loginType, otp: Get.find<VerificationController>().verificationCode,
          ),
        ));
      } else {
        Get.bottomSheet(ExistingUserBottomSheet(
          userModel: response.authResponseModel!.isExistUser!, number: _number, email: _email,
          loginType: widget.loginType, otp: Get.find<VerificationController>().verificationCode,
        ));
      }
    } else if(response.authResponseModel != null && !response.authResponseModel!.isPersonalInfo!) {
      if(ResponsiveHelper.isDesktop(context)) {
        Get.back();
        Get.dialog(NewUserSetupScreen(name: '', loginType: widget.loginType, phone: number, email: email));
      } else {
        Get.toNamed(RouteHelper.getNewUserSetupScreen(name: '', loginType: widget.loginType, phone: number, email: email));
      }
    } else {
      if(widget.fromForgetPassword) {
        if(ResponsiveHelper.isDesktop(Get.context!)){
          Get.back();
          Get.dialog(Center(child: NewPassScreen(resetToken: Get.find<VerificationController>().verificationCode, number : _number, email: _email, fromPasswordChange: false, fromDialog: true )));
        }else{
          Get.toNamed(RouteHelper.getResetPasswordRoute(phone: _number, email: _email, token: Get.find<VerificationController>().verificationCode, page: 'reset-password'));
        }
      } else {
        Get.offNamed(RouteHelper.getAccessLocationRoute('verification'));
      }
    }
  }

  void _resendOtp() {
    if(widget.userModel != null) {
      Get.find<ProfileController>().updateUserInfo(widget.userModel!, Get.find<AuthController>().getUserToken(), fromVerification: true);
    } else if(widget.fromSignUp) {
      if(widget.loginType == CentralizeLoginType.otp.name) {
        Get.find<AuthController>().otpLogin(phone: _number!, otp: '', loginType: widget.loginType, verified: '').then((response) {
          if (response.isSuccess) {
            _startTimer();
            showCustomSnackBar('resend_code_successful'.tr, isError: false);
          } else {
            showCustomSnackBar(response.message);
          }
        });
      } else {
        Get.find<AuthController>().login(
          emailOrPhone: _number != null ? _number! : _email ?? '', password: widget.password!, loginType: widget.loginType,
          fieldType: _number != null ? VerificationTypeEnum.phone.name : VerificationTypeEnum.email.name,
        ).then((value) {
          if (value.isSuccess) {
            _startTimer();
            showCustomSnackBar('resend_code_successful'.tr, isError: false);
          } else {
            showCustomSnackBar(value.message);
          }
        });
      }
    } else {
      Get.find<VerificationController>().forgetPassword(phone: _number, email: _email).then((value) {
        if (value.isSuccess) {
          _startTimer();
          showCustomSnackBar('resend_code_successful'.tr, isError: false);
        } else {
          showCustomSnackBar(value.message);
        }
      });
    }
  }
}
