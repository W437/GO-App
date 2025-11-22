import 'package:godelivery_user/common/cache/enums/cache_eviction_policy.dart';

class CacheConfig {
  // TTL Definitions
  static const Duration restaurantTTL = Duration(hours: 4);
  static const Duration productTTL = Duration(hours: 2);
  static const Duration categoryTTL = Duration(days: 7);
  static const Duration userProfileTTL = Duration(minutes: 30);
  static const Duration addressTTL = Duration(hours: 24);
  static const Duration bannerTTL = Duration(hours: 6);
  static const Duration storyTTL = Duration(hours: 1);
  static const Duration notificationTTL = Duration(minutes: 15);
  static const Duration defaultTTL = Duration(hours: 1);

  // Size Limits (in Bytes)
  static const int memoryCacheSize = 50 * 1024 * 1024; // 50 MB
  static const int diskCacheSize = 500 * 1024 * 1024; // 500 MB

  // Eviction Policy
  static const CacheEvictionPolicy evictionPolicy = CacheEvictionPolicy.lru;

  // Cache Tiers Enabled
  static const bool enableMemoryCache = true;
  static const bool enableDiskCache = true;

  // Get TTL by endpoint pattern
  static Duration getTTL(String endpoint) {
    if (endpoint.contains('/restaurants')) return restaurantTTL;
    if (endpoint.contains('/products')) return productTTL;
    if (endpoint.contains('/categories')) return categoryTTL;
    if (endpoint.contains('/customer/profile')) return userProfileTTL;
    if (endpoint.contains('/customer/address')) return addressTTL;
    if (endpoint.contains('/banners')) return bannerTTL;
    if (endpoint.contains('/stories')) return storyTTL;
    if (endpoint.contains('/notifications')) return notificationTTL;
    return defaultTTL;
  }
}
