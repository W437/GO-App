# Complete Caching System Implementation Plan

**Date**: 2025-01-21
**Strategy**: Hybrid TTL-based caching with pull-to-refresh and app launch refresh
**Status**: Ready for implementation

---

## Executive Summary

Implement comprehensive caching across all app features with tiered TTL strategy, manual refresh controls, and automatic background updates.

**Key Decisions:**
- ✅ Tiered TTL (7d/24h/1h/15m based on data volatility)
- ✅ Hybrid cache strategy (cache-first if fresh, network-first if stale)
- ✅ App-level caching (no user scoping) + logout clearing
- ✅ Pull-to-refresh bypasses cache entirely
- ✅ App launch triggers background refresh
- ❌ No version checking (keeping it simple)
- ❌ No caching for sensitive data (payment, auth, chat, order tracking)

---

## Current State Analysis

### Existing Infrastructure
- **Storage**: Drift (SQLite) for mobile, SharedPreferences for web
- **Current Schema Version**: 3
- **Pattern**: LocalClient + DataSourceEnum (local/client)

### Coverage Statistics
**Cached (11/34 repositories = 32%):**
- ✅ Home (banners, cashback)
- ✅ Restaurants (list, popular, latest, recently viewed, order again)
- ✅ Products (popular products)
- ✅ Categories, Campaigns, Cuisines, Reviews, Stories, Advertisements, Addresses, Notifications

**NOT Cached (23/34 repositories = 68%):**
- ❌ Restaurant details
- ❌ Restaurant products (menu items)
- ❌ Restaurant recommended items
- ❌ Cart operations
- ❌ Checkout, Orders, Favourites, Profile, Wallet, Coupons, Search results, Dine-in, Chat
- ...and 11 more

### Critical Issues
1. No TTL/expiration - cache lives forever
2. No cache invalidation strategy
3. Unused `clearCacheResponses()` method
4. Restaurant products NOT cached (causes reload flicker)
5. 68% of features lack caching

---

## TTL Strategy

### Tiered TTL Configuration

Add to `lib/util/app_constants.dart`:

```dart
/// Cache TTL configuration (in seconds)
class CacheTTL {
  // Static data - rarely changes (7 days)
  static const int staticData = 604800;  // 7 days
  static const int categories = 604800;
  static const int cuisines = 604800;
  static const int languages = 604800;

  // Semi-static data - updated occasionally (24 hours)
  static const int semiStaticData = 86400;  // 24 hours
  static const int restaurantList = 86400;
  static const int popularRestaurants = 86400;
  static const int latestRestaurants = 86400;
  static const int recentlyViewedRestaurants = 86400;
  static const int productList = 86400;
  static const int banners = 86400;
  static const int advertisements = 86400;
  static const int campaigns = 86400;

  // Dynamic data - changes frequently (1 hour)
  static const int dynamicData = 3600;  // 1 hour
  static const int restaurantDetails = 3600;
  static const int restaurantProducts = 3600;
  static const int coupons = 3600;
  static const int stories = 3600;

  // Short-lived data - very dynamic (15 minutes)
  static const int shortLived = 900;  // 15 minutes
  static const int orderHistory = 900;
  static const int addresses = 900;
  static const int profile = 900;
  static const int favorites = 900;
  static const int reviews = 900;
  static const int searchResults = 900;

  // Default fallback
  static const int defaultTTL = 3600;  // 1 hour

  /// Get TTL for specific endpoint
  static int getTTL(String endpoint) {
    if (endpoint.contains('category')) return categories;
    if (endpoint.contains('cuisine')) return cuisines;
    if (endpoint.contains('restaurant') && endpoint.contains('details')) return restaurantDetails;
    if (endpoint.contains('restaurant') && endpoint.contains('product')) return restaurantProducts;
    if (endpoint.contains('restaurant')) return restaurantList;
    if (endpoint.contains('product')) return productList;
    if (endpoint.contains('banner')) return banners;
    if (endpoint.contains('advertisement')) return advertisements;
    if (endpoint.contains('campaign')) return campaigns;
    if (endpoint.contains('coupon')) return coupons;
    if (endpoint.contains('story')) return stories;
    if (endpoint.contains('order')) return orderHistory;
    if (endpoint.contains('address')) return addresses;
    if (endpoint.contains('profile')) return profile;
    if (endpoint.contains('favorite')) return favorites;
    if (endpoint.contains('review')) return reviews;
    if (endpoint.contains('search')) return searchResults;
    return defaultTTL;
  }
}
```

