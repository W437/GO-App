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

/// Centralized navigation orchestrator
///
/// Handles all app-level navigation logic separately from data fetching.
/// This class is responsible ONLY for navigation decisions, not data loading.
///
/// Following the Single Responsibility Principle:
/// - ✅ Decide where to navigate based on app state
/// - ✅ Handle different navigation scenarios (launch, notification, deep link)
/// - ❌ NO data fetching
/// - ❌ NO API calls
///
/// Benefits:
/// - Clear navigation intent (no hidden side effects)
/// - Easy to test navigation logic independently
/// - Reusable navigation strategies
/// - Maintainable and predictable
class AppNavigator {
  /// Navigate on app launch based on current app state
  ///
  /// This is called from SplashScreen after config data is loaded.
  /// It decides where to route the user based on:
  /// - App version (needs update?)
  /// - Maintenance mode
  /// - Notification payload
  /// - Deep link
  /// - User authentication state
  /// - First-time user (show onboarding)
  /// - Address availability
  static Future<void> navigateOnAppLaunch({
    NotificationBodyModel? notification,
    DeepLinkBody? linkBody,
  }) async {
    print('🚀 [APP_NAVIGATOR] navigateOnAppLaunch() called');

    // 1. Check for app update requirement
    double? minimumVersion = _getMinimumVersion();
    bool needsUpdate = AppConstants.appVersion < minimumVersion;

    if (needsUpdate) {
      print('🚀 [APP_NAVIGATOR] Navigating to update screen (app update required)');
      Get.offNamed(RouteHelper.getUpdateRoute(true));
      return;
    }

    // 2. Check for maintenance mode
    bool isInMaintenance = MaintenanceHelper.isMaintenanceEnable();
    if (isInMaintenance) {
      print('🚀 [APP_NAVIGATOR] Navigating to maintenance screen');
      Get.offNamed(RouteHelper.getUpdateRoute(false));
      return;
    }

    // 3. Web-specific routing
    if (GetPlatform.isWeb) {
      if (Get.currentRoute.contains(RouteHelper.update) && !isInMaintenance) {
        print('🚀 [APP_NAVIGATOR] Web: Navigating from update screen to initial');
        Get.offNamed(RouteHelper.getInitialRoute());
      }
      return;
    }

    // 4. Mobile navigation flow
    print('🚀 [APP_NAVIGATOR] Starting mobile navigation flow');
    _handleMobileNavigation(notification, linkBody);
  }

  /// Handle navigation specifically for mobile platforms
  static void _handleMobileNavigation(
    NotificationBodyModel? notificationBody,
    DeepLinkBody? linkBody,
  ) {
    print('🚀 [NAVIGATION] _handleMobileNavigation started');

    // Priority 1: Notification
    if (notificationBody != null && linkBody == null) {
      print('🚀 [NAVIGATION] Route: notification');
      _navigateFromNotification(notificationBody);
      return;
    }

    // Priority 2: Deep link (if implemented)
    if (linkBody != null) {
      print('🚀 [NAVIGATION] Route: deep link');
      _navigateFromDeepLink(linkBody);
      return;
    }

    // Priority 3: Logged-in user
    if (Get.find<AuthController>().isLoggedIn()) {
      print('🚀 [NAVIGATION] Route: logged in user');
      _navigateLoggedInUser();
      return;
    }

    // Priority 4: First-time user (show onboarding)
    if (Get.find<SplashController>().showIntro()!) {
      print('🚀 [NAVIGATION] Route: first time user (onboarding)');
      _navigateNewUser();
      return;
    }

    // Priority 5: Guest user (already logged in)
    if (Get.find<AuthController>().isGuestLoggedIn()) {
      print('🚀 [NAVIGATION] Route: guest user (already logged in)');
      _navigateGuestUser();
      return;
    }

    // Priority 6: New guest user (login then navigate)
    print('🚀 [NAVIGATION] Route: new guest user (logging in)');
    Get.find<AuthController>().guestLogin().then((_) {
      _navigateGuestUser();
    });
  }

