import 'dart:async';
import 'package:godelivery_user/common/models/response_model.dart';
import 'package:godelivery_user/features/auth/domain/centralize_login_enum.dart';
import 'package:godelivery_user/features/auth/screens/new_user_setup_screen.dart';
import 'package:godelivery_user/features/auth/widgets/sign_in/existing_user_bottom_sheet.dart';
import 'package:godelivery_user/features/profile/controllers/profile_controller.dart';
import 'package:godelivery_user/features/profile/domain/models/update_user_model.dart';
import 'package:godelivery_user/helper/business_logic/auth_helper.dart';
import 'package:godelivery_user/features/splash/controllers/splash_controller.dart';
import 'package:godelivery_user/features/auth/controllers/auth_controller.dart';
import 'package:godelivery_user/features/verification/controllers/verification_controller.dart';
import 'package:godelivery_user/features/verification/domein/model/verification_data_model.dart';
import 'package:godelivery_user/features/verification/screens/new_pass_screen.dart';
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

/// Lightweight inline OTP step for embedding inside auth flows (no Scaffold).
class InlineVerificationStep extends StatefulWidget {
  final String? number;
  final String? email;
  final String loginType;
  final bool fromForgetPassword;
  final bool fromSignUp;
  final String? firebaseSession;
  final VoidCallback onBack;
  final VoidCallback onVerified;

  const InlineVerificationStep({
    super.key,
    required this.number,
    required this.email,
    required this.loginType,
    required this.fromForgetPassword,
    this.fromSignUp = true,
    this.firebaseSession,
    required this.onBack,
    required this.onVerified,
  });

  @override
  State<InlineVerificationStep> createState() => _InlineVerificationStepState();
}