### Data NOT to Cache (Security/Real-time)
- Payment/wallet transactions
- Authentication tokens/OTPs
- Real-time order tracking (active orders)
- Chat messages
- Verification codes

---

## Implementation Phases

## Phase 1: Update Database Schema

### 1.1 Update Cache Response Table

**File**: `lib/data_source/cache_response.dart`

```dart
class CacheResponse extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get endPoint => text().unique()();
  TextColumn get header => text()();
  TextColumn get response => text()();
  DateTimeColumn get cachedAt => dateTime()();  // NEW
  IntColumn get ttlSeconds => integer()();      // NEW
}
```

### 1.2 Update Schema Version & Migration

```dart
@override
int get schemaVersion => 4;  // Increment from 3 to 4

@override
MigrationStrategy get migration => MigrationStrategy(
  onCreate: (Migrator m) async {
    await m.createAll();
  },
  onUpgrade: (Migrator m, int from, int to) async {
    if (from < 4) {
      // Drop and recreate table (it's just cache, safe to lose)
      await m.deleteTable('cache_response');
      await m.createTable(cacheResponse);
    }
  },
);
```

### 1.3 Add Cache Management Methods

```dart
/// Clear all cached data (for logout)
Future<int> clearAllCache() async {
  return await delete(cacheResponse).go();
}

/// Clear cache older than X days (automatic cleanup)
Future<int> clearOldCache({int days = 7}) async {
  final cutoff = DateTime.now().subtract(Duration(days: days));
  return await (delete(cacheResponse)
    ..where((t) => t.cachedAt.isSmallerThanValue(cutoff))
  ).go();
}

/// Clear specific endpoint cache (for manual refresh)
Future<int> clearCacheByEndpoint(String endpoint) async {
  return await (delete(cacheResponse)
    ..where((t) => t.endPoint.equals(endpoint))
  ).go();
}
```

---

## Phase 2: Create Cache Result Model

**File**: `lib/common/models/cache_result.dart` (create new)

```dart
/// Result of cache lookup with freshness metadata
class CacheResult {
  final String? data;
  final bool isExpired;
  final DateTime? cachedAt;

  CacheResult({
    this.data,
    this.isExpired = false,
    this.cachedAt,
  });

  factory CacheResult.empty() => CacheResult(
    data: null,
    isExpired: true,
    cachedAt: null,
  );

  bool get hasData => data != null;
  bool get isFresh => hasData && !isExpired;
  bool get isStale => hasData && isExpired;

  /// Age of cached data
  Duration? get age => cachedAt != null
    ? DateTime.now().difference(cachedAt!)
    : null;
}
```

---

## Phase 3: Update LocalClient

**File**: `lib/api/local_client.dart`

```dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:godelivery_user/common/enums/data_source_enum.dart';
import 'package:godelivery_user/common/models/cache_result.dart';
import 'package:godelivery_user/data_source/cache_response.dart';
import 'package:godelivery_user/helper/utilities/db_helper.dart';
import 'package:godelivery_user/util/app_constants.dart';
import 'package:drift/drift.dart' as drift;

class LocalClient {
  /// Store or retrieve cached data with TTL support
  ///
  /// For DataSourceEnum.client: Saves data to cache with TTL
  /// For DataSourceEnum.local: Retrieves data and checks freshness
  static Future<CacheResult> organize(
    DataSourceEnum source,
    String cacheId,
    String? responseBody,
    Map<String, String>? header, {
    int? ttlSeconds,
  }) async {
    SharedPreferences sharedPreferences = Get.find();

    try {
      switch (source) {
        case DataSourceEnum.client:
          // SAVE to cache
          final ttl = ttlSeconds ?? CacheTTL.getTTL(cacheId);
          final now = DateTime.now();

          if (GetPlatform.isWeb) {
            // Web: SharedPreferences with JSON
            final cacheData = {
              'response': responseBody,
              'cachedAt': now.toIso8601String(),
              'ttlSeconds': ttl,
            };
            await sharedPreferences.setString(cacheId, jsonEncode(cacheData));
          } else {
            // Mobile: Drift database
            await DbHelper.insertOrUpdate(
              endPoint: cacheId,
              response: responseBody ?? '',
              header: jsonEncode(header),
              cachedAt: now,
              ttlSeconds: ttl,
            );
          }

          return CacheResult(
            data: responseBody,
            isExpired: false,
            cachedAt: now,
          );

        case DataSourceEnum.local:
          // RETRIEVE from cache with freshness check
          if (GetPlatform.isWeb) {
            String? cached = sharedPreferences.getString(cacheId);
            if (cached != null) {
              final cacheData = jsonDecode(cached);
              final cachedAt = DateTime.parse(cacheData['cachedAt']);
              final ttl = cacheData['ttlSeconds'] as int;
              final age = DateTime.now().difference(cachedAt).inSeconds;

              return CacheResult(
                data: cacheData['response'],
                isExpired: age > ttl,
                cachedAt: cachedAt,
              );
            }
          } else {
            final database = AppDatabase();
            final cached = await database.getCacheResponseById(cacheId);
            if (cached != null) {
              final age = DateTime.now().difference(cached.cachedAt).inSeconds;

              return CacheResult(
                data: cached.response,
                isExpired: age > cached.ttlSeconds,
                cachedAt: cached.cachedAt,
              );
            }
          }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Cache error [$source] for $cacheId: $e');
      }
    }

    return CacheResult.empty();
  }

  /// Clear all cache (for logout)
  static Future<void> clearAllCache() async {
    try {
      if (GetPlatform.isWeb) {
        SharedPreferences sharedPreferences = Get.find();
        // Clear all cache keys (you may want to filter specific keys)
        await sharedPreferences.clear();
      } else {
        final database = AppDatabase();
        await database.clearAllCache();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing cache: $e');
      }
    }
  }
}
```

---

## Phase 4: Update DbHelper

**File**: `lib/helper/utilities/db_helper.dart`

```dart
import 'package:drift/drift.dart';
import 'package:godelivery_user/data_source/cache_response.dart';

class DbHelper {
  /// Insert or update cache entry with TTL
  static Future<void> insertOrUpdate({
    required String endPoint,
    required String response,
    required String header,
    required DateTime cachedAt,
    required int ttlSeconds,
  }) async {
    final database = AppDatabase();
    final existing = await database.getCacheResponseById(endPoint);

    if (existing != null) {
      // Update existing entry
      await database.updateCacheResponse(
        endPoint,
        CacheResponseCompanion(
          response: Value(response),
          header: Value(header),
          cachedAt: Value(cachedAt),
          ttlSeconds: Value(ttlSeconds),
        ),
      );
    } else {
      // Insert new entry
      await database.insertCacheResponse(
        CacheResponseCompanion.insert(
          endPoint: endPoint,
          response: response,
          header: header,
          cachedAt: cachedAt,
          ttlSeconds: ttlSeconds,
        ),
      );
    }
  }
}
```

---

## Phase 5: Update Repository Pattern

### 5.1 Standard Repository Pattern

**Template for all repositories:**

```dart
@override
Future<ModelType?> getData({
  required DataSourceEnum source,
  bool forceRefresh = false,  // NEW: for pull-to-refresh
}) async {
  String cacheId = AppConstants.endpointUri;

  // Force refresh bypasses cache entirely
  if (forceRefresh) {
    return _fetchFromApi(cacheId);
  }

  switch (source) {
    case DataSourceEnum.local:
      // Try cache first
      CacheResult cacheResult = await LocalClient.organize(
        DataSourceEnum.local,
        cacheId,
        null,
        null,
      );

      if (cacheResult.hasData) {
        ModelType model = ModelType.fromJson(jsonDecode(cacheResult.data!));

        // Hybrid strategy: if stale, fetch in background
        if (cacheResult.isExpired) {
          unawaited(_fetchFromApi(cacheId));
        }

        return model;
      }

      // No cache - fetch from API
      return _fetchFromApi(cacheId);

    case DataSourceEnum.client:
      return _fetchFromApi(cacheId);
  }
}

Future<ModelType?> _fetchFromApi(String cacheId) async {
  Response response = await apiClient.getData(AppConstants.endpointUri);
  if (response.statusCode == 200) {
    ModelType model = ModelType.fromJson(response.body);

    // Cache with auto-determined TTL
    await LocalClient.organize(
      DataSourceEnum.client,
      cacheId,
      jsonEncode(response.body),
      apiClient.getHeader(),
    );

    return model;
  }
  return null;
}
```

