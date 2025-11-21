import 'package:get/get.dart';
import 'package:godelivery_user/common/enums/data_source_enum.dart';
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

/// Service responsible for coordinating all data loading during splash screen
/// with progress tracking, timeout handling, and retry logic
class SplashDataLoaderService {
  static const int maxRetries = 2;
  static const int requestTimeout = 15; // seconds per request
  static const int totalTimeout = 45; // seconds total

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

  /// Main method to load all data with progress tracking
  Future<bool> loadAllData({
    required Function(double, String) onProgress,
    required Function(String) onError,
    bool useCache = true,
  }) async {
    try {
      _progress = 0.0;
      _hasError = false;

      print('🚀 [SPLASH DATA LOADER] Starting comprehensive data load...');

      // Step 1: Config (required first) - already loaded in splash, just verify
      _updateProgress('config', 'Loading configuration...', onProgress);

      // Config should already be loaded, but we'll verify
      if (Get.find<SplashController>().configModel == null) {
        print('❌ [SPLASH DATA LOADER] Config not available!');
        onError('Failed to load configuration');
        return false;
      }

      // Step 2: User Data (if logged in)
      if (Get.find<AuthController>().isLoggedIn()) {
        await _loadUserData(onProgress, onError, useCache);
      }

      // Step 3: Core Data (parallel)
      await _loadCoreData(onProgress, onError, useCache);

      // Step 4: Conditional Data (config-dependent)
      await _loadConditionalData(onProgress, onError, useCache);

      // Step 5: Auth-dependent Data (if logged in)
      if (Get.find<AuthController>().isLoggedIn()) {
        await _loadAuthData(onProgress, onError, useCache);
      }

      _updateProgress('cashback', 'Data loading complete!', onProgress);
      print('✅ [SPLASH DATA LOADER] All data loaded successfully');

      return true;
    } catch (e) {
      print('❌ [SPLASH DATA LOADER] Error: $e');
      _hasError = true;
      _errorMessage = e.toString();
      onError('Failed to load data: $e');
      return false;
    }
  }

  /// Load user-specific data (profile, addresses)
  Future<void> _loadUserData(
    Function(double, String) onProgress,
    Function(String) onError,
    bool useCache,
  ) async {
    print('👤 [SPLASH DATA LOADER] Loading user data...');

    try {
      // Load profile and addresses in parallel
      await Future.wait([
        _loadWithRetry(
          'profile',
          'Loading profile...',
          () => Get.find<ProfileController>().getUserInfo(),
          onProgress,
          onError,
        ),
        _loadWithRetry(
          'addresses',
          'Loading addresses...',
          () => Get.find<AddressController>().getAddressList(),
          onProgress,
          onError,
        ),
      ]);
    } catch (e) {
      print('⚠️ [SPLASH DATA LOADER] User data loading failed: $e');
      // Non-critical, continue anyway
    }
  }

  /// Load core data that doesn't depend on config flags
  Future<void> _loadCoreData(
    Function(double, String) onProgress,
    Function(String) onError,
    bool useCache,
  ) async {
    print('📦 [SPLASH DATA LOADER] Loading core data...');

    final dataSource = useCache ? DataSourceEnum.local : DataSourceEnum.client;

    try {
      // Load all core data in parallel (limit to 5 concurrent to avoid overwhelming network)
      await Future.wait([
        _loadWithRetry(
          'categories',
          'Loading categories...',
          () => Get.find<CategoryController>().getCategoryList(false, dataSource: dataSource),
          onProgress,
          onError,
        ),
        _loadWithRetry(
          'banners',
          'Loading banners...',
          () => Get.find<HomeController>().getBannerList(false, dataSource: dataSource),
          onProgress,
          onError,
        ),
        _loadWithRetry(
          'cuisines',
          'Loading cuisines...',
          () => Get.find<CuisineController>().getCuisineList(dataSource: dataSource),
          onProgress,
          onError,
        ),
        _loadWithRetry(
          'advertisements',
          'Loading advertisements...',
          () => Get.find<AdvertisementController>().getAdvertisementList(),
          onProgress,
          onError,
        ),
        _loadWithRetry(
          'stories',
          'Loading stories...',
          () => Get.find<StoryController>().getStories(reload: !useCache),
          onProgress,
          onError,
        ),
      ]);

      // Second batch
      await Future.wait([
        _loadWithRetry(
          'zones',
          'Loading zones...',
          () => Get.find<LocationController>().getZoneList(),
          onProgress,
          onError,
        ),
        _loadWithRetry(
          'dine_in',
          'Loading dine-in restaurants...',
          () => Get.find<DineInController>().getDineInRestaurantList(1, false),
          onProgress,
          onError,
        ),
        _loadWithRetry(
          'restaurants',
          'Loading restaurants...',
          () => Get.find<RestaurantController>().getRestaurantList(1, false),
          onProgress,
          onError,
        ),
        _loadWithRetry(
          'campaigns',
          'Loading campaigns...',
          () => Get.find<CampaignController>().getItemCampaignList(false),
          onProgress,
          onError,
        ),
      ]);
    } catch (e) {
      print('⚠️ [SPLASH DATA LOADER] Core data loading failed: $e');
      throw e; // Core data is critical
    }
  }

