
import 'package:get/get.dart';
import 'package:godelivery_user/features/auth/controllers/auth_controller.dart';
import 'package:godelivery_user/features/favourite/controllers/favourite_controller.dart';
import 'package:godelivery_user/features/location/controllers/location_controller.dart';
import 'package:godelivery_user/features/notification/domain/models/notification_body_model.dart';
import 'package:godelivery_user/features/splash/controllers/splash_controller.dart';
import 'package:godelivery_user/features/splash/domain/models/deep_link_body.dart';
import 'package:godelivery_user/helper/business_logic/address_helper.dart';
import 'package:godelivery_user/helper/utilities/maintance_helper.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:godelivery_user/util/app_constants.dart';

void route({required NotificationBodyModel? notificationBody, required DeepLinkBody? linkBody}) {
  print('🚀 [ROUTE] route() called - starting navigation logic');
  double? minimumVersion = _getMinimumVersion();
  bool needsUpdate = AppConstants.appVersion < minimumVersion;

  bool isInMaintenance = MaintenanceHelper.isMaintenanceEnable();
  if (needsUpdate || isInMaintenance) {
    print('🚀 [ROUTE] Navigating to update/maintenance screen');
    Get.offNamed(RouteHelper.getUpdateRoute(needsUpdate));
  } else if(!GetPlatform.isWeb){
    print('🚀 [ROUTE] Calling _handleNavigation for mobile');
    _handleNavigation(notificationBody, linkBody);
  } else if (GetPlatform.isWeb && Get.currentRoute.contains(RouteHelper.update) && !isInMaintenance) {
    print('🚀 [ROUTE] Navigating to initial route for web');
    Get.offNamed(RouteHelper.getInitialRoute());
  }
  print('🚀 [ROUTE] route() completed');
}

double _getMinimumVersion() {
  if (GetPlatform.isAndroid) {
    return Get.find<SplashController>().configModel!.appMinimumVersionAndroid!;
  } else if (GetPlatform.isIOS) {
    return Get.find<SplashController>().configModel!.appMinimumVersionIos!;
  } else {
    return 0;
  }
}

void _handleNavigation(NotificationBodyModel? notificationBody, DeepLinkBody? linkBody) async {
  print('🚀 [NAVIGATION] _handleNavigation started');
  if (notificationBody != null && linkBody == null) {
    print('🚀 [NAVIGATION] Route: notification');
    _forNotificationRouteProcess(notificationBody);
  } else if (Get.find<AuthController>().isLoggedIn()) {
    print('🚀 [NAVIGATION] Route: logged in user');
    _forLoggedInUserRouteProcess();
  } else if (Get.find<SplashController>().showIntro()!) {
    print('🚀 [NAVIGATION] Route: first time user (onboarding)');
    _newlyRegisteredRouteProcess();
  } else if (Get.find<AuthController>().isGuestLoggedIn()) {
    print('🚀 [NAVIGATION] Route: guest user (already logged in)');
    _forGuestUserRouteProcess();
  } else {
    print('🚀 [NAVIGATION] Route: new guest user (logging in)');
    await Get.find<AuthController>().guestLogin();
    _forGuestUserRouteProcess();
  }
  print('🚀 [NAVIGATION] _handleNavigation completed');
}

void _forNotificationRouteProcess(NotificationBodyModel? notificationBody) {
  if(notificationBody!.notificationType == NotificationType.order) {
    Get.toNamed(RouteHelper.getOrderDetailsRoute(notificationBody.orderId, fromNotification: true));
  }else if(notificationBody.notificationType == NotificationType.message) {
    Get.toNamed(RouteHelper.getChatRoute(notificationBody: notificationBody, conversationID: notificationBody.conversationId, fromNotification: true));
  }else if(notificationBody.notificationType == NotificationType.block || notificationBody.notificationType == NotificationType.unblock){
    Get.toNamed(RouteHelper.getSignInRoute(RouteHelper.notification));
  }else if(notificationBody.notificationType == NotificationType.add_fund || notificationBody.notificationType == NotificationType.referral_earn || notificationBody.notificationType == NotificationType.CashBack){
    Get.toNamed(RouteHelper.getWalletRoute(fromNotification: true));
  }else{
    Get.toNamed(RouteHelper.getNotificationRoute(fromNotification: true));
  }
}

Future<void> _forLoggedInUserRouteProcess() async {
  Get.find<AuthController>().updateToken();
  await Get.find<FavouriteController>().getFavouriteList();
  // Pre-load zones for instant display when user clicks location
  Get.find<LocationController>().getZoneList();
  if (AddressHelper.getAddressFromSharedPref() != null) {
    Get.offNamed(RouteHelper.getInitialRoute(fromSplash: true ));
  } else {
    Get.offNamed(RouteHelper.getAccessLocationRoute('splash'));
  }
}

void _newlyRegisteredRouteProcess() {
  // Use unified onboarding that includes language selection
  Get.offNamed(RouteHelper.getUnifiedOnboardingRoute());
}

void _forGuestUserRouteProcess() {
  if (AddressHelper.getAddressFromSharedPref() != null) {
    Get.offNamed(RouteHelper.getInitialRoute(fromSplash: true));
  } else {
    Get.find<SplashController>().navigateToLocationScreen('splash', offNamed: true);
  }
}