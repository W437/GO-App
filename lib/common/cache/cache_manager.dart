import 'dart:convert';
import 'package:godelivery_user/common/cache/cache_config.dart';
import 'package:godelivery_user/common/cache/cache_entry.dart';
import 'package:godelivery_user/common/cache/cache_key.dart';
import 'package:godelivery_user/common/cache/enums/cache_tier.dart';
import 'package:godelivery_user/common/cache/services/disk_cache_service.dart';
import 'package:godelivery_user/common/cache/services/memory_cache_service.dart';

class CacheManager {
  final MemoryCacheService _memoryCache;
  final DiskCacheService _diskCache;

  CacheManager({
    MemoryCacheService? memoryCache,
    DiskCacheService? diskCache,
  })  : _memoryCache = memoryCache ?? MemoryCacheService(),
        _diskCache = diskCache ?? DiskCacheService();

  /// Get data from cache, checking tiers in order: Memory -> Disk
  /// If [fetcher] is provided and cache is missed/expired, it fetches fresh data,
  /// caches it, and returns it.
  Future<T?> get<T>(
    CacheKey key, {
    Future<T?> Function()? fetcher,
    Duration? ttl,
    T Function(dynamic)? deserializer,
    bool allowStale = false,
  }) async {
    final String id = key.id;

    // 1. Check Memory
    if (CacheConfig.enableMemoryCache) {
      final memoryData = _memoryCache.get<T>(id);
      if (memoryData != null) {
        return memoryData;
      }
    }

    // 2. Check Disk
    if (CacheConfig.enableDiskCache) {
      final diskEntry = await _diskCache.get(id);
      if (diskEntry != null) {
        // Deserialize if needed (Disk stores Strings)
        T data;
        if (deserializer != null && diskEntry.data is String) {
          // Assuming disk stores JSON string
          // You might need jsonDecode here if deserializer expects Map
          // But let's assume deserializer handles the raw type or we decode it
          // For simplicity, let's assume T is String or we decode
          // Ideally we should store type info or rely on deserializer
           try {
             // If T is not String, we might need to decode.
             // But for now, let's pass the data as is to deserializer if provided
             data = deserializer(diskEntry.data);
           } catch (e) {
             // Deserialization failed
             return null;
           }
        } else {
          data = diskEntry.data as T;
        }

        // Promote to Memory
        if (CacheConfig.enableMemoryCache) {
          _memoryCache.set(id, data, diskEntry.ttl);
        }
        return data;
      }
    }

    // 3. Fetch from Network (if fetcher provided)
    if (fetcher != null) {
      try {
        final data = await fetcher();
        if (data != null) {
          await set(key, data, ttl: ttl);
        }
        return data;
      } catch (e) {
        // If fetch fails and allowStale is true, we might want to return expired cache
        // But we already checked cache and returned if valid.
        // If we are here, cache is missing or expired.
        // Implementing "stale-while-revalidate" or "return stale on error" requires more logic
        // For now, just rethrow or return null
        rethrow;
      }
    }

    return null;
  }

  Future<void> set<T>(CacheKey key, T data, {Duration? ttl, String Function(T)? serializer}) async {
    final duration = ttl ?? CacheConfig.getTTL(key.endpoint);
    final String id = key.id;

    // Save to Memory (always succeeds)
    if (CacheConfig.enableMemoryCache) {
      try {
        _memoryCache.set(id, data, duration);
      } catch (e) {
        print('⚠️ [CACHE MANAGER] Memory cache set failed for $id: $e');
      }
    }

    // Save to Disk (may fail, don't let it crash the app)
    if (CacheConfig.enableDiskCache) {
      try {
        // We need to serialize T to String for Disk
        String serializedData;
        if (data is String) {
          serializedData = data;
        } else if (serializer != null) {
          // Use provided serializer
          serializedData = serializer(data);
        } else {
          // Try JSON encoding for Lists and Maps
          try {
            serializedData = jsonEncode(data);
          } catch (e) {
            print('⚠️ [CACHE MANAGER] Cannot JSON encode data for $id, skipping disk cache');
            return; // Skip disk cache if we can't serialize
          }
        }

        await _diskCache.set(id, serializedData, duration);
      } catch (e) {
        print('⚠️ [CACHE MANAGER] Disk cache set failed for $id: $e');
        // Continue even if disk cache fails - data is already in memory
      }
    }
  }

  Future<void> invalidate(CacheKey key) async {
    final id = key.id;
    _memoryCache.invalidate(id);
    await _diskCache.invalidate(id);
  }

  Future<void> invalidatePattern(String pattern) async {
    _memoryCache.invalidatePattern(pattern);
    await _diskCache.invalidatePattern(pattern);
  }

  Future<void> clear() async {
    _memoryCache.clear();
    await _diskCache.clear();
  }
}