  /// Load data that depends on config flags
  Future<void> _loadConditionalData(
    Function(double, String) onProgress,
    Function(String) onError,
    bool useCache,
  ) async {
    print('🎯 [SPLASH DATA LOADER] Loading conditional data...');

    final config = Get.find<SplashController>().configModel!;
    final futures = <Future>[];

    // Add conditional data loads based on config
    if (config.popularRestaurant == 1) {
      futures.add(_loadWithRetry(
        'popular_restaurants',
        'Loading popular restaurants...',
        () => Get.find<RestaurantController>().getPopularRestaurantList(false, 'all', false),
        onProgress,
        onError,
      ));
    }

    if (config.popularFood == 1) {
      futures.add(_loadWithRetry(
        'popular_products',
        'Loading popular products...',
        () => Get.find<ProductController>().getPopularProductList(false, 'all', false),
        onProgress,
        onError,
      ));
    }

    if (config.newRestaurant == 1) {
      futures.add(_loadWithRetry(
        'latest_restaurants',
        'Loading new restaurants...',
        () => Get.find<RestaurantController>().getLatestRestaurantList(false, 'all', false),
        onProgress,
        onError,
      ));
    }

    if (config.mostReviewedFoods == 1) {
      futures.add(_loadWithRetry(
        'reviewed_products',
        'Loading reviewed products...',
        () => Get.find<ReviewController>().getReviewedProductList(false, 'all', false),
        onProgress,
        onError,
      ));
    }

    if (futures.isNotEmpty) {
      try {
        await Future.wait(futures);
      } catch (e) {
        print('⚠️ [SPLASH DATA LOADER] Conditional data loading failed: $e');
        // Non-critical, continue anyway
      }
    }
  }

  /// Load auth-dependent data (recently viewed, order again, etc.)
  Future<void> _loadAuthData(
    Function(double, String) onProgress,
    Function(String) onError,
    bool useCache,
  ) async {
    print('🔐 [SPLASH DATA LOADER] Loading auth-dependent data...');

    try {
      await Future.wait([
        _loadWithRetry(
          'recently_viewed',
          'Loading recently viewed...',
          () => Get.find<RestaurantController>().getRecentlyViewedRestaurantList(false, 'all', false),
          onProgress,
          onError,
        ),
        _loadWithRetry(
          'order_again',
          'Loading order again...',
          () => Get.find<RestaurantController>().getOrderAgainRestaurantList(false),
          onProgress,
          onError,
        ),
        _loadWithRetry(
          'notifications',
          'Loading notifications...',
          () => Get.find<NotificationController>().getNotificationList(false),
          onProgress,
          onError,
        ),
        _loadWithRetry(
          'orders',
          'Loading orders...',
          () => Get.find<OrderController>().getRunningOrders(1, notify: false),
          onProgress,
          onError,
        ),
        _loadWithRetry(
          'cashback',
          'Loading cashback offers...',
          () => Get.find<HomeController>().getCashBackOfferList(dataSource: useCache ? DataSourceEnum.local : DataSourceEnum.client),
          onProgress,
          onError,
        ),
      ]);
    } catch (e) {
      print('⚠️ [SPLASH DATA LOADER] Auth data loading failed: $e');
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
            print('⏱️ [SPLASH DATA LOADER] Timeout for $key');
            throw TimeoutException('Request timeout for $key');
          },
        );

        print('✅ [SPLASH DATA LOADER] Loaded: $key');
        return; // Success
      } catch (e) {
        attempts++;
        print('⚠️ [SPLASH DATA LOADER] Attempt $attempts/$maxRetries failed for $key: $e');

        if (attempts >= maxRetries) {
          print('❌ [SPLASH DATA LOADER] Max retries reached for $key');
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
