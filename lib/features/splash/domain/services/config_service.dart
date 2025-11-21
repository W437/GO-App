import 'package:godelivery_user/features/splash/domain/models/config_model.dart';
import 'package:godelivery_user/features/splash/domain/services/splash_service_interface.dart';
import 'package:godelivery_user/common/enums/data_source_enum.dart';

/// Pure config data fetching service with no navigation side effects
///
/// This service is responsible ONLY for fetching and processing configuration data.
/// It does NOT handle navigation, which is the responsibility of AppNavigator.
///
/// Following the Single Responsibility Principle:
/// - ✅ Fetch config from API or cache
/// - ✅ Process and parse config data
/// - ❌ NO navigation logic
/// - ❌ NO side effects
class ConfigService {
  final SplashServiceInterface _service;

  ConfigService(this._service);

  /// Fetch config from API (always fresh)
  /// Returns null if fetch fails or status != 200
  Future<ConfigModel?> fetchConfig() async {
    print('🔍 [ConfigService] fetchConfig() called');
    final response = await _service.getConfigData(
      source: DataSourceEnum.client,
    );

    print('🔍 [ConfigService] API response - status: ${response.statusCode}, body: ${response.body != null ? "present" : "null"}');

    if (response.statusCode == 200) {
      final config = _service.prepareConfigData(response);
      print('🔍 [ConfigService] Config parsed - success: ${config != null}');
      return config;
    }
    print('❌ [ConfigService] API call failed - status: ${response.statusCode}, statusText: ${response.statusText}');
    return null;
  }

  /// Fetch config with cache-first strategy
  ///
  /// Strategy:
  /// 1. Try to get from cache first (instant response)
  /// 2. If cache exists, return it and refresh in background
  /// 3. If no cache, fetch from API and wait
  ///
  /// This provides instant app startup while keeping data fresh.
  Future<ConfigModel?> fetchConfigCached() async {
    print('🔍 [ConfigService] fetchConfigCached() called');

    // Try cache first
    final cacheResponse = await _service.getConfigData(
      source: DataSourceEnum.local,
    );

    print('🔍 [ConfigService] Cache response - status: ${cacheResponse.statusCode}');

    if (cacheResponse.statusCode == 200) {
      final cachedConfig = _service.prepareConfigData(cacheResponse);
      print('✅ [ConfigService] Using cached config, refreshing in background');

      // Refresh in background (fire and forget - no await)
      // This keeps cache fresh for next app launch
      fetchConfig();

      return cachedConfig;
    }

    // No cache - fetch from API
    print('⚠️ [ConfigService] No cache found, fetching from API');
    return await fetchConfig();
  }

  /// Check if config exists in cache
  /// Useful for determining if we need to show loading states
  Future<bool> hasConfigCached() async {
    final response = await _service.getConfigData(
      source: DataSourceEnum.local,
    );
    return response.statusCode == 200;
  }

  /// Fetch config and check for connection errors
  /// Returns a tuple-like result with config and connection status
  Future<ConfigFetchResult> fetchConfigWithConnectionCheck() async {
    try {
      final config = await fetchConfig();
      if (config != null) {
        return ConfigFetchResult(
          config: config,
          hasConnection: true,
          success: true,
        );
      } else {
        return ConfigFetchResult(
          config: null,
          hasConnection: false,
          success: false,
        );
      }
    } catch (e) {
      return ConfigFetchResult(
        config: null,
        hasConnection: false,
        success: false,
      );
    }
  }
}

/// Result object for config fetch operations
/// Contains config data and metadata about the fetch operation
class ConfigFetchResult {
  final ConfigModel? config;
  final bool hasConnection;
  final bool success;

  ConfigFetchResult({
    required this.config,
    required this.hasConnection,
    required this.success,
  });
}
