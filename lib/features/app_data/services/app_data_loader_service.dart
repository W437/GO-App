import 'package:get/get.dart';
import 'package:godelivery_user/features/auth/controllers/auth_controller.dart';
import 'package:godelivery_user/features/home/controllers/home_controller.dart';
import 'package:godelivery_user/features/category/controllers/category_controller.dart';
import 'package:godelivery_user/features/cuisine/controllers/cuisine_controller.dart';
import 'package:godelivery_user/features/home/controllers/advertisement_controller.dart';
import 'package:godelivery_user/features/dine_in/controllers/dine_in_controller.dart';
import 'package:godelivery_user/features/story/controllers/story_controller.dart';
import 'package:godelivery_user/features/location/controllers/location_controller.dart';
import 'package:godelivery_user/features/restaurant/controllers/restaurant_controller.dart';
import 'package:godelivery_user/features/product/controllers/campaign_controller.dart';
import 'package:godelivery_user/features/product/controllers/product_controller.dart';
import 'package:godelivery_user/features/review/controllers/review_controller.dart';
import 'package:godelivery_user/features/profile/controllers/profile_controller.dart';
import 'package:godelivery_user/features/notification/controllers/notification_controller.dart';
import 'package:godelivery_user/features/order/controllers/order_controller.dart';
import 'package:godelivery_user/features/address/controllers/address_controller.dart';
import 'package:godelivery_user/features/splash/controllers/splash_controller.dart';

/// Centralized service for coordinating all app-wide data loading
/// Handles initial load, refresh, progress tracking, and error handling
class AppDataLoaderService {
  static const int maxRetries = 2;
  static const int requestTimeout = 15; // seconds per request

  double _progress = 0.0;
  String _currentMessage = '';
  bool _hasError = false;
  String _errorMessage = '';

  double get progress => _progress;
  String get currentMessage => _currentMessage;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;

  // Progress weights for different data types
  static const Map<String, double> progressWeights = {
    'config': 5.0,
    'profile': 10.0,
    'categories': 15.0,
    'banners': 20.0,
    'cuisines': 25.0,
    'advertisements': 30.0,
    'stories': 35.0,
    'zones': 40.0,
    'dine_in': 45.0,
    'restaurants': 50.0,
    'campaigns': 55.0,
    'popular_restaurants': 60.0,
    'popular_products': 65.0,
    'latest_restaurants': 70.0,
    'reviewed_products': 75.0,
    'recently_viewed': 80.0,
    'order_again': 85.0,
    'notifications': 90.0,
    'orders': 95.0,
    'addresses': 97.0,
    'cashback': 100.0,
  };

  /// Load all application data with progress tracking
  /// Used during app initialization
  Future<bool> loadInitialData({
    required Function(double, String) onProgress,
    required Function(String) onError,
  }) async {
    try {
      _progress = 0.0;
      _hasError = false;

      print('🚀 [APP DATA] Starting initial data load...');

      // Message 1: Start
      onProgress(5.0, 'Waking up the kitchen...');

      // Config verification
      if (Get.find<SplashController>().configModel == null) {
        print('❌ [APP DATA] Config not available!');
        onError('Failed to load configuration');
        return false;
      }

      // Load user data if logged in
      if (Get.find<AuthController>().isLoggedIn()) {
        await _loadUserData(onProgress, onError);
      }

      // Message 2: Loading core data
      onProgress(20.0, 'Finding delicious options...');
      await _loadCoreData(onProgress, onError);

      // Message 3: Loading restaurants
      onProgress(50.0, 'Hunting down the best spots...');
      await _loadConditionalData(onProgress, onError);

      // Load auth data if logged in
      if (Get.find<AuthController>().isLoggedIn()) {
        await _loadAuthData(onProgress, onError);
      }

      // Message 4: Almost done
      onProgress(85.0, 'Almost there...');
      await Future.delayed(const Duration(milliseconds: 200));

      // Message 5: Complete
      onProgress(100.0, 'Bon appétit!');
      print('✅ [APP DATA] All data loaded successfully');

      return true;
    } catch (e) {
      print('❌ [APP DATA] Error: $e');
      _hasError = true;
      _errorMessage = e.toString();
      onError('Failed to load data: $e');
      return false;
    }
  }

