import 'dart:ui';
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
import 'package:godelivery_user/helper/business_logic/address_helper.dart';
import 'package:godelivery_user/helper/utilities/notification_helper.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:godelivery_user/main.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/images.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:lottie/lottie.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

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

    await Get.find<AuthController>().guestLogin();

    // Send the user straight to the interactive map selector so they can
    // grant location permission and pick a zone immediately after onboarding.
    Get.offNamed(RouteHelper.getPickMapRoute(RouteHelper.accessLocation, false));
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

          // Overlays (indicators, next button) - shown for all pages
          SafeArea(
            child: Column(
              children: [
                const Spacer(),

                // Page indicators
                Padding(
                  padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
                  child: SmoothPageIndicator(
                    controller: _pageController,
                    count: 5,
                    effect: SwapEffect(
                      dotHeight: 8,
                      dotWidth: 8,
                      spacing: 8,
                      activeDotColor: Theme.of(context).primaryColor,
                      dotColor: Theme.of(context).disabledColor.withValues(alpha: 0.3),
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
            padding: const EdgeInsets.fromLTRB(
              Dimensions.paddingSizeLarge,
              Dimensions.paddingSizeLarge,
              Dimensions.paddingSizeLarge,
              120, // Bottom padding for overlay buttons
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Lottie animation
                Lottie.asset(
                  'assets/animations/language_screen_lottie.json',
                  height: 160,
                  width: 160,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: Dimensions.paddingSizeLarge),

                // Title
                Text(
                  'choose_your_language'.tr,
                  style: robotoBold.copyWith(fontSize: Dimensions.fontSizeOverLarge),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                // Subtitle
                Text(
                  'choose_your_language_to_proceed'.tr,
                  style: robotoRegular.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    color: Theme.of(context).hintColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraLarge),

                // Language vertical list
                ListView.builder(
                  itemCount: localizationController.languages.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index < localizationController.languages.length - 1 ? 12 : 0,
                      ),
                      child: LanguageCardWidget(
                        languageModel: localizationController.languages[index],
                        localizationController: localizationController,
                        index: index,
                      ),
                    );
                  },
                ),
                const SizedBox(height: Dimensions.paddingSizeDefault),

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
    return Column(
      children: [
        // Top section: Image with blur
        Expanded(
          flex: 6,
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

              // Smooth blur fade at bottom of image - using ShaderMask for gradual blur transition
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 350,
                child: ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: const [
                        Colors.transparent,
                        Colors.black,
                      ],
                      stops: const [0.0, 0.5],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.dstOut,
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        color: Colors.transparent,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Bottom section: White background with content only (no buttons/pagination)
        Expanded(
          flex: 4,
          child: Container(
            width: double.infinity,
            color: Theme.of(context).cardColor,
            padding: const EdgeInsets.fromLTRB(
              Dimensions.paddingSizeLarge,
              Dimensions.paddingSizeLarge,
              Dimensions.paddingSizeLarge,
              120, // Bottom padding for overlay buttons
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
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
                    color: Theme.of(context).textTheme.bodyLarge?.color,
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
              // Illustration - Placeholder
              Container(
                width: MediaQuery.of(context).size.width * 0.6,
                height: MediaQuery.of(context).size.height * 0.35,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.image_outlined,
                    size: 80,
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.4),
                  ),
                ),
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
