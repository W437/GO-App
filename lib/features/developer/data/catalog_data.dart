import 'package:godelivery_user/features/developer/models/catalog_item_model.dart';

class CatalogData {
  static List<CatalogItemModel> getAllScreens() {
    return [
      // Address Module (2 screens)
      CatalogItemModel(
        itemName: 'Add Address Screen',
        filePath: 'lib/features/address/screens/add_address_screen.dart',
        category: ItemCategory.screen,
        module: 'Address',
        requiresAuth: true,
      ),
      CatalogItemModel(
        itemName: 'Address Screen',
        filePath: 'lib/features/address/screens/address_screen.dart',
        category: ItemCategory.screen,
        module: 'Address',
        requiresAuth: true,
      ),

      // Auth Module (6 screens)
      CatalogItemModel(
        itemName: 'Sign In Screen',
        filePath: 'lib/features/auth/screens/sign_in_screen.dart',
        category: ItemCategory.screen,
        module: 'Auth',
      ),
      CatalogItemModel(
        itemName: 'Sign Up Screen',
        filePath: 'lib/features/auth/screens/sign_up_screen.dart',
        category: ItemCategory.screen,
        module: 'Auth',
      ),
      CatalogItemModel(
        itemName: 'New User Setup Screen',
        filePath: 'lib/features/auth/screens/new_user_setup_screen.dart',
        category: ItemCategory.screen,
        module: 'Auth',
      ),
      CatalogItemModel(
        itemName: 'Delivery Man Registration',
        filePath: 'lib/features/auth/screens/delivery_man_registration_screen.dart',
        category: ItemCategory.screen,
        module: 'Auth',
      ),
      CatalogItemModel(
        itemName: 'Restaurant Registration',
        filePath: 'lib/features/auth/screens/restaurant_registration_screen.dart',
        category: ItemCategory.screen,
        module: 'Auth',
      ),
      CatalogItemModel(
        itemName: 'Deliveryman Registration Web',
        filePath: 'lib/features/auth/screens/web/deliveryman_registration_web_screen.dart',
        category: ItemCategory.screen,
        module: 'Auth',
        isWebOnly: true,
      ),

      // Business Module (2 screens)
      CatalogItemModel(
        itemName: 'Subscription Payment Screen',
        filePath: 'lib/features/business/screens/subscription_payment_screen.dart',
        category: ItemCategory.screen,
        module: 'Business',
        requiresAuth: true,
      ),
      CatalogItemModel(
        itemName: 'Subscription Success/Failed',
        filePath: 'lib/features/business/screens/subscription_success_or_failed_screen.dart',
        category: ItemCategory.screen,
        module: 'Business',
      ),

      // Cart Module (1 screen)
      CatalogItemModel(
        itemName: 'Cart Screen',
        filePath: 'lib/features/cart/screens/cart_screen.dart',
        category: ItemCategory.screen,
        module: 'Cart',
      ),

      // Category Module (2 screens)
      CatalogItemModel(
        itemName: 'Category Screen',
        filePath: 'lib/features/category/screens/category_screen.dart',
        category: ItemCategory.screen,
        module: 'Category',
      ),
      CatalogItemModel(
        itemName: 'Category Product Screen',
        filePath: 'lib/features/category/screens/category_product_screen.dart',
        category: ItemCategory.screen,
        module: 'Category',
        requiresData: true,
      ),

      // Chat Module (3 screens)
      CatalogItemModel(
        itemName: 'Chat Screen',
        filePath: 'lib/features/chat/screens/chat_screen.dart',
        category: ItemCategory.screen,
        module: 'Chat',
        requiresAuth: true,
      ),
      CatalogItemModel(
        itemName: 'Conversation Screen',
        filePath: 'lib/features/chat/screens/conversation_screen.dart',
        category: ItemCategory.screen,
        module: 'Chat',
        requiresAuth: true,
      ),
      CatalogItemModel(
        itemName: 'Preview Screen',
        filePath: 'lib/features/chat/screens/preview_screen.dart',
        category: ItemCategory.screen,
        module: 'Chat',
      ),

      // Checkout Module (5 screens)
      CatalogItemModel(
        itemName: 'Checkout Screen',
        filePath: 'lib/features/checkout/screens/checkout_screen.dart',
        category: ItemCategory.screen,
        module: 'Checkout',
        requiresAuth: true,
        requiresData: true,
      ),
      CatalogItemModel(
        itemName: 'Offline Payment Screen',
        filePath: 'lib/features/checkout/screens/offline_payment_screen.dart',
        category: ItemCategory.screen,
        module: 'Checkout',
      ),
      CatalogItemModel(
        itemName: 'Order Successful Screen',
        filePath: 'lib/features/checkout/screens/order_successful_screen.dart',
        category: ItemCategory.screen,
        module: 'Checkout',
      ),
      CatalogItemModel(
        itemName: 'Payment Screen',
        filePath: 'lib/features/checkout/screens/payment_screen.dart',
        category: ItemCategory.screen,
        module: 'Checkout',
        requiresData: true,
      ),
      CatalogItemModel(
        itemName: 'Payment Webview Screen',
        filePath: 'lib/features/checkout/screens/payment_webview_screen.dart',
        category: ItemCategory.screen,
        module: 'Checkout',
        requiresData: true,
      ),

      // Coupon Module (1 screen)
      CatalogItemModel(
        itemName: 'Coupon Screen',
        filePath: 'lib/features/coupon/screens/coupon_screen.dart',
        category: ItemCategory.screen,
        module: 'Coupon',
        requiresAuth: true,
      ),

      // Cuisine Module (2 screens)
      CatalogItemModel(
        itemName: 'Cuisine Screen',
        filePath: 'lib/features/cuisine/screens/cuisine_screen.dart',
        category: ItemCategory.screen,
        module: 'Cuisine',
      ),
      CatalogItemModel(
        itemName: 'Cuisine Restaurant Screen',
        filePath: 'lib/features/cuisine/screens/cuisine_restaurant_screen.dart',
        category: ItemCategory.screen,
        module: 'Cuisine',
        requiresData: true,
      ),

      // Dashboard Module (1 screen)
      CatalogItemModel(
        itemName: 'Dashboard Screen',
        filePath: 'lib/features/dashboard/screens/dashboard_screen.dart',
        category: ItemCategory.screen,
        module: 'Dashboard',
      ),

      // Dine In Module (1 screen)
      CatalogItemModel(
        itemName: 'Dine In Restaurant Screen',
        filePath: 'lib/features/dine_in/screens/dine_in_restaurant_screen.dart',
        category: ItemCategory.screen,
        module: 'Dine In',
      ),

      // Explore Module (1 screen)
      CatalogItemModel(
        itemName: 'Explore Screen',
        filePath: 'lib/features/explore/screens/explore_screen.dart',
        category: ItemCategory.screen,
        module: 'Explore',
      ),

      // Favourite Module (1 screen)
      CatalogItemModel(
        itemName: 'Favourite Screen',
        filePath: 'lib/features/favourite/screens/favourite_screen.dart',
        category: ItemCategory.screen,
        module: 'Favourite',
        requiresAuth: true,
      ),

      // Game Module (1 screen)
      CatalogItemModel(
        itemName: 'Flappy Bird Game',
        filePath: 'lib/features/game/screens/flappy_bird_game_screen.dart',
        category: ItemCategory.screen,
        module: 'Game',
      ),

      // Home Module (5 screens)
      CatalogItemModel(
        itemName: 'Home Screen',
        filePath: 'lib/features/home/screens/home_screen.dart',
        category: ItemCategory.screen,
        module: 'Home',
      ),
      CatalogItemModel(
        itemName: 'Map View Screen',
        filePath: 'lib/features/home/screens/map_view_screen.dart',
        category: ItemCategory.screen,
        module: 'Home',
      ),
      CatalogItemModel(
        itemName: 'Theme 1 Home Screen',
        filePath: 'lib/features/home/screens/theme1_home_screen.dart',
        category: ItemCategory.screen,
        module: 'Home',
      ),
      CatalogItemModel(
        itemName: 'Theme 2 Home Screen',
        filePath: 'lib/features/home/screens/theme2_home_screen.dart',
        category: ItemCategory.screen,
        module: 'Home',
      ),
      CatalogItemModel(
        itemName: 'Web Home Screen',
        filePath: 'lib/features/home/screens/web_home_screen.dart',
        category: ItemCategory.screen,
        module: 'Home',
        isWebOnly: true,
      ),

      // HTML Module (1 screen)
      CatalogItemModel(
        itemName: 'HTML Viewer Screen',
        filePath: 'lib/features/html/screens/html_viewer_screen.dart',
        category: ItemCategory.screen,
        module: 'HTML',
      ),

      // Interest Module (1 screen)
      CatalogItemModel(
        itemName: 'Interest Screen',
        filePath: 'lib/features/interest/screens/interest_screen.dart',
        category: ItemCategory.screen,
        module: 'Interest',
      ),

      // Language Module (2 screens)
      CatalogItemModel(
        itemName: 'Language Screen',
        filePath: 'lib/features/language/screens/language_screen.dart',
        category: ItemCategory.screen,
        module: 'Language',
      ),
      CatalogItemModel(
        itemName: 'Web Language Screen',
        filePath: 'lib/features/language/screens/web_language_screen.dart',
        category: ItemCategory.screen,
        module: 'Language',
        isWebOnly: true,
      ),

      // Location Module (3 screens)
      CatalogItemModel(
        itemName: 'Access Location Screen',
        filePath: 'lib/features/location/screens/access_location_screen.dart',
        category: ItemCategory.screen,
        module: 'Location',
      ),
      CatalogItemModel(
        itemName: 'Map Screen',
        filePath: 'lib/features/location/screens/map_screen.dart',
        category: ItemCategory.screen,
        module: 'Location',
      ),
      CatalogItemModel(
        itemName: 'Pick Map Screen',
        filePath: 'lib/features/location/screens/pick_map_screen.dart',
        category: ItemCategory.screen,
        module: 'Location',
      ),

      // Loyalty Module (1 screen)
      CatalogItemModel(
        itemName: 'Loyalty Screen',
        filePath: 'lib/features/loyalty/screens/loyalty_screen.dart',
        category: ItemCategory.screen,
        module: 'Loyalty',
        requiresAuth: true,
      ),

      // Menu Module (1 screen)
      CatalogItemModel(
        itemName: 'Menu Screen',
        filePath: 'lib/features/menu/screens/menu_screen.dart',
        category: ItemCategory.screen,
        module: 'Menu',
      ),

      // Notification Module (1 screen)
      CatalogItemModel(
        itemName: 'Notification Screen',
        filePath: 'lib/features/notification/screens/notification_screen.dart',
        category: ItemCategory.screen,
        module: 'Notification',
        requiresAuth: true,
      ),

      // Onboard Module (1 screen)
      CatalogItemModel(
        itemName: 'Unified Onboarding Screen',
        filePath: 'lib/features/onboard/screens/unified_onboarding_screen.dart',
        category: ItemCategory.screen,
        module: 'Onboard',
      ),

      // Order Module (5 screens)
      CatalogItemModel(
        itemName: 'Order Screen',
        filePath: 'lib/features/order/screens/order_screen.dart',
        category: ItemCategory.screen,
        module: 'Order',
        requiresAuth: true,
      ),
      CatalogItemModel(
        itemName: 'Order Details Screen',
        filePath: 'lib/features/order/screens/order_details_screen.dart',
        category: ItemCategory.screen,
        module: 'Order',
        requiresData: true,
      ),
      CatalogItemModel(
        itemName: 'Order Tracking Screen',
        filePath: 'lib/features/order/screens/order_tracking_screen.dart',
        category: ItemCategory.screen,
        module: 'Order',
        requiresData: true,
      ),
      CatalogItemModel(
        itemName: 'Guest Track Order Screen',
        filePath: 'lib/features/order/screens/guest_track_order_screen.dart',
        category: ItemCategory.screen,
        module: 'Order',
      ),
      CatalogItemModel(
        itemName: 'Refund Request Screen',
        filePath: 'lib/features/order/screens/refund_request_screen.dart',
        category: ItemCategory.screen,
        module: 'Order',
        requiresAuth: true,
        requiresData: true,
      ),

      // Product Module (2 screens)
      CatalogItemModel(
        itemName: 'Item Campaign Screen',
        filePath: 'lib/features/product/screens/item_campaign_screen.dart',
        category: ItemCategory.screen,
        module: 'Product',
      ),
      CatalogItemModel(
        itemName: 'Popular Food Screen',
        filePath: 'lib/features/product/screens/popular_food_screen.dart',
        category: ItemCategory.screen,
        module: 'Product',
      ),

      // Profile Module (2 screens)
      CatalogItemModel(
        itemName: 'Profile Screen',
        filePath: 'lib/features/profile/screens/profile_screen.dart',
        category: ItemCategory.screen,
        module: 'Profile',
      ),
      CatalogItemModel(
        itemName: 'Update Profile Screen',
        filePath: 'lib/features/profile/screens/update_profile_screen.dart',
        category: ItemCategory.screen,
        module: 'Profile',
        requiresAuth: true,
      ),

      // Refer and Earn Module (1 screen)
      CatalogItemModel(
        itemName: 'Refer and Earn Screen',
        filePath: 'lib/features/refer and earn/screens/refer_and_earn_screen.dart',
        category: ItemCategory.screen,
        module: 'Refer & Earn',
        requiresAuth: true,
      ),

      // Restaurant Module (5 screens)
      CatalogItemModel(
        itemName: 'All Restaurant Screen',
        filePath: 'lib/features/restaurant/screens/all_restaurant_screen.dart',
        category: ItemCategory.screen,
        module: 'Restaurant',
      ),
      CatalogItemModel(
        itemName: 'Campaign Screen',
        filePath: 'lib/features/restaurant/screens/campaign_screen.dart',
        category: ItemCategory.screen,
        module: 'Restaurant',
      ),
      CatalogItemModel(
        itemName: 'Restaurant Screen',
        filePath: 'lib/features/restaurant/screens/restaurant_screen.dart',
        category: ItemCategory.screen,
        module: 'Restaurant',
        requiresData: true,
      ),
      CatalogItemModel(
        itemName: 'Restaurant Product Search',
        filePath: 'lib/features/restaurant/screens/restaurant_product_search_screen.dart',
        category: ItemCategory.screen,
        module: 'Restaurant',
        requiresData: true,
      ),
      CatalogItemModel(
        itemName: 'Web Campaign Screen',
        filePath: 'lib/features/restaurant/screens/web_campaign_screen.dart',
        category: ItemCategory.screen,
        module: 'Restaurant',
        isWebOnly: true,
      ),

      // Review Module (2 screens)
      CatalogItemModel(
        itemName: 'Rate Review Screen',
        filePath: 'lib/features/review/screens/rate_review_screen.dart',
        category: ItemCategory.screen,
        module: 'Review',
        requiresAuth: true,
        requiresData: true,
      ),
      CatalogItemModel(
        itemName: 'Review Screen',
        filePath: 'lib/features/review/screens/review_screen.dart',
        category: ItemCategory.screen,
        module: 'Review',
        requiresData: true,
      ),

      // Search Module (1 screen)
      CatalogItemModel(
        itemName: 'Search Screen',
        filePath: 'lib/features/search/screens/search_screen.dart',
        category: ItemCategory.screen,
        module: 'Search',
      ),

      // Splash Module (1 screen)
      CatalogItemModel(
        itemName: 'Splash Screen',
        filePath: 'lib/features/splash/screens/splash_screen.dart',
        category: ItemCategory.screen,
        module: 'Splash',
      ),

      // Story Module (1 screen)
      CatalogItemModel(
        itemName: 'Story Viewer Screen',
        filePath: 'lib/features/story/screens/story_viewer_screen.dart',
        category: ItemCategory.screen,
        module: 'Story',
        requiresData: true,
      ),

      // Support Module (1 screen)
      CatalogItemModel(
        itemName: 'Support Screen',
        filePath: 'lib/features/support/screens/support_screen.dart',
        category: ItemCategory.screen,
        module: 'Support',
        requiresAuth: true,
      ),

      // Update Module (1 screen)
      CatalogItemModel(
        itemName: 'Update Screen',
        filePath: 'lib/features/update/screens/update_screen.dart',
        category: ItemCategory.screen,
        module: 'Update',
      ),

      // Verification Module (3 screens)
      CatalogItemModel(
        itemName: 'Forget Password Screen',
        filePath: 'lib/features/verification/screens/forget_pass_screen.dart',
        category: ItemCategory.screen,
        module: 'Verification',
      ),
      CatalogItemModel(
        itemName: 'New Password Screen',
        filePath: 'lib/features/verification/screens/new_pass_screen.dart',
        category: ItemCategory.screen,
        module: 'Verification',
      ),
      CatalogItemModel(
        itemName: 'Verification Screen',
        filePath: 'lib/features/verification/screens/verification_screen.dart',
        category: ItemCategory.screen,
        module: 'Verification',
      ),

      // Wallet Module (1 screen)
      CatalogItemModel(
        itemName: 'Wallet Screen',
        filePath: 'lib/features/wallet/screens/wallet_screen.dart',
        category: ItemCategory.screen,
        module: 'Wallet',
        requiresAuth: true,
      ),

      // Developer Module (1 screen)
      CatalogItemModel(
        itemName: 'Modern Input Field Test',
        filePath: 'lib/features/developer/screens/input_test_screen.dart',
        category: ItemCategory.screen,
        module: 'Developer',
      ),
    ];
  }

  static List<String> getAllModules() {
    final screens = getAllScreens();
    final modules = screens.map((screen) => screen.module).toSet().toList();
    modules.sort();
    return modules;
  }

  static List<CatalogItemModel> getScreensByModule(String module) {
    return getAllScreens().where((screen) => screen.module == module).toList();
  }

  static List<CatalogItemModel> searchScreens(String query) {
    final lowercaseQuery = query.toLowerCase();
    return getAllScreens().where((screen) {
      return screen.itemName.toLowerCase().contains(lowercaseQuery) ||
          screen.filePath.toLowerCase().contains(lowercaseQuery) ||
          screen.module.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }
}