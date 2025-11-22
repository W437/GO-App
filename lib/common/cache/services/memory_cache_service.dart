import 'dart:collection';
import 'package:godelivery_user/common/cache/cache_entry.dart';
import 'package:godelivery_user/common/cache/cache_config.dart';

class MemoryCacheService {
  final Map<String, CacheEntry> _cache = {};
  final int maxSizeBytes;
  final LinkedHashMap<String, DateTime> _accessOrder = LinkedHashMap();
  int _currentSizeBytes = 0;

  MemoryCacheService({this.maxSizeBytes = CacheConfig.memoryCacheSize});

  T? get<T>(String key) {
    if (!_cache.containsKey(key)) return null;

    final entry = _cache[key]!;
    if (entry.isExpired) {
      _cache.remove(key);
      _accessOrder.remove(key);
      _currentSizeBytes -= entry.sizeBytes;
      return null;
    }

    // Update LRU order
    _accessOrder.remove(key);
    _accessOrder[key] = DateTime.now();

    return entry.data as T;
  }

  void set<T>(String key, T data, Duration ttl, {int? sizeBytes}) {
    // Calculate size if not provided (rough estimation for strings/json)
    final entrySize = sizeBytes ?? _estimateSize(data);
    
    final entry = CacheEntry(
      data: data,
      ttl: ttl,
      sizeBytes: entrySize,
    );

    // Evict if size limit reached
    while (_currentSizeBytes + entrySize > maxSizeBytes && _cache.isNotEmpty) {
      _evictLRU();
    }

    // If key exists, subtract old size
    if (_cache.containsKey(key)) {
      _currentSizeBytes -= _cache[key]!.sizeBytes;
    }

    _cache[key] = entry;
    _currentSizeBytes += entrySize;
    _accessOrder.remove(key);
    _accessOrder[key] = DateTime.now();
  }

  void invalidate(String key) {
    if (_cache.containsKey(key)) {
      _currentSizeBytes -= _cache[key]!.sizeBytes;
      _cache.remove(key);
      _accessOrder.remove(key);
    }
  }

  void invalidatePattern(String pattern) {
    // Simple regex or wildcard matching
    // Assuming pattern is a regex string or simple prefix
    final regex = RegExp(pattern.replaceAll('*', '.*'));
    final keysToRemove = _cache.keys.where((k) => regex.hasMatch(k)).toList();
    
    for (var key in keysToRemove) {
      invalidate(key);
    }
  }

  void clear() {
    _cache.clear();
    _accessOrder.clear();
    _currentSizeBytes = 0;
  }

  void _evictLRU() {
    if (_accessOrder.isEmpty) return;
    final oldestKey = _accessOrder.keys.first;
    invalidate(oldestKey);
  }

  int _estimateSize(dynamic data) {
    if (data is String) return data.length;
    // Add more type estimations if needed
    return 1024; // Default fallback
  }
}