  /// Navigate for logged-in user
  static Future<void> _navigateLoggedInUser() async {
    print('🚀 [NAVIGATION] Setting up logged-in user');

    Get.find<AuthController>().updateToken();

    // Fire and forget - don't block navigation for favourites
    Get.find<FavouriteController>().getFavouriteList();

    // Pre-load zones for instant display when user clicks location
    Get.find<LocationController>().getZoneList();

    if (AddressHelper.getAddressFromSharedPref() != null) {
      print('🚀 [NAVIGATION] User has address → home screen');
      Get.offNamed(RouteHelper.getInitialRoute(fromSplash: true));
    } else {
      print('🚀 [NAVIGATION] User needs address → location screen');
      Get.offNamed(RouteHelper.getAccessLocationRoute('splash'));
    }
  }

  /// Navigate for guest user
  static void _navigateGuestUser() {
    print('🚀 [NAVIGATION] Setting up guest user');

    if (AddressHelper.getAddressFromSharedPref() != null) {
      print('🚀 [NAVIGATION] Guest has address → home screen');
      Get.offNamed(RouteHelper.getInitialRoute(fromSplash: true));
    } else {
      print('🚀 [NAVIGATION] Guest needs address → location screen');
      Get.find<SplashController>().navigateToLocationScreen('splash', offNamed: true);
    }
  }

  /// Navigate for first-time user (onboarding)
  static void _navigateNewUser() {
    print('🚀 [NAVIGATION] Showing onboarding for new user');
    // Use unified onboarding that includes language selection
    Get.offNamed(RouteHelper.getUnifiedOnboardingRoute());
  }

  /// Handle notification-based navigation
  static void _navigateFromNotification(NotificationBodyModel notification) {
    print('🚀 [NAVIGATION] Navigating based on notification type: ${notification.notificationType}');

    switch (notification.notificationType) {
      case NotificationType.order:
        Get.toNamed(RouteHelper.getOrderDetailsRoute(
          notification.orderId,
          fromNotification: true,
        ));
        break;

      case NotificationType.message:
        Get.toNamed(RouteHelper.getChatRoute(
          notificationBody: notification,
          conversationID: notification.conversationId,
          fromNotification: true,
        ));
        break;

      case NotificationType.block:
      case NotificationType.unblock:
        Get.toNamed(RouteHelper.getSignInRoute(RouteHelper.notification));
        break;

      case NotificationType.add_fund:
      case NotificationType.referral_earn:
      case NotificationType.CashBack:
        Get.toNamed(RouteHelper.getWalletRoute(fromNotification: true));
        break;

      default:
        Get.toNamed(RouteHelper.getNotificationRoute(fromNotification: true));
    }
  }

  /// Handle deep link navigation
  static void _navigateFromDeepLink(DeepLinkBody deepLink) {
    print('🚀 [NAVIGATION] Navigating based on deep link');
    // Deep link navigation logic
    // (Implement based on your deep link structure)
  }

  /// Navigate when maintenance mode is enabled
  ///
  /// This is called when a maintenance notification is received
  /// while the app is running.
  static void navigateToMaintenance() {
    print('🚀 [NAVIGATION] Navigating to maintenance mode');
    if (Get.currentRoute != RouteHelper.update) {
      Get.offNamed(RouteHelper.getUpdateRoute(false));
    }
  }

  /// Navigate when app update is required
  ///
  /// This is called when the app detects it's below minimum version
  /// while running.
  static void navigateToUpdate() {
    print('🚀 [NAVIGATION] Navigating to update screen');
    if (Get.currentRoute != RouteHelper.update) {
      Get.offNamed(RouteHelper.getUpdateRoute(true));
    }
  }

  /// Get minimum required app version based on platform
  static double _getMinimumVersion() {
    if (GetPlatform.isAndroid) {
      return Get.find<SplashController>().configModel?.appMinimumVersionAndroid ?? 0;
    } else if (GetPlatform.isIOS) {
      return Get.find<SplashController>().configModel?.appMinimumVersionIos ?? 0;
    } else {
      return 0;
    }
  }
}
