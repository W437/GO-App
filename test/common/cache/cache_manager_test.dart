import 'package:flutter_test/flutter_test.dart';
import 'package:godelivery_user/common/cache/cache_manager.dart';
import 'package:godelivery_user/common/cache/cache_key.dart';
import 'package:godelivery_user/common/cache/services/memory_cache_service.dart';
import 'package:godelivery_user/common/cache/services/disk_cache_service.dart';
import 'package:godelivery_user/common/cache/cache_entry.dart';

// Manual mocks
class MockMemoryCacheService implements MemoryCacheService {
  final Map<String, CacheEntry> _store = {};

  @override
  int get maxSizeBytes => 1000;

  @override
  T? get<T>(String key) {
    if (_store.containsKey(key)) {
      return _store[key]!.data as T;
    }
    return null;
  }

  @override
  void set<T>(String key, T data, Duration ttl, {int? sizeBytes}) {
    _store[key] = CacheEntry(data: data, ttl: ttl);
  }
  
  @override
  void invalidate(String key) {
    _store.remove(key);
  }

  @override
  void invalidatePattern(String pattern) {
    _store.removeWhere((key, value) => key.startsWith(pattern.replaceAll('*', '')));
  }

  @override
  void clear() {
    _store.clear();
  }
}

class MockDiskCacheService implements DiskCacheService {
  final Map<String, CacheEntry<String>> _store = {};

  @override
  int get maxSizeBytes => 1000;

  @override
  Future<CacheEntry<String>?> get(String key) async {
    return _store[key];
  }

  @override
  Future<void> set(String key, String data, Duration ttl, {String? metadata}) async {
    _store[key] = CacheEntry(data: data, ttl: ttl);
  }
  
  @override
  Future<void> invalidate(String key) async {
    _store.remove(key);
  }

  @override
  Future<void> invalidatePattern(String pattern) async {
    _store.removeWhere((key, value) => key.startsWith(pattern.replaceAll('*', '')));
  }

  @override
  Future<void> clear() async {
    _store.clear();
  }
}

void main() {
  late CacheManager cacheManager;
  late MockMemoryCacheService mockMemoryCache;
  late MockDiskCacheService mockDiskCache;

  setUp(() {
    mockMemoryCache = MockMemoryCacheService();
    mockDiskCache = MockDiskCacheService();
    cacheManager = CacheManager(
      memoryCache: mockMemoryCache,
      diskCache: mockDiskCache,
    );
  });

  test('get returns data from memory if available', () async {
    final key = CacheKey(endpoint: '/test');
    mockMemoryCache.set(key.id, 'memory_data', Duration(minutes: 1));

    final result = await cacheManager.get<String>(key);

    expect(result, 'memory_data');
  });

  test('get returns data from disk if memory miss', () async {
    final key = CacheKey(endpoint: '/test');
    await mockDiskCache.set(key.id, 'disk_data', Duration(minutes: 1));

    final result = await cacheManager.get<String>(key);

    expect(result, 'disk_data');
  });

  test('get fetches from network if cache miss', () async {
    final key = CacheKey(endpoint: '/test');
    
    final result = await cacheManager.get<String>(
      key,
      fetcher: () async => 'network_data',
    );

    expect(result, 'network_data');
    // Should be cached in memory and disk
    expect(mockMemoryCache.get(key.id), 'network_data');
    // Mock disk check (async in real life, sync in mock map)
    final diskEntry = await mockDiskCache.get(key.id);
    expect(diskEntry?.data, 'network_data');
  });
}
