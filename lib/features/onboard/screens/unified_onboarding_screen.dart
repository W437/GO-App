import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/common/widgets/custom_asset_image_widget.dart';
import 'package:godelivery_user/common/widgets/custom_button_widget.dart';
import 'package:godelivery_user/common/widgets/custom_snackbar_widget.dart';
import 'package:godelivery_user/features/auth/controllers/auth_controller.dart';
import 'package:godelivery_user/features/language/controllers/localization_controller.dart';
import 'package:godelivery_user/features/language/widgets/language_card_widget.dart';
import 'package:godelivery_user/features/onboard/controllers/onboard_controller.dart';
import 'package:godelivery_user/features/splash/controllers/splash_controller.dart';
import 'package:godelivery_user/helper/address_helper.dart';
import 'package:godelivery_user/helper/notification_helper.dart';
import 'package:godelivery_user/helper/route_helper.dart';
import 'package:godelivery_user/main.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/images.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:lottie/lottie.dart';

class UnifiedOnboardingScreen extends StatefulWidget {
  const UnifiedOnboardingScreen({super.key});

  @override
  State<UnifiedOnboardingScreen> createState() => _UnifiedOnboardingScreenState();
}

class _UnifiedOnboardingScreenState extends State<UnifiedOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    Get.find<OnBoardingController>().getOnBoardingList();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _finishOnboarding() async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).cardColor,
      body: Stack(
        children: [
          // PageView - takes full screen
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            children: [
              // Page 0: Language Selection
              SafeArea(child: _buildLanguagePage()),

              // Page 1: Welcome - Fullscreen without SafeArea
              _buildWelcomePage(),

              // Pages 2-4: Onboarding steps
              ...List.generate(3, (index) => SafeArea(child: _buildOnboardingPage(index))),
            ],
          ),

          // Overlays (skip button, indicators, next button) - only show if not on welcome page
          if (_currentPage != 1)
            SafeArea(
              child: Column(
                children: [
                  // Skip button
                  if (_currentPage < 4)
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                        child: TextButton(
                          onPressed: () => _pageController.jumpToPage(4),
                          child: Text(
                            'skip'.tr,
                            style: robotoMedium.copyWith(
                              color: Theme.of(context).primaryColor,
                              fontSize: Dimensions.fontSizeDefault,
                            ),
                          ),
                        ),
                      ),
                    ),

                  const Spacer(),

                  // Page indicators
                  Padding(
                    padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        5,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: index == _currentPage ? 32 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: index == _currentPage
                                ? Theme.of(context).primaryColor
                                : Theme.of(context).disabledColor.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Next button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Dimensions.paddingSizeExtraLarge,
                      0,
                      Dimensions.paddingSizeExtraLarge,
                      Dimensions.paddingSizeDefault,
                    ),
                    child: GetBuilder<LocalizationController>(
                      builder: (localizationController) {
                        return CustomButtonWidget(
                          buttonText: _currentPage == 4 ? 'get_started'.tr : 'next'.tr,
                          onPressed: () {
                            // Validate language selection on first page
                            if (_currentPage == 0) {
                              if (localizationController.selectedLanguageIndex == -1) {
                                showCustomSnackBar('select_a_language'.tr);
                                return;
                              }
                            }
                            _nextPage();
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

          // For welcome page, show only indicators and next button at bottom with SafeArea
          if (_currentPage == 1)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Page indicators
                    Padding(
                      padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          5,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: index == _currentPage ? 32 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: index == _currentPage
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Next button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        Dimensions.paddingSizeExtraLarge,
                        0,
                        Dimensions.paddingSizeExtraLarge,
                        Dimensions.paddingSizeDefault,
                      ),
                      child: CustomButtonWidget(
                        buttonText: 'next'.tr,
                        onPressed: _nextPage,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Language Selection Page
  Widget _buildLanguagePage() {
    return GetBuilder<LocalizationController>(
      builder: (localizationController) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Lottie animation
                Lottie.asset(
                  'assets/animations/language_screen_lottie.json',
                  height: 200,
                  width: 200,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: Dimensions.paddingSizeLarge),

                // Title
                Text(
                  'choose_your_language'.tr,
                  style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                // Subtitle
                Text(
                  'choose_your_language_to_proceed'.tr,
                  style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraLarge),

                // Language cards
                ListView.builder(
                  itemCount: localizationController.languages.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
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
                Text(
                  'you_can_change_this_later'.tr,
                  style: robotoRegular.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    color: Theme.of(context).hintColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Welcome Page
  Widget _buildWelcomePage() {
    return Stack(
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

        // Content - centered above pagination
        Positioned(
          bottom: 150, // Above the pagination and button
          left: 0,
          right: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Welcome title
                Text(
                  'welcome_title'.tr,
                  style: robotoBold.copyWith(
                    fontSize: 36,
                    color: Theme.of(context).primaryColor,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
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
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Onboarding Step Page
  Widget _buildOnboardingPage(int index) {
    return GetBuilder<OnBoardingController>(
      builder: (onBoardingController) {
        if (onBoardingController.onBoardingList == null) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
            ),
          );
        }

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
    );
  }
}
