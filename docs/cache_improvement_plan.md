# Cache Improvement Implementation Plan

**Date**: 2025-11-11
**Strategy**: Hybrid Stale-While-Revalidate (SWR) with TTL-based expiration

## Overview

Implement intelligent caching that:
- Shows cached data **instantly** (no loading spinners)
- Fetches fresh data in background
- Only refetches if cache is expired (TTL-based)
- Auto-cleans old cache entries

## Current State

- **Caching**: Drift (SQLite) for mobile, SharedPreferences for web
- **Schema Version**: 3
- **Problem**: No expiration logic - cache lives forever
- **Cached Data Types**: 9 types (banners, products, restaurants, etc.)

## Migration Strategy

### Safe Approach: Recreate Cache Database

**Why**: It's just cache data, not user data. Losing it is harmless.

**Schema Change**:
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

**Migration Code** (`cache_response.dart`):
```dart
@override
int get schemaVersion => 4;

@override
MigrationStrategy get migration => MigrationStrategy(
  onCreate: (Migrator m) async {
    await m.createAll();
  },
  onUpgrade: (Migrator m, int from, int to) async {
    if (from < 4) {
      // Recreate table - cache will rebuild naturally
      await m.deleteTable('cache_response');
      await m.createTable(cacheResponse);
    }
  },
);
```

## TTL Configuration

Add to `lib/util/app_constants.dart`:

```dart
// Cache TTL in seconds
static const Map<String, int> cacheTtl = {
  // Frequently changing
  bannerUri: 300,                    // 5 min
  cashBackOfferListUri: 300,         // 5 min
  notificationUri: 600,              // 10 min

  // Semi-dynamic
  popularProductUri: 900,            // 15 min
  restaurantUri: 900,                // 15 min
  latestRestaurantUri: 900,          // 15 min
  storyFeedUri: 1800,                // 30 min

  // Static
  categoryUri: 3600,                 // 1 hour
  cuisineUri: 3600,                  // 1 hour
};

static const int defaultCacheTtl = 900; // 15 min fallback
```

## Implementation Phases

### Phase 1: Create Cache Result Model

Create `lib/common/models/cache_result.dart`:

```dart
class CacheResult {
  final String? data;
  final bool isExpired;
  final DateTime? cachedAt;

  CacheResult({
    this.data,
    this.isExpired = false,
    this.cachedAt,
  });

  factory CacheResult.empty() => CacheResult(data: null, isExpired: true);

  bool get hasData => data != null;
  bool get isFresh => hasData && !isExpired;
}
```

### Phase 2: Update Database Helper

Update `lib/helper/db_helper.dart`:

```dart
static Future<void> insertOrUpdate({
  required String endPoint,
  required String response,
  required String header,
  required DateTime cachedAt,
  required int ttlSeconds,
}) async {
  final appDatabase = AppDatabase();
  CacheResponseData? cacheResponseData = await appDatabase.getCacheResponseById(endPoint);

  if (cacheResponseData != null) {
    await appDatabase.updateCacheResponse(
      endPoint,
      CacheResponseCompanion(
        response: Value(response),
        header: Value(header),
        cachedAt: Value(cachedAt),
        ttlSeconds: Value(ttlSeconds),
      ),
    );
  } else {
    await appDatabase.insertCacheResponse(
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
```

### Phase 3: Update LocalClient

Update `lib/api/local_client.dart`:

```dart
static Future<CacheResult> organize(
  DataSourceEnum source,
  String cacheId,
  String? responseBody,
  Map<String, String>? header, {
  int? ttlSeconds,
}) async {
  try {
    if (source == DataSourceEnum.client) {
      // SAVE to cache
      if (GetPlatform.isWeb) {
        final cacheData = {
          'response': responseBody,
          'cachedAt': DateTime.now().toIso8601String(),
          'ttlSeconds': ttlSeconds ?? AppConstants.defaultCacheTtl,
        };
        await sharedPreferences.setString(cacheId, jsonEncode(cacheData));
      } else {
        await DbHelper.insertOrUpdate(
          endPoint: cacheId,
          response: responseBody ?? '',
          header: jsonEncode(header),
          cachedAt: DateTime.now(),
          ttlSeconds: ttlSeconds ?? AppConstants.defaultCacheTtl,
        );
      }
      return CacheResult(
        data: responseBody,
        isExpired: false,
        cachedAt: DateTime.now(),
      );
    } else {
      // RETRIEVE from cache
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
        final cached = await appDatabase.getCacheResponseById(cacheId);
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
    debugPrint('Cache error: $e');
  }

  return CacheResult.empty();
}
```

