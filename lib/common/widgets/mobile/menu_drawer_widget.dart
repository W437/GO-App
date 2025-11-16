// Menu drawer widget for mobile navigation sidebar
// Provides navigation menu with user profile, settings, and app links

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/common/widgets/adaptive/dialogs/confirmation_dialog_widget.dart';
import 'package:godelivery_user/common/widgets/shared/feedback/custom_snackbar_widget.dart';
import 'package:godelivery_user/common/widgets/web/hover/on_hover_widget.dart';
import 'package:godelivery_user/features/auth/controllers/auth_controller.dart';
import 'package:godelivery_user/features/auth/widgets/auth_dialog_widget.dart';
import 'package:godelivery_user/features/cart/controllers/cart_controller.dart';
import 'package:godelivery_user/features/favourite/controllers/favourite_controller.dart';
import 'package:godelivery_user/features/profile/controllers/profile_controller.dart';
import 'package:godelivery_user/features/splash/controllers/splash_controller.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:godelivery_user/helper/ui/responsive_helper.dart';
import 'package:godelivery_user/story_creator/config/story_creator_config.dart';
import 'package:godelivery_user/story_creator/story_creator_flow.dart';
import 'package:godelivery_user/util/app_constants.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/images.dart';
import 'package:godelivery_user/util/styles.dart';

class MenuDrawerWidget extends StatefulWidget {
  const MenuDrawerWidget({super.key, this.forceShow = false});

  final bool forceShow;

  @override
  MenuDrawerWidgetState createState() => MenuDrawerWidgetState();
}

class MenuDrawerWidgetState extends State<MenuDrawerWidget> with SingleTickerProviderStateMixin {
  late final List<Menu> _menuList;

  static const _initialDelayTime = Duration(milliseconds: 200);
  static const _itemSlideTime = Duration(milliseconds: 250);
  static const _staggerTime = Duration(milliseconds: 50);
  static const _buttonDelayTime = Duration(milliseconds: 150);
  static const _buttonTime = Duration(milliseconds: 500);
  final _animationDuration = _initialDelayTime + (_staggerTime * 7) + _buttonDelayTime + _buttonTime;

  late AnimationController _staggeredController;
  final List<Interval> _itemSlideIntervals = [];

  @override
  void initState() {
    super.initState();

    _menuList = [
      Menu(icon: Images.storyCreator, title: 'create_story'.tr, onTap: _openStoryCreator),
      Menu(icon: Images.profileIcon, title: 'profile'.tr, onTap: () {
        Get.offNamed(RouteHelper.getProfileRoute());
      }),
      Menu(icon: Images.orderMenuIcon, title: 'my_orders'.tr, onTap: () {
        Get.offNamed(RouteHelper.getOrderRoute());
      }),
      Menu(icon: Images.location, title: 'my_address'.tr, onTap: () {
        Get.offNamed(RouteHelper.getAddressRoute());
      }),
      Menu(icon: Images.language, title: 'language'.tr, onTap: () {
        Get.offNamed(RouteHelper.getLanguageRoute('menu'));
      }),
      Menu(icon: Images.coupon, title: 'coupon'.tr, onTap: () {
        Get.offNamed(RouteHelper.getCouponRoute(fromCheckout: false));
      }),
      Menu(icon: Images.support, title: 'help_support'.tr, onTap: () {
        Get.offNamed(RouteHelper.getSupportRoute());
      }),
      Menu(icon: Images.chat, title: 'live_chat'.tr, onTap: () {
        Get.offNamed(RouteHelper.getConversationRoute());
      }),
    ];

    if(Get.find<SplashController>().configModel!.refundPolicyStatus == 1) {
      _menuList.add(Menu(icon: Images.refund, title: 'refund_policy'.tr, onTap: () {
        Get.offNamed(RouteHelper.getHtmlRoute('refund-policy'));
      }));
    }
    if(Get.find<SplashController>().configModel!.cancellationPolicyStatus == 1) {
      _menuList.add(Menu(icon: Images.cancellation, title: 'cancellation_policy'.tr, onTap: () {
        Get.offNamed(RouteHelper.getHtmlRoute('cancellation-policy'));
      }));
    }
    if(Get.find<SplashController>().configModel!.shippingPolicyStatus == 1) {
      _menuList.add(Menu(icon: Images.shippingPolicy, title: 'shipping_policy'.tr, onTap: () {
        Get.offNamed(RouteHelper.getHtmlRoute('shipping-policy'));
      }));
    }

    if(Get.find<SplashController>().configModel!.customerWalletStatus == 1) {
      _menuList.add(Menu(icon: Images.wallet, title: 'wallet'.tr, onTap: () {
        Get.offNamed(RouteHelper.getWalletRoute());
      }));
    }

    if(Get.find<SplashController>().configModel!.loyaltyPointStatus == 1) {
      _menuList.add(Menu(icon: Images.loyal, title: 'loyalty_points'.tr, onTap: () {
        Get.offNamed(RouteHelper.getLoyaltyRoute());
      }));
    }
    if(Get.find<SplashController>().configModel!.refEarningStatus == 1) {
      _menuList.add(Menu(icon: Images.referCode, title: 'refer_and_earn'.tr, onTap: () {
        Get.offNamed(RouteHelper.getReferAndEarnRoute());
      }));
    }
    if(Get.find<SplashController>().configModel!.toggleDmRegistration!) {
      _menuList.add(Menu(
        icon: Images.deliveryManJoin, title: 'join_as_a_delivery_man'.tr,onTap: (){
          Get.toNamed(RouteHelper.getDeliverymanRegistrationRoute());
      }));
    }
    if(Get.find<SplashController>().configModel!.toggleRestaurantRegistration!) {
      _menuList.add(Menu(
        icon: Images.restaurantJoin, title: 'join_as_a_restaurant'.tr,
        onTap: () => Get.toNamed(RouteHelper.getRestaurantRegistrationRoute()),
      ));
    }
    _menuList.add(Menu(icon: Images.logOut, title: Get.find<AuthController>().isLoggedIn() ? 'logout'.tr : 'sign_in'.tr, onTap: () {
      Get.back();
      if(Get.find<AuthController>().isLoggedIn()) {
        Get.dialog(ConfirmationDialogWidget(icon: Images.support, description: 'are_you_sure_to_logout'.tr, isLogOut: true, onYesPressed: () {
          Get.find<AuthController>().resetOtpView();
          Get.find<AuthController>().clearSharedData();
          Get.find<CartController>().clearCartList();
          Get.find<AuthController>().socialLogout();
          Get.find<FavouriteController>().removeFavourites();
          if(ResponsiveHelper.isDesktop(Get.context)) {
            Get.offAllNamed(RouteHelper.getInitialRoute());
          }else{
            Get.offAllNamed(RouteHelper.getSignInRoute(RouteHelper.splash));
          }
        }), useSafeArea: false);
      }else {
        Get.find<FavouriteController>().removeFavourites();
        if(ResponsiveHelper.isDesktop(context)){
          Get.dialog(const Center(child: AuthDialogWidget(exitFromApp: false, backFromThis: false)), barrierDismissible: false,);
        }else{
          Get.toNamed(RouteHelper.getSignInRoute(RouteHelper.main));
        }
      }
    }));

    _createAnimationIntervals();

    _staggeredController = AnimationController(
      vsync: this,
      duration: _animationDuration,
    )..forward();
  }