class _InlineVerificationStepState extends State<InlineVerificationStep> {
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
    return GetBuilder<VerificationController>(builder: (verificationController) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).primaryColor.withValues(alpha: 0.15),
                  Theme.of(context).primaryColor.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
            ),
            child: Center(
              child: Icon(
                _email != null ? Icons.mail_outline_rounded : Icons.message_rounded,
                size: 70,
                color: Theme.of(context).primaryColor.withValues(alpha: 0.6),
              ),
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeExtraLarge),

          Text(
            'check_your_messages'.tr,
            style: robotoBold.copyWith(
              fontSize: Dimensions.fontSizeOverLarge,
              color: Theme.of(context).textTheme.bodyLarge!.color,
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
            child: Text(
              _email != null
                ? 'verification_email_message'.tr
                : 'verification_phone_message'.tr,
              style: robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeDefault,
                color: Theme.of(context).disabledColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeExtraLarge * 1.5),

          // Pin code field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
            child: PinCodeTextField(
              length: 6,
              appContext: context,
              keyboardType: TextInputType.number,
              animationType: AnimationType.fade,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                fieldHeight: 56,
                fieldWidth: 46,
                borderWidth: 1.5,
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                selectedColor: Theme.of(context).primaryColor,
                activeColor: Theme.of(context).primaryColor.withValues(alpha: 0.6),
                inactiveColor: Theme.of(context).disabledColor.withValues(alpha: 0.3),
                selectedFillColor: Theme.of(context).cardColor,
                activeFillColor: Theme.of(context).cardColor,
                inactiveFillColor: Theme.of(context).cardColor,
              ),
              cursorColor: Theme.of(context).primaryColor,
              animationDuration: const Duration(milliseconds: 150),
              enableActiveFill: true,
              textStyle: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge),
              onChanged: (value) => verificationController.updateVerificationCode(value, canUpdate: false),
              beforeTextPaste: (text) => true,
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeExtraLarge * 2),

          // Bottom action section
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeDefault,
              vertical: Dimensions.paddingSizeDefault,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                  width: 0.5,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomButtonWidget(
                  buttonText: 'verify'.tr,
                  isLoading: verificationController.isLoading,
                  onPressed: verificationController.verificationCode.length < 6
                      ? null
                      : () => _verifyOtp(context, verificationController),
                ),
                const SizedBox(height: Dimensions.paddingSizeSmall),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'didnt_receive_code'.tr,
                      style: robotoRegular.copyWith(
                        color: Theme.of(context).disabledColor,
                        fontSize: Dimensions.fontSizeSmall,
                      ),
                    ),
                    const SizedBox(width: 4),
                    TextButton(
                      onPressed: _seconds == 0
                          ? () async {
                              _startTimer();
                              await _resendOtp();
                            }
                          : null,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        _seconds == 0
                            ? 'resend_code'.tr
                            : '0:${_seconds.toString().padLeft(2, '0')}',
                        style: robotoMedium.copyWith(
                          color: _seconds == 0
                              ? Theme.of(context).primaryColor
                              : Theme.of(context).disabledColor,
                          fontSize: Dimensions.fontSizeSmall,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  void _verifyOtp(BuildContext context, VerificationController verificationController) {
    if (widget.fromSignUp) {
      verificationController.verifyPhone(
        data: VerificationDataModel(
          phone: _number,
          email: _email,
          verificationType: _number != null ? VerificationTypeEnum.phone.name : VerificationTypeEnum.email.name,
          otp: verificationController.verificationCode,
          loginType: widget.loginType,
          guestId: AuthHelper.getGuestId(),
        ),
      ).then((ResponseModel response) {
        if (response.isSuccess) {
          widget.onVerified();
        } else {
          showCustomSnackBar(response.message);
        }
      });
    } else {
      verificationController.verifyToken(phone: _number, email: _email).then((ResponseModel response) {
        if (response.isSuccess) {
          widget.onVerified();
        } else {
          showCustomSnackBar(response.message);
        }
      });
    }
  }

  Future<void> _resendOtp() async {
    if (widget.fromSignUp && widget.loginType == CentralizeLoginType.otp.name && _number != null) {
      await Get.find<AuthController>().otpLogin(phone: _number!, otp: '', loginType: widget.loginType, verified: '');
      showCustomSnackBar('resend_code_successful'.tr, isError: false);
    } else {
      final resp = await Get.find<VerificationController>().forgetPassword(phone: _number, email: _email);
      if (resp.isSuccess) {
        showCustomSnackBar('resend_code_successful'.tr, isError: false);
      } else {
        showCustomSnackBar(resp.message);
      }
    }
  }
}

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
        title: _email != null ? 'email_verification'.tr : 'phone_verification'.tr,
        showBackButton: true,
        centerTitle: true,
        showBorder: true,
      ),
      backgroundColor: isDesktop ? Colors.transparent : null,
      body: GetBuilder<VerificationController>(builder: (verificationController) {
        return Column(
          children: [
            // Main content area - centered in viewport
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isDesktop)
                          Align(
                            alignment: Alignment.topRight,
                            child: IconButton(
                              onPressed: () => Get.back(),
                              icon: const Icon(Icons.clear),
                            ),
                          ),

                        // Illustration
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Theme.of(context).primaryColor.withValues(alpha: 0.15),
                                Theme.of(context).primaryColor.withValues(alpha: 0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
                          ),
                          child: Center(
                            child: Icon(
                              _email != null ? Icons.mail_outline_rounded : Icons.message_rounded,
                              size: 70,
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                        const SizedBox(height: Dimensions.paddingSizeExtraLarge),

                        Text(
                          'check_your_messages'.tr,
                          style: robotoBold.copyWith(
                            fontSize: Dimensions.fontSizeOverLarge,
                            color: Theme.of(context).textTheme.bodyLarge!.color,
                          ),
                        ),
                        const SizedBox(height: Dimensions.paddingSizeSmall),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
                          child: Text(
                            _email != null
                              ? 'verification_email_message'.tr
                              : 'verification_phone_message'.tr,
                            style: robotoRegular.copyWith(
                              fontSize: Dimensions.fontSizeDefault,
                              color: Theme.of(context).disabledColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: Dimensions.paddingSizeExtraLarge * 1.5),

                        // Pin code field
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                          child: PinCodeTextField(
                            length: 6,
                            appContext: context,
                            keyboardType: TextInputType.number,
                            animationType: AnimationType.fade,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            pinTheme: PinTheme(
                              shape: PinCodeFieldShape.box,
                              fieldHeight: 56,
                              fieldWidth: 46,
                              borderWidth: 1.5,
                              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                              selectedColor: Theme.of(context).primaryColor,
                              activeColor: Theme.of(context).primaryColor.withValues(alpha: 0.6),
                              inactiveColor: Theme.of(context).disabledColor.withValues(alpha: 0.3),
                              selectedFillColor: Theme.of(context).cardColor,
                              activeFillColor: Theme.of(context).cardColor,
                              inactiveFillColor: Theme.of(context).cardColor,
                            ),
                            cursorColor: Theme.of(context).primaryColor,
                            animationDuration: const Duration(milliseconds: 150),
                            enableActiveFill: true,
                            textStyle: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge),
                            onChanged: verificationController.updateVerificationCode,
                            beforeTextPaste: (text) => true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Bottom action section
            Container(
              padding: EdgeInsets.fromLTRB(
                Dimensions.paddingSizeDefault,
                Dimensions.paddingSizeDefault,
                Dimensions.paddingSizeDefault,
                Dimensions.paddingSizeDefault + MediaQuery.of(context).padding.bottom,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                    width: 0.5,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GetBuilder<ProfileController>(
                    builder: (profileController) {
                      return CustomButtonWidget(
                        buttonText: 'verify'.tr,
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
                      );
                    }
                  ),
                  const SizedBox(height: Dimensions.paddingSizeSmall),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'didnt_receive_code'.tr,
                        style: robotoRegular.copyWith(
                          color: Theme.of(context).disabledColor,
                          fontSize: Dimensions.fontSizeSmall,
                        ),
                      ),
                      const SizedBox(width: 4),
                      TextButton(
                        onPressed: _seconds == 0
                            ? () async {
                                if(widget.firebaseSession != null) {
                                  await Get.find<AuthController>().firebaseVerifyPhoneNumber(_number!, widget.token, widget.loginType, fromSignUp: widget.fromSignUp, canRoute: false);
                                  _startTimer();
                                } else {
                                  _resendOtp();
                                }
                              }
                            : null,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          _seconds == 0
                              ? 'resend_code'.tr
                              : '0:${_seconds.toString().padLeft(2, '0')}',
                          style: robotoMedium.copyWith(
                            color: _seconds == 0
                                ? Theme.of(context).primaryColor
                                : Theme.of(context).disabledColor,
                            fontSize: Dimensions.fontSizeSmall,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      }),
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
        Get.back();
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
