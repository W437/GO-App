import 'package:godelivery_user/common/widgets/bouncy_bottom_sheet.dart';
import 'package:godelivery_user/common/widgets/custom_asset_image_widget.dart';
import 'package:godelivery_user/features/auth/controllers/auth_controller.dart';
import 'package:godelivery_user/features/cart/controllers/cart_controller.dart';
import 'package:godelivery_user/features/language/controllers/localization_controller.dart';
import 'package:godelivery_user/features/language/widgets/language_bottom_sheet_widget.dart';
import 'package:godelivery_user/features/menu/widgets/ios_menu_item_widget.dart';
import 'package:godelivery_user/features/profile/controllers/profile_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:godelivery_user/features/profile/widgets/guest_login_bottom_sheet.dart';
import 'package:godelivery_user/features/splash/controllers/splash_controller.dart';
import 'package:godelivery_user/features/splash/controllers/theme_controller.dart';
import 'package:godelivery_user/features/auth/screens/sign_in_screen.dart';
import 'package:godelivery_user/features/favourite/controllers/favourite_controller.dart';
import 'package:godelivery_user/helper/business_logic/auth_helper.dart';
import 'package:godelivery_user/helper/converters/date_converter.dart';
import 'package:godelivery_user/helper/converters/price_converter.dart';
import 'package:godelivery_user/helper/ui/responsive_helper.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:godelivery_user/util/app_constants.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/images.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:godelivery_user/features/developer/controllers/developer_catalog_controller.dart';
import 'package:godelivery_user/common/widgets/confirmation_dialog_widget.dart';
import 'package:godelivery_user/common/widgets/emoji_profile_picture.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:screen_corner_radius/screen_corner_radius.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  BorderRadius? _headerRadius;
  EdgeInsets? _headerPadding;

  @override
  void initState() {
    super.initState();
    _initializeHeaderRadius();
  }

  /// Fetches device screen corner radii and calculates appropriate header radius
  ///
  /// This method attempts to get the real physical corner radius from the device.
  /// - On Android 12+: Returns actual device corner radii
  /// - On iOS: May be restricted/unavailable due to privacy
  /// - Fallback: If API fails, returns null and removes top/side margins for clean full-width layout
  ///
  /// The calculated radius accounts for any margins applied to the header container.
  Future<void> _initializeHeaderRadius() async {
    try {
      // Attempt to fetch real device corner radii
      print('📱 [Header] Fetching screen corner radii...');
      final radii = await ScreenCornerRadius.get();
      print('📱 [Header] API returned: $radii');

      if (radii != null && mounted) {
        // Successfully got device radii - apply with formula: outerRadius - gap = innerRadius
        const margin = Dimensions.paddingSizeExtraSmall; // 5px margin
        const gap = 2.0; // Smaller gap value for more rounding
        final innerRadiusTopLeft = radii.topLeft - gap;
        final innerRadiusTopRight = radii.topRight - gap;

        print('📱 [Header] ✅ SUCCESS - Device radii found:');
        print('   • Outer radius (device): ${radii.topLeft}px');
        print('   • Margin: ${margin}px');
        print('   • Gap (for radius calc): ${gap}px');
        print('   • Inner radius (calculated): ${innerRadiusTopLeft}px');
        print('   • Formula: outerRadius - gap = innerRadius');
        print('   • Result: ${radii.topLeft}px - ${gap}px = ${innerRadiusTopLeft}px');

        setState(() {
          _headerRadius = BorderRadius.only(
            topLeft: Radius.circular(innerRadiusTopLeft),
            topRight: Radius.circular(innerRadiusTopRight),
            bottomLeft: const Radius.circular(Dimensions.radiusExtraLarge),
            bottomRight: const Radius.circular(Dimensions.radiusExtraLarge),
          );
          _headerPadding = const EdgeInsets.only(
            top: margin,
            left: margin,
            right: margin,
          );
        });
        print('📱 [Header] Margins and rounded corners applied');
      } else if (mounted) {
        // API returned null - graceful fallback: no top rounding, no margins
        print('📱 [Header] ⚠️ FALLBACK - API returned null');
        print('   • No top rounding will be applied');
        print('   • No margins will be applied');
        setState(() {
          _headerRadius = const BorderRadius.only(
            bottomLeft: Radius.circular(Dimensions.radiusExtraLarge),
            bottomRight: Radius.circular(Dimensions.radiusExtraLarge),
          );
          _headerPadding = EdgeInsets.zero;
        });
      }
    } catch (e) {
      // API threw exception - graceful fallback: no top rounding, no margins
      print('📱 [Header] ❌ EXCEPTION - Screen corner radius detection failed: $e');
      print('   • Applying fallback: no top rounding, no margins');
      if (mounted) {
        setState(() {
          _headerRadius = const BorderRadius.only(
            bottomLeft: Radius.circular(Dimensions.radiusExtraLarge),
            bottomRight: Radius.circular(Dimensions.radiusExtraLarge),
          );
          _headerPadding = EdgeInsets.zero;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).cardColor,
      body: GetBuilder<ProfileController>(
        builder: (profileController) {
          final bool isLoggedIn = Get.find<AuthController>().isLoggedIn();

          // Show placeholder while radius is being calculated
          if (_headerRadius == null || _headerPadding == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(children: [

            Padding(
              padding: _headerPadding!,
              child: ClipRRect(
                borderRadius: _headerRadius!,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                  ),
                  child: Stack(
                  children: [
                    // Background logo
                    Positioned(
                      right: -40,
                      top: -40,
                      child: Opacity(
                        opacity: 0.15,
                        child: CustomAssetImageWidget(
                          Images.logo,
                          width: 180,
                          height: 180,
                          color: Colors.white,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    // Main content
                    Padding(
                      padding: EdgeInsets.only(
                        left: Dimensions.paddingSizeOverLarge,
                        right: Dimensions.paddingSizeOverLarge,
                        top: MediaQuery.of(context).padding.top + Dimensions.paddingSizeLarge,
                        bottom: Dimensions.paddingSizeOverLarge,
                      ),
                      child: Row(children: [

                      EmojiProfilePicture(
                        emoji: isLoggedIn ? profileController.userInfoModel?.profileEmoji : null,
                        bgColorHex: isLoggedIn ? profileController.userInfoModel?.profileBgColor : null,
                        size: 70,
                        borderWidth: 2,
                        borderColor: Theme.of(context).cardColor,
                      ),
                      const SizedBox(width: Dimensions.paddingSizeDefault),

                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      isLoggedIn && profileController.userInfoModel == null ? Shimmer(
                        duration: const Duration(seconds: 2),
                        enabled: true,
                        child: Container(
                          height: 16, width: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey[Get.find<ThemeController>().darkTheme ? 700 : 200],
                            borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                          ),
                        ),
                      ) : Text(
                        isLoggedIn ? '${profileController.userInfoModel?.fName} ${profileController.userInfoModel?.lName}' : 'guest_user'.tr,
                        style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: Theme.of(context).cardColor),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                      isLoggedIn && profileController.userInfoModel != null ? Text(
                        DateConverter.memberSinceFormat(profileController.userInfoModel!.createdAt!),
                        style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).cardColor),
                      ) : InkWell(
                        onTap: () async {
                          if(!ResponsiveHelper.isDesktop(context)) {
                            Get.toNamed(RouteHelper.getSignInRoute(Get.currentRoute))?.then((value) {
                              if(AuthHelper.isLoggedIn()) {
                                profileController.getUserInfo();
                              }
                            });
                          }else{
                            Get.dialog(const SignInScreen(exitFromApp: true, backFromThis: true)).then((value) {
                              if(AuthHelper.isLoggedIn()) {
                                profileController.getUserInfo();
                              }
                            });
                          }
                        },
                        child: Text(
                          'login_to_view_all_feature'.tr,
                          style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).cardColor),
                        ),
                      ) ,

                        ]),
                      ),

                      ]),
                    ),
                  ],
                ),
                ),
              ),
            ),

            Expanded(child: SingleChildScrollView(
              child: Ink(
                color: Get.find<ThemeController>().darkTheme ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 35),
                child: Column(children: [

                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 20, bottom: 8),
                      child: Text(
                        'general'.tr.toUpperCase(),
                        style: robotoMedium.copyWith(
                          fontSize: Dimensions.fontSizeExtraSmall,
                          color: const Color(0xFF6D6D72),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),

                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(children: [
                        IosMenuItemWidget(
                          icon: Icons.person_outline,
                          iconBackgroundColor: const Color(0xFF007AFF),
                          title: 'profile'.tr,
                          onTap: () {
                            if (AuthHelper.isLoggedIn()) {
                              Get.toNamed(RouteHelper.getProfileRoute());
                            } else {
                              showBouncyBottomSheet(
                                context: context,
                                builder: (context) => GuestLoginBottomSheet(
                                  onLoginSuccess: () {
                                    profileController.getUserInfo();
                                  },
                                ),
                              );
                            }
                          },
                        ),
                        IosMenuItemWidget(
                          icon: Icons.favorite_border,
                          iconBackgroundColor: const Color(0xFFFF3B30),
                          title: 'favourite'.tr,
                          onTap: () => Get.toNamed(RouteHelper.getFavouriteScreen()),
                        ),
                        IosMenuItemWidget(
                          icon: Icons.sports_esports,
                          iconBackgroundColor: const Color(0xFF34C759),
                          title: 'Hopa! Bird Game',
                          onTap: () => Get.toNamed(RouteHelper.getFlappyBirdGameScreen()),
                        ),
                        IosMenuItemWidget(
                          icon: Icons.location_on_outlined,
                          iconBackgroundColor: const Color(0xFF007AFF),
                          title: 'my_address'.tr,
                          onTap: () => Get.toNamed(RouteHelper.getAddressRoute()),
                        ),
                        IosMenuItemWidget(
                          icon: Icons.language_outlined,
                          iconBackgroundColor: const Color(0xFF8E8E93),
                          title: 'language'.tr,
                          onTap: () => _manageLanguageFunctionality(),
                        ),
                        IosMenuItemWidget(
                          icon: Icons.dark_mode_outlined,
                          iconBackgroundColor: const Color(0xFF8E8E93),
                          title: 'dark_mode'.tr,
                          showChevron: false,
                          hideSeparator: true,
                          trailing: CupertinoSwitch(
                            value: Get.isDarkMode,
                            onChanged: (bool value) {
                              Get.find<ThemeController>().toggleTheme();
                            },
                          ),
                        ),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 35),

                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 20, bottom: 8),
                      child: Text(
                        'promotional_activity'.tr.toUpperCase(),
                        style: robotoMedium.copyWith(
                          fontSize: Dimensions.fontSizeExtraSmall,
                          color: const Color(0xFF6D6D72),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),

                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(children: [
                        IosMenuItemWidget(
                          icon: Icons.local_offer_outlined,
                          iconBackgroundColor: const Color(0xFFFF9500),
                          title: 'coupon'.tr,
                          onTap: () => Get.toNamed(RouteHelper.getCouponRoute(fromCheckout: false)),
                          hideSeparator: Get.find<SplashController>().configModel!.loyaltyPointStatus != 1 && Get.find<SplashController>().configModel!.customerWalletStatus != 1,
                        ),

                        (Get.find<SplashController>().configModel!.loyaltyPointStatus == 1) ? IosMenuItemWidget(
                          icon: Icons.stars_outlined,
                          iconBackgroundColor: const Color(0xFFAF52DE),
                          title: 'loyalty_points'.tr,
                          badge: !isLoggedIn ? null : profileController.userInfoModel == null ? null : '${Get.find<ProfileController>().userInfoModel!.loyaltyPoint ?? 0}',
                          onTap: () => Get.toNamed(RouteHelper.getLoyaltyRoute()),
                          hideSeparator: Get.find<SplashController>().configModel!.customerWalletStatus != 1,
                        ) : const SizedBox(),

                        (Get.find<SplashController>().configModel!.customerWalletStatus == 1) ? IosMenuItemWidget(
                          icon: Icons.account_balance_wallet_outlined,
                          iconBackgroundColor: const Color(0xFF34C759),
                          title: 'my_wallet'.tr,
                          badge: !isLoggedIn ? null : profileController.userInfoModel == null ? null : PriceConverter.convertPrice(Get.find<ProfileController>().userInfoModel!.walletBalance ?? 0),
                          onTap: () => Get.toNamed(RouteHelper.getWalletRoute(fromMenuPage: true)),
                          hideSeparator: true,
                        ) : const SizedBox(),
                      ]),
                    )
                  ]),
                  const SizedBox(height: 35),

                  (Get.find<SplashController>().configModel!.refEarningStatus == 1)
                   || (Get.find<SplashController>().configModel!.toggleDmRegistration! && !ResponsiveHelper.isDesktop(context))
                   || (Get.find<SplashController>().configModel!.toggleRestaurantRegistration! && !ResponsiveHelper.isDesktop(context)) ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 20, bottom: 8),
                      child: Text(
                        'earnings'.tr.toUpperCase(),
                        style: robotoMedium.copyWith(
                          fontSize: Dimensions.fontSizeExtraSmall,
                          color: const Color(0xFF6D6D72),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),

                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(children: [

                        (Get.find<SplashController>().configModel!.refEarningStatus == 1 ) ? IosMenuItemWidget(
                          icon: Icons.card_giftcard_outlined,
                          iconBackgroundColor: const Color(0xFFFF2D55),
                          title: 'refer_and_earn'.tr,
                          onTap: () => Get.toNamed(RouteHelper.getReferAndEarnRoute()),
                          hideSeparator: Get.find<SplashController>().configModel!.toggleDmRegistration != true && Get.find<SplashController>().configModel!.toggleRestaurantRegistration != true,
                        ) : const SizedBox(),

                        (Get.find<SplashController>().configModel!.toggleDmRegistration! && !ResponsiveHelper.isDesktop(context)) ? IosMenuItemWidget(
                          icon: Icons.delivery_dining_outlined,
                          iconBackgroundColor: const Color(0xFF5AC8FA),
                          title: 'join_as_a_delivery_man'.tr,
                          onTap: () => Get.toNamed(RouteHelper.getDeliverymanRegistrationRoute()),
                          hideSeparator: Get.find<SplashController>().configModel!.toggleRestaurantRegistration != true,
                        ) : const SizedBox(),

                        (Get.find<SplashController>().configModel!.toggleRestaurantRegistration! && !ResponsiveHelper.isDesktop(context)) ? IosMenuItemWidget(
                          icon: Icons.store_outlined,
                          iconBackgroundColor: const Color(0xFFFF9500),
                          title: 'open_store'.tr,
                          onTap: () => Get.toNamed(RouteHelper.getRestaurantRegistrationRoute()),
                          hideSeparator: true,
                        ) : const SizedBox(),
                      ]),
                    ),
                    const SizedBox(height: 35),
                  ]) : const SizedBox(),

                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 20, bottom: 8),
                      child: Text(
                        'help_and_support'.tr.toUpperCase(),
                        style: robotoMedium.copyWith(
                          fontSize: Dimensions.fontSizeExtraSmall,
                          color: const Color(0xFF6D6D72),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),

                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(children: [
                        IosMenuItemWidget(
                          icon: Icons.chat_bubble_outline,
                          iconBackgroundColor: const Color(0xFF007AFF),
                          title: 'live_chat'.tr,
                          onTap: () => Get.toNamed(RouteHelper.getConversationRoute()),
                        ),
                        IosMenuItemWidget(
                          icon: Icons.help_outline,
                          iconBackgroundColor: const Color(0xFFFF9500),
                          title: 'help_and_support'.tr,
                          onTap: () => Get.toNamed(RouteHelper.getSupportRoute()),
                        ),
                        IosMenuItemWidget(
                          icon: Icons.info_outline,
                          iconBackgroundColor: const Color(0xFF8E8E93),
                          title: 'about_us'.tr,
                          onTap: () => Get.toNamed(RouteHelper.getHtmlRoute('about-us')),
                        ),
                        IosMenuItemWidget(
                          icon: Icons.description_outlined,
                          iconBackgroundColor: const Color(0xFF8E8E93),
                          title: 'terms_conditions'.tr,
                          onTap: () => Get.toNamed(RouteHelper.getHtmlRoute('terms-and-condition')),
                        ),
                        IosMenuItemWidget(
                          icon: Icons.privacy_tip_outlined,
                          iconBackgroundColor: const Color(0xFF8E8E93),
                          title: 'privacy_policy'.tr,
                          onTap: () => Get.toNamed(RouteHelper.getHtmlRoute('privacy-policy')),
                          hideSeparator: Get.find<SplashController>().configModel!.refundPolicyStatus != 1 &&
                                        Get.find<SplashController>().configModel!.cancellationPolicyStatus != 1 &&
                                        Get.find<SplashController>().configModel!.shippingPolicyStatus != 1,
                        ),

                        (Get.find<SplashController>().configModel!.refundPolicyStatus == 1 ) ? IosMenuItemWidget(
                          icon: Icons.replay_outlined,
                          iconBackgroundColor: const Color(0xFF8E8E93),
                          title: 'refund_policy'.tr,
                          onTap: () => Get.toNamed(RouteHelper.getHtmlRoute('refund-policy')),
                          hideSeparator: Get.find<SplashController>().configModel!.cancellationPolicyStatus != 1 &&
                                        Get.find<SplashController>().configModel!.shippingPolicyStatus != 1,
                        ) : const SizedBox(),

                        (Get.find<SplashController>().configModel!.cancellationPolicyStatus == 1 ) ? IosMenuItemWidget(
                          icon: Icons.cancel_outlined,
                          iconBackgroundColor: const Color(0xFF8E8E93),
                          title: 'cancellation_policy'.tr,
                          onTap: () => Get.toNamed(RouteHelper.getHtmlRoute('cancellation-policy')),
                          hideSeparator: Get.find<SplashController>().configModel!.shippingPolicyStatus != 1,
                        ) : const SizedBox(),

                        (Get.find<SplashController>().configModel!.shippingPolicyStatus == 1 ) ? IosMenuItemWidget(
                          icon: Icons.local_shipping_outlined,
                          iconBackgroundColor: const Color(0xFF8E8E93),
                          title: 'shipping_policy'.tr,
                          onTap: () => Get.toNamed(RouteHelper.getHtmlRoute('shipping-policy')),
                          hideSeparator: true,
                        ) : const SizedBox(),

                      ]),
                    )
                  ]),
                  const SizedBox(height: 35),

                  // Logout/Sign In Button
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IosMenuItemWidget(
                      icon: Get.find<AuthController>().isLoggedIn()
                          ? Icons.logout_outlined
                          : Icons.login_outlined,
                      iconBackgroundColor: const Color(0xFFFF3B30),
                      title: Get.find<AuthController>().isLoggedIn() ? 'logout'.tr : 'sign_in'.tr,
                      showChevron: false,
                      hideSeparator: true,
                      onTap: () async {
                        if(Get.find<AuthController>().isLoggedIn()) {
                          Get.dialog(ConfirmationDialogWidget(icon: Images.support, description: 'are_you_sure_to_logout'.tr, isLogOut: true, onYesPressed: () async {
                            Get.find<ProfileController>().setForceFullyUserEmpty();
                            Get.find<AuthController>().socialLogout();
                            Get.find<AuthController>().resetOtpView();
                            Get.find<CartController>().clearCartList();
                            Get.find<FavouriteController>().removeFavourites();
                            await Get.find<AuthController>().clearSharedData();
                            Get.offAllNamed(RouteHelper.getInitialRoute());
                          }), useSafeArea: false);
                        }else {
                          Get.find<FavouriteController>().removeFavourites();
                          await Get.toNamed(RouteHelper.getSignInRoute(Get.currentRoute));
                          if(AuthHelper.isLoggedIn()) {
                            await Get.find<FavouriteController>().getFavouriteList();
                            profileController.getUserInfo();
                          }
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Version display with secret gesture for developer mode
                  GestureDetector(
                    onTap: () {
                      // Initialize controller if not already done
                      if (!Get.isRegistered<DeveloperCatalogController>()) {
                        Get.put(DeveloperCatalogController());
                      }
                      Get.find<DeveloperCatalogController>().handleVersionTap();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
                      child: Text(
                        'v${AppConstants.appVersion}',
                        style: robotoRegular.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          color: const Color(0xFF6D6D72),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: Dimensions.paddingSizeOverLarge)

                ]),
              ),
            )),
          ]);
        }
      ),
    );
  }

  _manageLanguageFunctionality() {
    final localizationController = Get.find<LocalizationController>();
    localizationController.saveCacheLanguage(null);
    localizationController.searchSelectedLanguage();

    // Store current language before opening sheet
    final currentLocale = localizationController.locale;

    showModalBottomSheet(
      isScrollControlled: true, useRootNavigator: true, context: Get.context!,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(Dimensions.radiusExtraLarge), topRight: Radius.circular(Dimensions.radiusExtraLarge)),
      ),
      builder: (context) {
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
          child: const LanguageBottomSheetWidget(),
        );
      },
    ).then((value) {
      // Only call setLanguage if language actually changed
      final cachedLocale = localizationController.getCacheLocaleFromSharedPref();
      if (currentLocale.languageCode != cachedLocale.languageCode) {
        localizationController.setLanguage(cachedLocale);
      }
    });
  }
}
