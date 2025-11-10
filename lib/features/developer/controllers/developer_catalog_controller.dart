import 'package:get/get.dart';
import 'package:godelivery_user/features/developer/data/catalog_data.dart';
import 'package:godelivery_user/features/developer/models/catalog_item_model.dart';
import 'package:godelivery_user/helper/route_helper.dart';
import 'package:godelivery_user/features/auth/controllers/auth_controller.dart';
import 'package:flutter/material.dart';

class DeveloperCatalogController extends GetxController {
  static DeveloperCatalogController get instance => Get.find();

  // State variables
  RxList<CatalogItemModel> displayedScreens = <CatalogItemModel>[].obs;
  RxList<CatalogItemModel> allScreens = <CatalogItemModel>[].obs;
  RxString searchQuery = ''.obs;
  RxString selectedModule = 'All'.obs;
  RxBool isGridView = true.obs;
  RxBool showAuthRequired = true.obs;
  RxBool showDataRequired = true.obs;
  RxBool developerModeEnabled = false.obs;

  // Tap counter for secret gesture
  int _tapCount = 0;
  DateTime? _lastTapTime;

  @override
  void onInit() {
    super.onInit();
    loadAllScreens();
  }

  void loadAllScreens() {
    allScreens.value = CatalogData.getAllScreens();
    filterScreens();
  }

  void filterScreens() {
    List<CatalogItemModel> filtered = allScreens;

    // Filter by module
    if (selectedModule.value != 'All') {
      filtered = filtered.where((screen) => screen.module == selectedModule.value).toList();
    }

    // Filter by search query
    if (searchQuery.value.isNotEmpty) {
      filtered = CatalogData.searchScreens(searchQuery.value);
    }

    // Filter by auth requirement
    if (!showAuthRequired.value) {
      filtered = filtered.where((screen) => !screen.requiresAuth).toList();
    }

    // Filter by data requirement
    if (!showDataRequired.value) {
      filtered = filtered.where((screen) => !screen.requiresData).toList();
    }

    displayedScreens.value = filtered;
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
    filterScreens();
  }

  void selectModule(String module) {
    selectedModule.value = module;
    filterScreens();
  }

  void toggleGridView() {
    isGridView.value = !isGridView.value;
  }

  void toggleAuthFilter() {
    showAuthRequired.value = !showAuthRequired.value;
    filterScreens();
  }

  void toggleDataFilter() {
    showDataRequired.value = !showDataRequired.value;
    filterScreens();
  }

  List<String> getModules() {
    return ['All', ...CatalogData.getAllModules()];
  }