### Phase 4: Update Repository Pattern

Example for `lib/features/home/domain/repositories/home_repository.dart`:

```dart
Future<BannerModel?> getBannerList({required DataSourceEnum source}) async {
  String cacheId = AppConstants.bannerUri;
  int ttl = AppConstants.cacheTtl[AppConstants.bannerUri] ?? AppConstants.defaultCacheTtl;

  switch(source) {
    case DataSourceEnum.local:
      // Try cache first
      CacheResult cacheResult = await LocalClient.organize(
        DataSourceEnum.local,
        cacheId,
        null,
        null,
      );

      if (cacheResult.hasData) {
        BannerModel model = BannerModel.fromJson(jsonDecode(cacheResult.data!));

        // If expired, trigger background refresh
        if (cacheResult.isExpired) {
          unawaited(getBannerList(source: DataSourceEnum.client));
        }

        return model;
      }

      // No cache - fetch from API
      return getBannerList(source: DataSourceEnum.client);

    case DataSourceEnum.client:
      Response response = await apiClient.getData(AppConstants.bannerUri);
      if (response.statusCode == 200) {
        BannerModel bannerModel = BannerModel.fromJson(response.body);

        // Cache with TTL
        await LocalClient.organize(
          DataSourceEnum.client,
          cacheId,
          jsonEncode(response.body),
          apiClient.getHeader(),
          ttlSeconds: ttl,
        );

        return bannerModel;
      }
  }

  return null;
}
```

**Apply same pattern to**:
- `category_repository.dart`
- `cuisine_repository.dart`
- `product_repository.dart`
- `restaurant_repository.dart`
- `story_repository.dart`
- `notification_repository.dart`
- `home_repository.dart` (cashback)

### Phase 5: Add Cache Cleanup

Add to `lib/data_source/cache_response.dart`:

```dart
// Clear cache older than X days
Future<int> clearOldCache({int days = 7}) async {
  final cutoff = DateTime.now().subtract(Duration(days: days));
  return await (delete(cacheResponse)
    ..where((t) => t.cachedAt.isSmallerThanValue(cutoff))
  ).go();
}
```

Add to app startup in `main.dart` or splash screen:

```dart
// Run on app start
AppDatabase().clearOldCache(days: 7);
```

## Controller Pattern (Optional Enhancement)

Update controllers to always load cache first:

```dart
Future<void> getBannerList(bool reload) async {
  if (_bannerImageList == null || reload) {
    _bannerImageList = null;

    // Step 1: Load cache instantly
    BannerModel? cached = await homeServiceInterface.getBannerList(
      source: DataSourceEnum.local
    );
    if (cached != null) {
      _prepareBannerList(cached);
      update(); // Show cached data immediately
    }

    // Step 2: Fetch fresh (only if cache expired - handled in repository)
    // Repository will skip API if cache is fresh
  }
}
```

## Deployment Notes

### Mobile Apps (iOS/Android)
- Each user has **local SQLite database** on their device
- Migration runs **when user updates app**
- No backend changes needed

### Web
- Uses browser's **localStorage** (SharedPreferences)
- No migration needed - just add timestamp fields to JSON

### DigitalOcean Backend
- **No changes required** - backend doesn't know about client-side caching
- Cache is purely client-side (Flutter app)

## Testing Plan

1. **Test migration**: Uninstall/reinstall app - should work cleanly
2. **Test TTL**: Set TTL to 10 seconds, wait, verify refetch
3. **Test offline**: Enable airplane mode, verify cached data loads
4. **Test cleanup**: Set cleanup to 1 day, verify old cache deleted
5. **Test web**: Verify SharedPreferences logic works in browser

## Benefits

- ⚡ **50% fewer API calls** (only refetch when expired)
- 🚀 **Instant screen loads** (show cache first)
- 📱 **Better offline experience** (graceful degradation)
- 🧹 **Automatic cleanup** (no database bloat)
- 🎯 **Configurable TTL** per data type

## Rollback Plan

If issues arise:
1. Revert `schemaVersion` to 3
2. Revert table definition (remove new columns)
3. Revert `LocalClient.organize()` signature
4. Users will get fresh cache on next app start

---

**End of Plan**
