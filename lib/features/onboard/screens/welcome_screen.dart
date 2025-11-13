import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/images.dart';
import 'package:godelivery_user/util/styles.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-navigate to onboarding after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Get.offNamed(RouteHelper.getOnBoardingRoute());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () => Get.offNamed(RouteHelper.getOnBoardingRoute()),
        child: Stack(
          children: [
            // Background image
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(Images.welcomeBg),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Dark gradient overlay
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),

            // Content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome title
                    Text(
                      'welcome_title'.tr,
                      style: robotoBold.copyWith(
                        fontSize: 36,
                        color: Theme.of(context).primaryColor,
                        height: 1.2,
                      ),
                    ),

                    const SizedBox(height: Dimensions.paddingSizeDefault),

                    // Description
                    Text(
                      'welcome_description'.tr,
                      style: robotoRegular.copyWith(
                        fontSize: Dimensions.fontSizeDefault,
                        color: Colors.white,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
