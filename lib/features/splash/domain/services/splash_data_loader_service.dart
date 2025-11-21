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

      // Message 1: Start
      onProgress(5.0, 'Waking up the kitchen...');

      // Config verification (no message)
      if (Get.find<SplashController>().configModel == null) {
        print('❌ [SPLASH DATA LOADER] Config not available!');
        onError('Failed to load configuration');
        return false;
      }

      // Load user data silently (if logged in)
      if (Get.find<AuthController>().isLoggedIn()) {
        await _loadUserData(onProgress, onError, useCache);
      }

      // Message 2: Loading core data
      onProgress(20.0, 'Finding delicious options...');
      await _loadCoreData(onProgress, onError, useCache);

      // Message 3: Loading restaurants
      onProgress(50.0, 'Hunting down the best spots...');
      await _loadConditionalData(onProgress, onError, useCache);

      // Load auth data silently (if logged in)
      if (Get.find<AuthController>().isLoggedIn()) {
        await _loadAuthData(onProgress, onError, useCache);
      }

      // Message 4: Almost done
      onProgress(85.0, 'Almost there...');
      await Future.delayed(const Duration(milliseconds: 200));

      // Message 5: Complete
      onProgress(100.0, 'Bon appétit!');
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
      // Load core data sequentially for visible progress
      await _loadWithRetry(
        'categories',
        'Finding delicious options...',
        () => Get.find<CategoryController>().getCategoryList(false, dataSource: dataSource),
        onProgress,
        onError,
      );
      await Future.delayed(const Duration(milliseconds: 50));

      await _loadWithRetry(
        'banners',
        'Spicing things up...',
        () => Get.find<HomeController>().getBannerList(false, dataSource: dataSource),
        onProgress,
        onError,
      );
      await Future.delayed(const Duration(milliseconds: 50));

      await _loadWithRetry(
        'cuisines',
        'Exploring cuisines...',
        () => Get.find<CuisineController>().getCuisineList(dataSource: dataSource),
        onProgress,
        onError,
      );
      await Future.delayed(const Duration(milliseconds: 50));

      await _loadWithRetry(
        'advertisements',
        'Checking for deals...',
        () => Get.find<AdvertisementController>().getAdvertisementList(),
        onProgress,
        onError,
      );
      await Future.delayed(const Duration(milliseconds: 50));

      await _loadWithRetry(
        'stories',
        'What\'s cooking today...',
        () => Get.find<StoryController>().getStories(reload: !useCache),
        onProgress,
        onError,
      );
      await Future.delayed(const Duration(milliseconds: 50));

      // Load remaining in parallel (faster)
      await Future.wait([
        _loadWithRetry(
          'zones',
          'Mapping your neighborhood...',
          () => Get.find<LocationController>().getZoneList(),
          onProgress,
          onError,
        ),
        _loadWithRetry(
          'dine_in',
          'Finding dine-in spots...',
          () => Get.find<DineInController>().getDineInRestaurantList(1, false),
          onProgress,
          onError,
        ),
        _loadWithRetry(
          'restaurants',
          'Hunting down the best spots...',
          () => Get.find<RestaurantController>().getRestaurantList(1, false),
          onProgress,
          onError,
        ),
        _loadWithRetry(
          'campaigns',
          'Looking for surprises...',
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
          () => Get.find<OrderController>().getRunningOrders(1, notify: false),
          onProgress,
          onError,
        ),
        _loadWithRetry(
          'cashback',
          'Finding rewards for you...',
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
