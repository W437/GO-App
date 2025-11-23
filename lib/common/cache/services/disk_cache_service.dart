import 'package:drift/drift.dart';
import 'package:godelivery_user/common/cache/cache_config.dart';
import 'package:godelivery_user/common/cache/cache_entry.dart';
import 'package:godelivery_user/data_source/cache_response.dart';
import 'package:godelivery_user/helper/utilities/db_helper.dart';

class DiskCacheService {
  final AppDatabase _db;
  final int maxSizeBytes;

  DiskCacheService({
    AppDatabase? db,
    this.maxSizeBytes = CacheConfig.diskCacheSize,
  }) : _db = db ?? database;

  Future<CacheEntry<String>?> get(String key) async {
    final record = await _db.getCacheResponseByKey(key);
    if (record == null) return null;

    // Check expiration
    if (record.expiresAt != null && DateTime.now().isAfter(record.expiresAt!)) {
      await invalidate(key);
      return null;
    }

    // Update last accessed
    await _db.updateCacheResponseByKey(
      key,
      CacheResponseCompanion(
        lastAccessedAt: Value(DateTime.now()),
      ),
    );

    return CacheEntry(
      data: record.response,
      ttl: record.expiresAt != null
          ? record.expiresAt!.difference(DateTime.now())
          : Duration.zero,
      sizeBytes: record.sizeBytes,
    );
  }

  Future<void> set(String key, String data, Duration ttl, {String? metadata}) async {
    final size = data.length; // Approximate size in bytes for string
    final expiresAt = DateTime.now().add(ttl);

    try {
      // Delete existing entry first to avoid UNIQUE constraint conflicts
      // (table has both endPoint and cacheKey as UNIQUE)
      await invalidate(key);

      await _db.into(_db.cacheResponse).insert(
        CacheResponseCompanion(
          cacheKey: Value(key),
          endPoint: Value(key), // Use key as endpoint for legacy compatibility/uniqueness if needed
          response: Value(data),
          header: const Value(''), // Default empty header
          metadata: Value(metadata),
          expiresAt: Value(expiresAt),
          lastAccessedAt: Value(DateTime.now()),
          sizeBytes: Value(size),
          schemaVersion: const Value(1),
          createdAt: Value(DateTime.now()),
        ),
      );
    } catch (e) {
      // Log error but don't crash - cache failures shouldn't break the app
      print('⚠️ [DISK CACHE] Failed to cache $key: $e');
    }

    // Check size limit and evict if needed (simple check, can be optimized)
    // Ideally run this periodically or on background, not every set
    // await _evictIfNecessary();
  }

  Future<void> invalidate(String key) async {
    await (_db.delete(_db.cacheResponse)..where((tbl) => tbl.cacheKey.equals(key))).go();
  }

  Future<void> invalidatePattern(String pattern) async {
    // Drift doesn't support regex delete easily, so we might need to fetch keys or use LIKE
    // For now, support simple prefix matching with LIKE
    final likePattern = pattern.replaceAll('*', '%');
    await (_db.delete(_db.cacheResponse)..where((tbl) => tbl.cacheKey.like(likePattern))).go();
  }

  Future<void> clear() async {
    await _db.clearCacheResponses();
  }
}
