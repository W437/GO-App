import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/common/widgets/custom_asset_image_widget.dart';
import 'package:godelivery_user/common/widgets/custom_button_widget.dart';
import 'package:godelivery_user/features/auth/controllers/auth_controller.dart';
import 'package:godelivery_user/features/onboard/controllers/onboard_controller.dart';
import 'package:godelivery_user/features/splash/controllers/splash_controller.dart';
import 'package:godelivery_user/helper/business_logic/address_helper.dart';
import 'package:godelivery_user/helper/utilities/notification_helper.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:godelivery_user/main.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';

class OnBoardingScreen extends StatelessWidget {
  OnBoardingScreen({super.key});
  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    Get.find<OnBoardingController>().getOnBoardingList();
    return GetBuilder<OnBoardingController>(builder: (onBoardingController) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: onBoardingController.onBoardingList != null
            ? Stack(
                children: [
                  // Decorative background circles
                  Positioned(
                    top: 100,
                    left: 30,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 150,
                    right: 50,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 400,
                    right: 30,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 500,
                    left: 50,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 200,
                    left: 20,
                    child: Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 250,
                    right: 60,
                    child: Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),

                  // Main content
                  SafeArea(
                    child: Container(
                      margin: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: Column(
                        children: [
                          // PageView
                          Expanded(
                            child: PageView.builder(
                              controller: _pageController,
                              itemCount: onBoardingController.onBoardingList!.length,
                              onPageChanged: (index) {
                                onBoardingController.changeSelectIndex(index);
                              },
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.all(Dimensions.paddingSizeExtraLarge),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Illustration
                                      CustomAssetImageWidget(
                                        onBoardingController.onBoardingList![index].imageUrl,
                                        width: MediaQuery.of(context).size.width * 0.6,
                                        height: MediaQuery.of(context).size.height * 0.35,
                                        fit: BoxFit.contain,
                                      ),

                                      const SizedBox(height: Dimensions.paddingSizeExtraLarge),

                                      // Title
                                      Text(
                                        onBoardingController.onBoardingList![index].title,
                                        style: robotoBold.copyWith(
                                          fontSize: 28,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),

                                      const SizedBox(height: Dimensions.paddingSizeDefault),

                                      // Description
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                                        child: Text(
                                          onBoardingController.onBoardingList![index].description,
                                          style: robotoRegular.copyWith(
                                            fontSize: Dimensions.fontSizeDefault,
                                            color: Theme.of(context).disabledColor,
                                            height: 1.5,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),

                          // Pagination dots
                          Padding(
                            padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeLarge),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                onBoardingController.onBoardingList!.length,
                                (index) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  width: index == onBoardingController.selectedIndex ? 32 : 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: index == onBoardingController.selectedIndex
                                        ? Theme.of(context).primaryColor
                                        : Theme.of(context).disabledColor.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Next/Get Started button
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              Dimensions.paddingSizeExtraLarge,
                              0,
                              Dimensions.paddingSizeExtraLarge,
                              Dimensions.paddingSizeExtraLarge,
                            ),
                            child: CustomButtonWidget(
                              buttonText: onBoardingController.selectedIndex == 2
                                  ? 'get_started'.tr
                                  : 'next'.tr,
                              onPressed: () {
                                if (onBoardingController.selectedIndex != 2) {
                                  _pageController.nextPage(
                                    duration: const Duration(milliseconds: 500),
                                    curve: Curves.easeInOut,
                                  );
                                } else {
                                  _configureToRouteInitialPage();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                ),
              ),
      );
    });
  }

  void _configureToRouteInitialPage() async {
    Get.find<SplashController>().disableIntro();

    // Request notification permission after onboarding
    await NotificationHelper.requestPermission(flutterLocalNotificationsPlugin);

    await Get.find<AuthController>().guestLogin();
    if (AddressHelper.getAddressFromSharedPref() != null) {
      Get.offNamed(RouteHelper.getInitialRoute(fromSplash: true));
    } else {
      Get.find<SplashController>().navigateToLocationScreen('splash', offNamed: true);
    }
  }
}