  /// Refresh all data (for pull-to-refresh)
  Future<void> refreshAllData() async {
    print('🔄 [APP DATA] Refreshing all data...');

    final config = Get.find<SplashController>().configModel!;

    // Refresh core data
    await Future.wait([
      Get.find<CategoryController>().getCategoryList(true),
      Get.find<HomeController>().getBannerList(true),
      Get.find<CuisineController>().getCuisineList(),
      Get.find<AdvertisementController>().getAdvertisementList(reload: true),
      Get.find<StoryController>().getStories(reload: true),
      Get.find<RestaurantController>().getRestaurantList(0, true),
      Get.find<CampaignController>().getItemCampaignList(true),
    ]);

    // Refresh conditional data
    if (config.popularRestaurant == 1) {
      Get.find<RestaurantController>().getPopularRestaurantList(true, 'all', false);
    }
    if (config.popularFood == 1) {
      Get.find<ProductController>().getPopularProductList(true, 'all', false);
    }
    if (config.newRestaurant == 1) {
      Get.find<RestaurantController>().getLatestRestaurantList(true, 'all', false);
    }

    // Refresh auth data
    if (Get.find<AuthController>().isLoggedIn()) {
      Get.find<ProfileController>().getUserInfo();
      Get.find<RestaurantController>().getRecentlyViewedRestaurantList(true, 'all', false);
      Get.find<RestaurantController>().getOrderAgainRestaurantList(true);
      Get.find<NotificationController>().getNotificationList(true);
      Get.find<AddressController>().getAddressList();
    }

    print('✅ [APP DATA] Refresh complete');
  }

  /// Load user-specific data (profile, addresses)
  Future<void> _loadUserData(
    Function(double, String) onProgress,
    Function(String) onError,
  ) async {
    print('👤 [APP DATA] Loading user data...');

    try {
      await Future.wait([
        _loadWithRetry(
          'profile',
          'Getting to know you...',
          () => Get.find<ProfileController>().getUserInfo(),
          onProgress,
          onError,
        ),
        _loadWithRetry(
          'addresses',
          'Finding your favorite spots...',
          () => Get.find<AddressController>().getAddressList(),
          onProgress,
          onError,
        ),
      ]);
    } catch (e) {
      print('⚠️ [APP DATA] User data loading failed: $e');
      // Non-critical, continue anyway
    }
  }

  /// Load core data that doesn't depend on config flags
  /// ALL loaded in parallel for maximum speed!
  Future<void> _loadCoreData(
    Function(double, String) onProgress,
    Function(String) onError,
  ) async {
    print('📦 [APP DATA] Loading core data in parallel...');

    try {
      // Load ALL core data in parallel for maximum speed
      onProgress(20.0, 'Loading your personalized experience...');

      await Future.wait([
        _loadWithRetry(
          'categories',
          'Categories...',
          () => Get.find<CategoryController>().getCategoryList(false),
          onProgress,
          onError,
        ),
        _loadWithRetry(
          'banners',
          'Banners...',
          () => Get.find<HomeController>().getBannerList(false),
          onProgress,
          onError,
        ),
        _loadWithRetry(
          'cuisines',
          'Cuisines...',
          () => Get.find<CuisineController>().getCuisineList(),
          onProgress,
          onError,
        ),
        _loadWithRetry(
          'advertisements',
          'Ads...',
          () => Get.find<AdvertisementController>().getAdvertisementList(),
          onProgress,
          onError,
        ),
        _loadWithRetry(
          'stories',
          'Stories...',
          () => Get.find<StoryController>().getStories(reload: false),
          onProgress,
          onError,
        ),
        _loadWithRetry(
          'zones',
          'Zones...',
          () => Get.find<LocationController>().getZoneList(),
          onProgress,
          onError,
        ),
        _loadWithRetry(
          'dine_in',
          'Dine-in...',
          () => Get.find<DineInController>().getDineInRestaurantList(0, false),
          onProgress,
          onError,
        ),
        _loadWithRetry(
          'restaurants',
          'Restaurants...',
          () => Get.find<RestaurantController>().getRestaurantList(0, false),
          onProgress,
          onError,
        ),
        _loadWithRetry(
          'campaigns',
          'Campaigns...',
          () => Get.find<CampaignController>().getItemCampaignList(false),
          onProgress,
          onError,
        ),
      ]);

      print('✅ [APP DATA] Core data loaded in parallel');
    } catch (e) {
      print('⚠️ [APP DATA] Core data loading failed: $e');
      throw e; // Core data is critical
    }
  }