### 5.2 Repositories to Update

**Priority 1: Restaurant Module (fixes reload issue)**
1. `RestaurantRepository.getRestaurantDetails()` - Add caching
2. `RestaurantRepository.getRestaurantProductList()` - Add caching
3. `RestaurantRepository.getRestaurantRecommendedItemList()` - Add caching
4. `RestaurantRepository.getCartRestaurantSuggestedItemList()` - Add caching

**Priority 2: User Data**
5. `OrderRepository.getOrderList()` - Add caching
6. `FavouriteRepository.getFavoriteList()` - Add caching
7. `ProfileRepository.getUserInfo()` - Add caching
8. `CouponRepository.getCouponList()` - Add caching
9. `ReviewRepository.getReviewList()` - Already cached, add TTL

**Priority 3: Core Features**
10. `SearchRepository.getSearchResults()` - Add caching (not search history)
11. `CheckoutRepository` - Skip (checkout is transactional)
12. `CartRepository` - Skip (using SharedPreferences, different pattern)
13. `WalletRepository` - Skip (sensitive financial data)
14. `ChatRepository` - Skip (real-time messaging)
15. `DineInRepository` - Consider caching table/restaurant data only

---

## Phase 6: Controller Updates

### 6.1 Add Pull-to-Refresh Support

**Pattern for all controllers:**

```dart
Future<void> getData(bool reload, {bool forceRefresh = false}) async {
  if (reload || forceRefresh) {
    _data = null;
    update();
  }

  // Always try cache first (unless force refresh)
  DataType? data = await serviceInterface.getData(
    source: DataSourceEnum.local,
    forceRefresh: forceRefresh,
  );

  if (data != null) {
    _prepareData(data);
  }
}
```

### 6.2 Add App Launch Refresh

**File**: `lib/features/splash/controllers/splash_controller.dart` or main startup

```dart
/// Refresh critical data on app launch
Future<void> _refreshCriticalDataOnLaunch() async {
  // Run in background, don't block app launch
  Future.microtask(() async {
    // Refresh dynamic data
    Get.find<HomeController>().getBannerList(false, forceRefresh: true);
    Get.find<CategoryController>().getCategoryList(false, forceRefresh: true);
    Get.find<RestaurantController>().getRestaurantList(1, false, forceRefresh: true);

    // Static data only if very old (let TTL handle it)
  });
}
```

### 6.3 Add Logout Cache Clearing

**File**: `lib/features/auth/controllers/auth_controller.dart`

```dart
Future<void> logout() async {
  // Clear auth data
  await authServiceInterface.logout();

  // Clear all cached data
  await LocalClient.clearAllCache();

  // Reset controllers
  Get.find<RestaurantController>().makeEmptyRestaurant();
  Get.find<HomeController>().resetState();
  // ... reset other controllers

  // Navigate to login
  Get.offAllNamed(RouteHelper.getSignInRoute());
}
```

---

## Phase 7: UI Updates

### 7.1 Add Pull-to-Refresh Widgets

**Example**: `lib/features/restaurant/screens/restaurant_screen.dart`

```dart
Widget build(BuildContext context) {
  return RefreshIndicator(
    onRefresh: () async {
      // Force refresh - bypass cache
      await Get.find<RestaurantController>().getRestaurantDetails(
        Restaurant(id: widget.restaurant!.id),
        forceRefresh: true,
      );
      await Get.find<RestaurantController>().getRestaurantProductList(
        widget.restaurant!.id,
        1,
        'all',
        false,
        forceRefresh: true,
      );
    },
    child: CustomScrollView(
      controller: scrollController,
      slivers: [
        // ... existing content
      ],
    ),
  );
}
```

Apply to all main screens:
- Home screen
- Restaurant list
- Product list
- Order history
- Profile
- Favorites

---

## Phase 8: App Startup Cache Cleanup

