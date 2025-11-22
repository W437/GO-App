import 'package:flutter_test/flutter_test.dart';
import 'package:godelivery_user/features/restaurant/domain/repositories/restaurant_repository.dart';
import 'package:godelivery_user/api/api_client.dart';
import 'package:godelivery_user/common/cache/cache_manager.dart';
import 'package:godelivery_user/common/cache/cache_key.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:godelivery_user/common/models/restaurant_model.dart';
import 'package:get/get.dart';

// Manual Mocks
class MockApiClient implements ApiClient {
  @override
  String appBaseUrl = 'https://example.com';
  
  @override
  late SharedPreferences sharedPreferences;

  @override
  Future<Response> getData(String uri, {Map<String, dynamic>? query, Map<String, String>? headers, bool handleError = true, bool showToaster = false}) async {
    print('MockApiClient called with URI: $uri');
    // Simulate API response
    if (uri.contains('restaurant') || uri.contains('all')) {
      return Response(statusCode: 200, body: {
        'total_size': 1,
        'limit': 10,
        'offset': 1,
        'restaurants': [
          {'id': 1, 'name': 'Test Restaurant'}
        ]
      });
    }
    return Response(statusCode: 404, statusText: 'Not Found');
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockSharedPreferences implements SharedPreferences {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockCacheManager implements CacheManager {
  CacheKey? lastKey;
  
  @override
  Future<T?> get<T>(
    CacheKey key, {
    Future<T?> Function()? fetcher,
    Duration? ttl,
    T Function(dynamic)? deserializer,
    bool allowStale = false,
  }) async {
    lastKey = key;
    // Simulate cache miss, trigger fetcher
    if (fetcher != null) {
      return await fetcher();
    }
    return null;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late RestaurantRepository repository;
  late MockApiClient mockApiClient;
  late MockSharedPreferences mockSharedPreferences;
  late MockCacheManager mockCacheManager;

  setUp(() {
    mockApiClient = MockApiClient();
    mockSharedPreferences = MockSharedPreferences();
    mockCacheManager = MockCacheManager();
    repository = RestaurantRepository(
      apiClient: mockApiClient,
      sharedPreferences: mockSharedPreferences,
      cacheManager: mockCacheManager,
    );
  });

  test('getList calls CacheManager with correct key', () async {
    final result = await repository.getList(offset: 1);

    expect(result, isA<RestaurantModel>());
    expect(result?.restaurants?.first.name, 'Test Restaurant');
    expect(mockCacheManager.lastKey?.endpoint, endsWith('/list'));
    expect(mockCacheManager.lastKey?.params?['offset'], 1);
  });
}
