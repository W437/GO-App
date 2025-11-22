import 'package:flutter_test/flutter_test.dart';
import 'package:godelivery_user/features/home/domain/repositories/home_repository.dart';
import 'package:godelivery_user/api/api_client.dart';
import 'package:godelivery_user/common/cache/cache_manager.dart';
import 'package:godelivery_user/common/cache/cache_key.dart';
import 'package:godelivery_user/common/enums/data_source_enum.dart';
import 'package:godelivery_user/features/home/domain/models/banner_model.dart';
import 'package:godelivery_user/features/home/domain/models/cashback_model.dart';
import 'package:get/get.dart';

// Manual Mocks
class MockApiClient implements ApiClient {
  @override
  String appBaseUrl = 'https://example.com';
  
  @override
  Future<Response> getData(String uri, {Map<String, dynamic>? query, Map<String, String>? headers, bool handleError = true, bool showToaster = false}) async {
    print('MockApiClient called with URI: $uri');
    if (uri.contains('banner')) {
      return Response(statusCode: 200, body: {
        'campaigns': [],
        'banners': []
      });
    } else if (uri.contains('cashback')) {
      return Response(statusCode: 200, body: [
        {'id': 1, 'title': 'Cashback Offer'}
      ]);
    }
    return Response(statusCode: 404, statusText: 'Not Found');
  }

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
    if (fetcher != null) {
      return await fetcher();
    }
    return null;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late HomeRepository repository;
  late MockApiClient mockApiClient;
  late MockCacheManager mockCacheManager;

  setUp(() {
    mockApiClient = MockApiClient();
    mockCacheManager = MockCacheManager();
    repository = HomeRepository(
      apiClient: mockApiClient,
      cacheManager: mockCacheManager,
    );
  });

  test('getList (banners) calls CacheManager with correct key', () async {
    final result = await repository.getList(source: DataSourceEnum.client);

    expect(result, isA<BannerModel>());
    expect(mockCacheManager.lastKey?.endpoint, contains('banner'));
  });

  test('getCashBackOfferList calls CacheManager with correct key', () async {
    final result = await repository.getCashBackOfferList(source: DataSourceEnum.client);

    expect(result, isA<List<CashBackModel>>());
    expect(result?.first.title, 'Cashback Offer');
    expect(mockCacheManager.lastKey?.endpoint, contains('cashback'));
  });
}
