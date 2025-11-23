import 'package:godelivery_user/features/splash/domain/models/config_model.dart';
import 'package:godelivery_user/features/splash/domain/services/splash_service_interface.dart';

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
    final response = await _service.getConfigData();

    if (response.statusCode == 200) {
      return _service.prepareConfigData(response);
    }
    return null;
  }

  /// Fetch config (simplified - no more caching)
  Future<ConfigModel?> fetchConfigCached() async {
    return await fetchConfig();
  }

  /// Check if config exists (always returns false now since no cache)
  Future<bool> hasConfigCached() async {
    return false;
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