  /// Load data that depends on config flags
  Future<void> _loadConditionalData(
    Function(double, String) onProgress,
    Function(String) onError,
  ) async {
    print('🎯 [APP DATA] Loading conditional data...');

    final config = Get.find<SplashController>().configModel!;
    final futures = <Future>[];

    // Add conditional data loads based on config
    if (config.popularRestaurant == 1) {
      futures.add(_loadWithRetry(
        'popular_restaurants',
        'Finding crowd favorites...',
        () => Get.find<RestaurantController>().getPopularRestaurantList(false, 'all', false),
        onProgress,
        onError,
      ));
    }

    if (config.popularFood == 1) {
      futures.add(_loadWithRetry(
        'popular_products',
        'Picking trending dishes...',
        () => Get.find<ProductController>().getPopularProductList(false, 'all', false),
        onProgress,
        onError,
      ));
    }

    if (config.newRestaurant == 1) {
      futures.add(_loadWithRetry(
        'latest_restaurants',
        'Discovering new places...',
        () => Get.find<RestaurantController>().getLatestRestaurantList(false, 'all', false),
        onProgress,
        onError,
      ));
    }

    if (config.mostReviewedFoods == 1) {
      futures.add(_loadWithRetry(
        'reviewed_products',
        'Reading reviews for you...',
        () => Get.find<ReviewController>().getReviewedProductList(false, 'all', false),
        onProgress,
        onError,
      ));
    }

    if (futures.isNotEmpty) {
      try {
        await Future.wait(futures);
      } catch (e) {
        print('⚠️ [APP DATA] Conditional data loading failed: $e');
        // Non-critical, continue anyway
      }
    }
  }

  /// Load auth-dependent data (recently viewed, order again, etc.)
  Future<void> _loadAuthData(
    Function(double, String) onProgress,
    Function(String) onError,
  ) async {
    print('🔐 [APP DATA] Loading auth-dependent data...');

    try {
      await Future.wait([
        _loadWithRetry(
          'recently_viewed',
          'Remembering your favorites...',
          () => Get.find<RestaurantController>().getRecentlyViewedRestaurantList(false, 'all', false),
          onProgress,
          onError,
        ),
        _loadWithRetry(
          'order_again',
          'Your usual order is ready...',
          () => Get.find<RestaurantController>().getOrderAgainRestaurantList(false),
          onProgress,
          onError,
        ),
        _loadWithRetry(
          'notifications',
          'Checking for updates...',
          () => Get.find<NotificationController>().getNotificationList(false),
          onProgress,
          onError,
        ),
        _loadWithRetry(
          'orders',
          'Tracking your orders...',
          () => Get.find<OrderController>().getRunningOrders(0, notify: false),
          onProgress,
          onError,
        ),
        _loadWithRetry(
          'cashback',
          'Finding rewards for you...',
          () => Get.find<HomeController>().getCashBackOfferList(),
          onProgress,
          onError,
        ),
      ]);
    } catch (e) {
      print('⚠️ [APP DATA] Auth data loading failed: $e');
      // Non-critical, continue anyway
    }
  }

  /// Load with retry logic and timeout
  Future<void> _loadWithRetry(
    String key,
    String message,
    Future<void> Function() loadFunction,
    Function(double, String) onProgress,
    Function(String) onError,
  ) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        _updateProgress(key, message, onProgress);

        // Add timeout to each request
        await loadFunction().timeout(
          Duration(seconds: requestTimeout),
          onTimeout: () {
            print('⏱️ [APP DATA] Timeout for $key');
            throw TimeoutException('Request timeout for $key');
          },
        );

        print('✅ [APP DATA] Loaded: $key');
        return; // Success
      } catch (e) {
        attempts++;
        print('⚠️ [APP DATA] Attempt $attempts/$maxRetries failed for $key: $e');

        if (attempts >= maxRetries) {
          print('❌ [APP DATA] Max retries reached for $key');
          // Don't throw - let non-critical data fail silently
          return;
        }

        // Wait before retry
        await Future.delayed(Duration(seconds: 1));
      }
    }
  }

  /// Update progress and message
  void _updateProgress(String key, String message, Function(double, String) onProgress) {
    _progress = progressWeights[key] ?? _progress;
    _currentMessage = message;
    onProgress(_progress, message);
  }

  /// Reset state
  void reset() {
    _progress = 0.0;
    _currentMessage = '';
    _hasError = false;
    _errorMessage = '';
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}