**File**: `lib/main.dart`

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dependencies
  await init();

  // Cleanup old cache (run async, don't block startup)
  Future.microtask(() async {
    try {
      final database = AppDatabase();
      await database.clearOldCache(days: 7);
      debugPrint('Old cache cleared');
    } catch (e) {
      debugPrint('Cache cleanup error: $e');
    }
  });

  runApp(MyApp());
}
```

---

## Testing Strategy

### Unit Tests

```dart
// test/cache_test.dart
void main() {
  group('Cache TTL Tests', () {
    test('Fresh cache returns data', () async {
      // Save with 1 hour TTL
      await LocalClient.organize(
        DataSourceEnum.client,
        'test_endpoint',
        '{"data": "test"}',
        {},
        ttlSeconds: 3600,
      );

      // Retrieve immediately
      final result = await LocalClient.organize(
        DataSourceEnum.local,
        'test_endpoint',
        null,
        null,
      );

      expect(result.isFresh, true);
      expect(result.data, '{"data": "test"}');
    });

    test('Expired cache marked as stale', () async {
      // Save with 1 second TTL
      await LocalClient.organize(
        DataSourceEnum.client,
        'test_endpoint',
        '{"data": "test"}',
        {},
        ttlSeconds: 1,
      );

      // Wait 2 seconds
      await Future.delayed(Duration(seconds: 2));

      // Retrieve
      final result = await LocalClient.organize(
        DataSourceEnum.local,
        'test_endpoint',
        null,
        null,
      );

      expect(result.isStale, true);
      expect(result.hasData, true);  // Still has data, just expired
    });
  });
}
```

### Manual Testing Checklist

**TTL Behavior:**
- [ ] Set TTL to 10 seconds, verify data refetches after expiration
- [ ] Verify fresh cache shows instantly without API call
- [ ] Verify stale cache shows instantly but triggers background refresh

**Pull-to-Refresh:**
- [ ] Pull down on restaurant screen → should bypass cache
- [ ] Pull down on home screen → should force fresh banners
- [ ] Verify loading indicator shows during refresh
- [ ] Verify cache is updated after pull-to-refresh

**App Launch:**
- [ ] Close app completely
- [ ] Reopen → verify critical data refreshes in background
- [ ] Verify screens load instantly with cached data

**Logout:**
- [ ] Login as User A, browse restaurants
- [ ] Logout
- [ ] Login as User B → should NOT see User A's data

**Offline Mode:**
- [ ] Enable airplane mode
- [ ] Open app → should show cached data
- [ ] Verify graceful handling when cache is empty

**Cache Cleanup:**
- [ ] Set cleanup to 1 day
- [ ] Wait 2 days
- [ ] Verify old entries are deleted
- [ ] Verify database size doesn't grow unbounded

---

## Migration & Deployment

### Pre-Deployment
1. ✅ Backup current database schema
2. ✅ Test migration on dev devices (iOS, Android, Web)
3. ✅ Verify no data loss for critical data (cart, user settings)
4. ✅ Load test: insert 1000+ cache entries, verify performance

### Deployment Steps
1. Update schema version to 4
2. Deploy to TestFlight/Internal Testing
3. Monitor crash reports for migration issues
4. Gradual rollout: 10% → 50% → 100%
5. Monitor cache hit rates and API call reduction

### Rollback Plan
If critical issues arise:
1. Revert `schemaVersion` to 3
2. Revert schema changes (remove `cachedAt`, `ttlSeconds`)
3. Revert `LocalClient.organize()` signature
4. Users will rebuild cache on next app start (safe)

---

## Performance Metrics

### Expected Improvements
- **API calls**: 50-70% reduction (due to cache hits)
- **Screen load time**: 80% faster (instant cache display)
- **Data usage**: 40-60% reduction (fewer network requests)
- **Offline experience**: 90% of screens usable with cached data

### Monitoring
Add analytics events:
```dart
// Track cache performance
Analytics.logEvent('cache_hit', parameters: {
  'endpoint': cacheId,
  'age_seconds': cacheResult.age?.inSeconds,
  'is_fresh': cacheResult.isFresh,
});