  void navigateToScreen(CatalogItemModel screen) {
    // Set developer preview mode flag
    Get.put(DevPreviewModeController()).isPreviewMode = true;

    // For screens that require auth, temporarily enable auth if needed
    if (screen.requiresAuth && !Get.find<AuthController>().isLoggedIn()) {
      Get.find<AuthController>().setDeveloperPreviewMode(true);
    }

    // Navigate based on screen
    switch (screen.filePath) {
      // Address screens
      case 'lib/features/address/screens/add_address_screen.dart':
        Get.toNamed(RouteHelper.getAddAddressRoute(false, 0));
        break;
      case 'lib/features/address/screens/address_screen.dart':
        Get.toNamed(RouteHelper.getAddressRoute());
        break;

      // Auth screens
      case 'lib/features/auth/screens/sign_in_screen.dart':
        Get.toNamed(RouteHelper.getSignInRoute(RouteHelper.splash));
        break;
      case 'lib/features/auth/screens/sign_up_screen.dart':
        Get.toNamed(RouteHelper.getSignUpRoute());
        break;
      case 'lib/features/auth/screens/new_user_setup_screen.dart':
        Get.toNamed(RouteHelper.getNewUserSetupScreen(
          loginType: 'phone',
          phone: '+1234567890',
          email: 'test@example.com',
          name: 'Test User',
        ));
        break;
      case 'lib/features/auth/screens/delivery_man_registration_screen.dart':
        Get.toNamed(RouteHelper.deliveryManRegistration);
        break;
      case 'lib/features/auth/screens/restaurant_registration_screen.dart':
        Get.toNamed(RouteHelper.getRestaurantRegistrationRoute());
        break;

      // Cart screen
      case 'lib/features/cart/screens/cart_screen.dart':
        Get.toNamed(RouteHelper.getCartRoute());
        break;

      // Category screens
      case 'lib/features/category/screens/category_screen.dart':
        Get.toNamed(RouteHelper.getCategoryRoute());
        break;
      case 'lib/features/category/screens/category_product_screen.dart':
        Get.toNamed(RouteHelper.getCategoryProductRoute(1, 'Category'));
        break;

      // Chat screens
      case 'lib/features/chat/screens/conversation_screen.dart':
        Get.toNamed(RouteHelper.getConversationRoute());
        break;

      // Checkout screens
      case 'lib/features/checkout/screens/checkout_screen.dart':
        Get.toNamed(RouteHelper.getCheckoutRoute('cart'));
        break;
      case 'lib/features/checkout/screens/order_successful_screen.dart':
        Get.toNamed(RouteHelper.getOrderSuccessRoute('12345', 'success', 100.0, '1234567890'));
        break;

      // Coupon screen
      case 'lib/features/coupon/screens/coupon_screen.dart':
        Get.toNamed(RouteHelper.getCouponRoute(fromCheckout: false));
        break;

      // Dashboard screen
      case 'lib/features/dashboard/screens/dashboard_screen.dart':
        Get.toNamed(RouteHelper.getInitialRoute());
        break;

      // Explore screen
      case 'lib/features/explore/screens/explore_screen.dart':
        Get.toNamed(RouteHelper.getInitialRoute()); // Opens at index 0
        break;

      // Favourite screen
      case 'lib/features/favourite/screens/favourite_screen.dart':
        Get.toNamed(RouteHelper.favourite);
        break;

      // Home screens
      case 'lib/features/home/screens/home_screen.dart':
        Get.toNamed(RouteHelper.getInitialRoute()); // Opens at index 2
        break;

      // HTML viewer
      case 'lib/features/html/screens/html_viewer_screen.dart':
        Get.toNamed(RouteHelper.getHtmlRoute('privacy-policy'));
        break;

      // Language screen
      case 'lib/features/language/screens/language_screen.dart':
        Get.toNamed(RouteHelper.getLanguageRoute('menu'));
        break;

      // Location screens
      case 'lib/features/location/screens/access_location_screen.dart':
        Get.toNamed(RouteHelper.getAccessLocationRoute('splash'));
        break;
      case 'lib/features/location/screens/map_screen.dart':
        // Skip map screen - requires AddressModel
        Get.snackbar('Info', 'Map screen requires address data');
        break;

      // Loyalty screen
      case 'lib/features/loyalty/screens/loyalty_screen.dart':
        Get.toNamed(RouteHelper.getLoyaltyRoute());
        break;

      // Menu screen
      case 'lib/features/menu/screens/menu_screen.dart':
        Get.toNamed(RouteHelper.getInitialRoute()); // Opens at index 4
        break;

      // Notification screen
      case 'lib/features/notification/screens/notification_screen.dart':
        Get.toNamed(RouteHelper.getNotificationRoute());
        break;

      // Onboarding screens
      case 'lib/features/onboard/screens/onboarding_screen.dart':
        Get.toNamed(RouteHelper.getOnBoardingRoute());
        break;

      // Order screens
      case 'lib/features/order/screens/order_screen.dart':
        Get.toNamed(RouteHelper.getOrderRoute());
        break;
      case 'lib/features/order/screens/guest_track_order_screen.dart':
        Get.toNamed(RouteHelper.getGuestTrackOrderScreen('12345', '1234567890'));
        break;

      // Product screens
      case 'lib/features/product/screens/item_campaign_screen.dart':
        Get.toNamed(RouteHelper.getItemCampaignRoute());
        break;
      case 'lib/features/product/screens/popular_food_screen.dart':
        Get.toNamed(RouteHelper.getPopularFoodRoute(true));
        break;

      // Profile screens
      case 'lib/features/profile/screens/profile_screen.dart':
        Get.toNamed(RouteHelper.getProfileRoute());
        break;
      case 'lib/features/profile/screens/update_profile_screen.dart':
        Get.toNamed(RouteHelper.getUpdateProfileRoute());
        break;

      // Refer and earn screen
      case 'lib/features/refer and earn/screens/refer_and_earn_screen.dart':
        Get.toNamed(RouteHelper.getReferAndEarnRoute());
        break;

      // Restaurant screens
      case 'lib/features/restaurant/screens/all_restaurant_screen.dart':
        Get.toNamed(RouteHelper.getAllRestaurantRoute(''));
        break;
      case 'lib/features/restaurant/screens/campaign_screen.dart':
        Get.toNamed(RouteHelper.basicCampaign);
        break;

      // Search screen
      case 'lib/features/search/screens/search_screen.dart':
        Get.toNamed(RouteHelper.getSearchRoute());
        break;

      // Splash screen
      case 'lib/features/splash/screens/splash_screen.dart':
        Get.toNamed(RouteHelper.getSplashRoute(null, null));
        break;

      // Support screen
      case 'lib/features/support/screens/support_screen.dart':
        Get.toNamed(RouteHelper.getSupportRoute());
        break;

      // Update screen
      case 'lib/features/update/screens/update_screen.dart':
        Get.toNamed(RouteHelper.getUpdateRoute(true));
        break;

      // Verification screens
      case 'lib/features/verification/screens/forget_pass_screen.dart':
        Get.toNamed(RouteHelper.forgotPassword);
        break;

      // Wallet screen
      case 'lib/features/wallet/screens/wallet_screen.dart':
        Get.toNamed(RouteHelper.getWalletRoute());
        break;

      default:
        Get.snackbar(
          'Navigation Not Configured',
          'Route not configured for: ${screen.itemName}',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
    }
  }

  void handleVersionTap() {
    final now = DateTime.now();
    if (_lastTapTime != null && now.difference(_lastTapTime!) > const Duration(seconds: 2)) {
      _tapCount = 0;
    }

    _tapCount++;
    _lastTapTime = now;

    if (_tapCount == 5) {
      _tapCount = 0;
      developerModeEnabled.value = true;
      Get.toNamed(RouteHelper.getDeveloperCatalogRoute());
      Get.snackbar(
        'Developer Mode',
        'Developer Catalog Activated',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
      );
    }
  }

  void copyFilePath(String path) {
    // Copy to clipboard
    Get.snackbar(
      'Copied',
      'File path copied to clipboard',
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 1),
    );
  }
}

// Helper controller for preview mode
class DevPreviewModeController extends GetxController {
  bool isPreviewMode = false;
}