  void _createAnimationIntervals() {
    for (var i = 0; i < _menuList.length; ++i) {
      final startTime = _initialDelayTime + (_staggerTime * i);
      final endTime = startTime + _itemSlideTime;
      _itemSlideIntervals.add(
        Interval(
          startTime.inMilliseconds / _animationDuration.inMilliseconds,
          endTime.inMilliseconds / _animationDuration.inMilliseconds,
        ),
      );
    }
  }

  void _openStoryCreator() {
    final authController = Get.find<AuthController>();
    if (!authController.isLoggedIn()) {
      Get.back();
      showCustomSnackBar('please_login_to_continue'.tr);
      return;
    }

    final profileController = Get.find<ProfileController>();
    final userId = profileController.userInfoModel?.id?.toString();
    if (userId == null) {
      profileController.getUserInfo();
      Get.back();
      showCustomSnackBar('profile_loading_try_again'.tr);
      return;
    }

    final config = StoryCreatorConfig(
      authToken: authController.getUserToken(),
      userId: userId,
      baseApiUrl: AppConstants.baseUrl,
      mediaUploadPath: '/api/v1/stories/upload',
      storyCreatePath: '/api/v1/stories',
    );

    Get.back();
    Get.to(() => StoryCreatorFlow(config: config), fullscreenDialog: true);
  }

  @override
  void dispose() {
    _staggeredController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.forceShow) {
      return _buildContent();
    }
    return ResponsiveHelper.isDesktop(context) ? _buildContent() : const SizedBox();
  }

  Widget _buildContent() {
    return Align(alignment: Alignment.topRight, child: Container(
      width: 300,
      decoration: BoxDecoration(color: Theme.of(context).cardColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeLarge, horizontal: 25),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.10),
            ),
            alignment: Alignment.centerLeft,
            child: Row( mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('menu'.tr, style: robotoBold.copyWith(fontSize: 20 )),
                IconButton( padding: const EdgeInsets.all(0), onPressed: () => Get.back(), icon: const Icon(Icons.close))
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
              itemCount: _menuList.length,
              physics: const AlwaysScrollableScrollPhysics(),
              shrinkWrap: true,
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              itemBuilder: (context, index) {
                return AnimatedBuilder(
                  animation: _staggeredController,
                  builder: (context, child) {
                    final animationPercent = Curves.easeOut.transform(
                      _itemSlideIntervals[index].transform(_staggeredController.value),
                    );
                    final opacity = animationPercent;
                    final slideDistance = (1.0 - animationPercent) * 150;

                    return Opacity(
                      opacity: opacity,
                      child: Transform.translate(
                        offset: Offset(slideDistance, 0),
                        child: child,
                      ),
                    );
                  },
                  child: OnHoverWidget(
                    isItem: true,
                    fromMenu: true,
                    child: InkWell(
                      onTap: _menuList[index].onTap as void Function()?,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeExtraSmall),
                        child: Row(children: [
                          Container(
                            height: 55, width: 55, alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                              color: index != _menuList.length-1 ? Theme.of(context).primaryColor : Get.find<AuthController>().isLoggedIn() ? Theme.of(context).colorScheme.error : Colors.green,
                            ),
                            child: Image.asset(_menuList[index].icon, color: Colors.white, height: 30, width: 30),
                          ),
                          const SizedBox(width: Dimensions.paddingSizeSmall),

                          Expanded(child: Text(_menuList[index].title, style: robotoMedium, overflow: TextOverflow.ellipsis, maxLines: 1)),

                        ]),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

        ],
      ),
    ));
  }
}

class Menu {
  String icon;
  String title;
  Function onTap;

  Menu({required this.icon, required this.title, required this.onTap});
}
