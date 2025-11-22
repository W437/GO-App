import 'dart:convert';
import 'package:crypto/crypto.dart';

class CacheKey {
  final String endpoint;
  final Map<String, dynamic>? params;
  final int schemaVersion;

  CacheKey({
    required this.endpoint,
    this.params,
    this.schemaVersion = 1,
  });

  String get id => _generateId();

  String _generateId() {
    final paramHash = params != null ? _hashParams(params!) : '';
    // Sanitize endpoint to remove leading/trailing slashes for consistency if needed,
    // but for now we assume the caller provides a clean endpoint.
    return '${endpoint}_v${schemaVersion}_$paramHash';
  }

  String _hashParams(Map<String, dynamic> params) {
    // Sort keys to ensure consistent hash regardless of key order
    final sortedKeys = params.keys.toList()..sort();
    final sortedMap = {for (var k in sortedKeys) k: params[k]};
    final jsonString = jsonEncode(sortedMap);
    final bytes = utf8.encode(jsonString);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16); // Short hash is usually enough
  }

  @override
  String toString() => id;
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CacheKey && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