Analytics.logEvent('cache_miss', parameters: {
  'endpoint': cacheId,
});
```

---

## Security Considerations

### Data NOT Cached
- ❌ Payment tokens, card numbers
- ❌ OTP codes, verification tokens
- ❌ Session tokens (except in SharedPreferences for auth)
- ❌ Active order tracking (real-time)
- ❌ Chat messages (use dedicated chat cache)

### Cache Isolation
- App-level caching (not user-scoped)
- Clear on logout (prevents data leakage)
- No sensitive data in cache keys
- Cache stored in app sandbox (not accessible to other apps)

---

## Benefits Summary

### User Experience
- ⚡ Instant screen loads (show cached data first)
- 📱 Better offline experience (graceful degradation)
- 🔄 Manual refresh control (pull-to-refresh)
- 🎯 Always fresh on app launch

### Technical
- 🚀 50-70% fewer API calls
- 💾 Automatic cache cleanup (no bloat)
- 🛠️ Configurable TTL per data type
- 🏗️ Consistent pattern across repositories

### Business
- 💰 Reduced server costs (fewer API calls)
- 📊 Better analytics (cache hit rates)
- 🌐 Improved global performance (especially poor networks)
- ⭐ Better app store ratings (faster, more reliable)

---

## Repository Implementation Checklist

### Completed (11 repositories with basic caching):
- [x] HomeRepository (banners, cashback)
- [x] AdvertisementRepository
- [x] RestaurantRepository (list endpoints only)
- [x] ProductRepository (popular products)
- [x] CampaignRepository
- [x] CuisineRepository
- [x] CategoryRepository
- [x] ReviewRepository
- [x] NotificationRepository
- [x] StoryRepository
- [x] AddressRepository

### To Update (add TTL + forceRefresh):
- [ ] HomeRepository - Add TTL support
- [ ] AdvertisementRepository - Add TTL support
- [ ] RestaurantRepository - Add TTL support
- [ ] ProductRepository - Add TTL support
- [ ] CampaignRepository - Add TTL support
- [ ] CuisineRepository - Add TTL support
- [ ] CategoryRepository - Add TTL support
- [ ] ReviewRepository - Add TTL support
- [ ] NotificationRepository - Add TTL support
- [ ] StoryRepository - Add TTL support
- [ ] AddressRepository - Add TTL support

### To Implement (new caching):
- [ ] RestaurantRepository.getRestaurantDetails()
- [ ] RestaurantRepository.getRestaurantProductList()
- [ ] RestaurantRepository.getRestaurantRecommendedItemList()
- [ ] RestaurantRepository.getCartRestaurantSuggestedItemList()
- [ ] OrderRepository.getOrderList()
- [ ] FavouriteRepository.getFavoriteList()
- [ ] ProfileRepository.getUserInfo()
- [ ] CouponRepository.getCouponList()
- [ ] SearchRepository.getSearchResults()

### Excluded (not caching):
- [x] CartRepository - Uses SharedPreferences (different pattern)
- [x] CheckoutRepository - Transactional, no caching needed
- [x] WalletRepository - Sensitive financial data
- [x] ChatRepository - Real-time messaging
- [x] AuthRepository - Security-sensitive
- [x] VerificationRepository - One-time codes
- [x] PaymentRepository - PCI compliance

---

## Timeline Estimate

- **Phase 1-4** (Infrastructure): 2-3 days
- **Phase 5** (Update 11 existing repos): 2-3 days
- **Phase 5** (Add caching to 9 new repos): 3-4 days
- **Phase 6-7** (Controllers & UI): 2-3 days
- **Phase 8** (Testing & Polish): 2-3 days

**Total**: ~11-16 days

---

## Questions & Decisions Log

**Q: Why not version-based cache invalidation?**
A: Adds complexity. Pull-to-refresh + app launch refresh covers 95% of scenarios. Backend updates propagate within TTL window (acceptable latency).

**Q: Why app-level caching instead of user-scoped?**
A: Simpler implementation. Clear cache on logout prevents data leakage. Most devices are single-user.

**Q: Why not cache cart data?**
A: Cart uses SharedPreferences for offline support, different pattern. Would need separate offline queue system.

**Q: TTL too long for dynamic content?**
A: Users can pull-to-refresh anytime. App launch refreshes critical data. TTL is for passive background behavior.

---

**End of Plan**

Ready for implementation! 🚀
