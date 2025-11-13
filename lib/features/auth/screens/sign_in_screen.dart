import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/common/widgets/unified_header_widget.dart';
import 'package:godelivery_user/common/widgets/custom_image_widget.dart';
import 'package:godelivery_user/features/auth/controllers/auth_controller.dart';
import 'package:godelivery_user/features/auth/widgets/sign_in/sign_in_view.dart';
import 'package:godelivery_user/features/splash/controllers/splash_controller.dart';
import 'package:godelivery_user/helper/ui/responsive_helper.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:lottie/lottie.dart';

class SignInScreen extends StatefulWidget {
  final bool exitFromApp;
  final bool backFromThis;
  final bool fromResetPassword;
  const SignInScreen({super.key, required this.exitFromApp, required this.backFromThis, this.fromResetPassword = false});

  @override
  SignInScreenState createState() => SignInScreenState();
}

class SignInScreenState extends State<SignInScreen> {
  bool _canExit = GetPlatform.isWeb ? true : false;


  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if(widget.exitFromApp) {
          if (_canExit) {
            if (GetPlatform.isAndroid) {
              SystemNavigator.pop();
            } else if (GetPlatform.isIOS) {
              exit(0);
            } else {
              Navigator.pushNamed(context, RouteHelper.getInitialRoute());
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('back_press_again_to_exit'.tr, style: const TextStyle(color: Colors.white)),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
              margin: const EdgeInsets.all(Dimensions.paddingSizeSmall),
            ));
            _canExit = true;
            Timer(const Duration(seconds: 2), () {
              _canExit = false;
            });
          }
        }else {
          if(Get.find<AuthController>().isOtpViewEnable){
            Get.find<AuthController>().enableOtpView(enable: false);
          }else{
            Get.back();
          }
        }
      },
      child: Scaffold(
        backgroundColor: ResponsiveHelper.isDesktop(context) ? Colors.transparent : Theme.of(context).cardColor,
        appBar: widget.exitFromApp ? null : UnifiedHeaderWidget(
          title: '',
          showBackButton: true,
          onBackPressed: () {
            if(Get.find<AuthController>().isOtpViewEnable){
              Get.find<AuthController>().enableOtpView(enable: false);
            }else{
              Get.back(result: false);
            }
          },
        ),
        body: SafeArea(
          top: widget.exitFromApp,
          child: Align(
            alignment: Alignment.center,
            child: Container(
              width: context.width > 700 ? 500 : context.width,
              padding: context.width > 700 ? const EdgeInsets.all(50) : const EdgeInsets.all(Dimensions.paddingSizeLarge),
              margin: context.width > 700 ? const EdgeInsets.all(50) : EdgeInsets.zero,
              decoration: context.width > 700 ? BoxDecoration(
                color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                boxShadow: ResponsiveHelper.isDesktop(context) ? null : [BoxShadow(color: Colors.grey[Get.isDarkMode ? 700 : 300]!, blurRadius: 5, spreadRadius: 1)],
              ) : null,
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height -
                               MediaQuery.of(context).padding.top -
                               MediaQuery.of(context).padding.bottom -
                               (widget.exitFromApp ? 0 : 56) - // AppBar height (UnifiedHeaderWidget preferredSize)
                               (Dimensions.paddingSizeLarge * 2), // Container padding
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Avatar/Logo
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            'H!',
                            style: robotoBold.copyWith(
                              fontSize: 36,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: Dimensions.paddingSizeExtraLarge),

                      SignInView(exitFromApp: widget.exitFromApp, backFromThis: widget.backFromThis, fromResetPassword: widget.fromResetPassword, isOtpViewEnable: (v){},),

                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

}

