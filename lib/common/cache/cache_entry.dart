class CacheEntry<T> {
  final T data;
  final DateTime expiresAt;
  final DateTime createdAt;
  int sizeBytes;

  CacheEntry({
    required this.data,
    required Duration ttl,
    this.sizeBytes = 0,
  })  : createdAt = DateTime.now(),
        expiresAt = DateTime.now().add(ttl);

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  
  Duration get ttl => expiresAt.difference(DateTime.now());
}
