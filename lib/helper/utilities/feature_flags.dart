/// Feature flags for controlling gradual rollout of new features
/// Phase 1: Cart Flow Redesign
class FeatureFlags {
  // ============================================================================
  // PHASE 1: Foundation & Data Models
  // ============================================================================

  /// Enable multi-restaurant cart support
  /// When true: Users can add items from different restaurants to cart simultaneously
  /// When false: Traditional single-restaurant cart behavior (with warning dialog)
  static bool get enableMultiRestaurantCarts => _getFlag(
        'ENABLE_MULTI_RESTAURANT_CARTS',
        defaultValue: false,
      );

  // ============================================================================
  // PHASE 2: Screen B - Order Details
  // ============================================================================

  /// Enable standalone Order Details screen
  /// When true: Navigates to separate OrderDetailsScreen
  /// When false: Shows cart details inline (current behavior)
  static bool get enableOrderDetailsScreen => _getFlag(
        'ENABLE_ORDER_DETAILS_SCREEN',
        defaultValue: false,
      );

  /// Enable per-cart special instructions
  /// When true: Shows "Message to restaurant" widget in Screen B
  /// When false: Uses global order note only
  static bool get enablePerCartInstructions => _getFlag(
        'ENABLE_PER_CART_INSTRUCTIONS',
        defaultValue: false,
      );

  // ============================================================================
  // PHASE 4: Screen C - Enhanced Checkout
  // ============================================================================

  /// Enable map-based checkout header
  /// When true: Shows Google Map with restaurant + address pins
  /// When false: Traditional form-based checkout
  static bool get enableMapCheckout => _getFlag(
        'ENABLE_MAP_CHECKOUT',
        defaultValue: false,
      );

  /// Enable gift order functionality
  /// When true: Shows "Send as gift" option with recipient fields
  /// When false: Regular orders only
  static bool get enableGiftOrders => _getFlag(
        'ENABLE_GIFT_ORDERS',
        defaultValue: false,
      );

  /// Enable "Leave at door" option for delivery orders
  /// When true: Shows toggle in delivery options
  /// When false: Regular delivery only
  static bool get enableLeaveAtDoor => _getFlag(
        'ENABLE_LEAVE_AT_DOOR',
        defaultValue: false,
      );

  // ============================================================================
  // PERFORMANCE & FALLBACKS
  // ============================================================================

  /// Use static map image instead of interactive Google Maps
  /// Useful for low-end devices or when map performance is poor
  static bool get useStaticMapFallback => _getFlag(
        'USE_STATIC_MAP_FALLBACK',
        defaultValue: false,
      );

  /// Enable debug mode for cart flow
  /// Shows additional logging and debugging information
  static bool get debugCartFlow => _getFlag(
        'DEBUG_CART_FLOW',
        defaultValue: false,
      );

  // ============================================================================
  // Internal Implementation
  // ============================================================================

  /// Get flag value from configuration
  /// In production, this should read from:
  /// - Firebase Remote Config (recommended for A/B testing)
  /// - Local SharedPreferences (for per-device overrides)
  /// - Environment variables (for build-time configuration)
  ///
  /// For now, returns hardcoded default values
  static bool _getFlag(String key, {required bool defaultValue}) {
    // TODO: In Phase 2+, integrate with Firebase Remote Config or similar
    // Example:
    // try {
    //   final remoteConfig = FirebaseRemoteConfig.instance;
    //   return remoteConfig.getBool(key);
    // } catch (e) {
    //   return defaultValue;
    // }

    // For Phase 1, use hardcoded defaults
    return defaultValue;
  }

  /// Override a feature flag for testing purposes
  /// This method would store the override in SharedPreferences
  static Future<void> setFlagOverride(String key, bool value) async {
    // TODO: Implement SharedPreferences override
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.setBool('feature_flag_$key', value);
  }

  /// Clear all feature flag overrides
  static Future<void> clearAllOverrides() async {
    // TODO: Implement clearing overrides
    // final prefs = await SharedPreferences.getInstance();
    // final keys = prefs.getKeys().where((key) => key.startsWith('feature_flag_'));
    // for (var key in keys) {
    //   await prefs.remove(key);
    // }
  }

  /// Get all feature flag states (for debugging)
  static Map<String, bool> getAllFlags() {
    return {
      'ENABLE_MULTI_RESTAURANT_CARTS': enableMultiRestaurantCarts,
      'ENABLE_ORDER_DETAILS_SCREEN': enableOrderDetailsScreen,
      'ENABLE_PER_CART_INSTRUCTIONS': enablePerCartInstructions,
      'ENABLE_MAP_CHECKOUT': enableMapCheckout,
      'ENABLE_GIFT_ORDERS': enableGiftOrders,
      'ENABLE_LEAVE_AT_DOOR': enableLeaveAtDoor,
      'USE_STATIC_MAP_FALLBACK': useStaticMapFallback,
      'DEBUG_CART_FLOW': debugCartFlow,
    };
  }
}
