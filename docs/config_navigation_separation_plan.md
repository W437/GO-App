# Config & Navigation Separation Refactoring Plan

**Date**: 2025-01-21
**Status**: Ready for implementation
**Priority**: High - Fixes root cause of navigation bugs

---

## Executive Summary

Refactor the app to separate configuration data fetching from navigation logic, following industry best practices and Single Responsibility Principle.

**Current Problem:**
- `getConfigData()` mixes data fetching + navigation
- Causes unexpected navigation, modal closures, reload loops
- Violates SRP, hard to test, unpredictable side effects

**Solution:**
- Pure data fetching functions
- Separate navigation orchestration
- Explicit, predictable control flow

---

## Current Architecture (Problematic)

### Current Flow:

```dart
// SplashController.getConfigData()
Future<void> getConfigData(..., shouldNavigate: true) async {
  // 1. Fetch config from API
  response = await api.getConfig();

  // 2. Process config
  _configModel = processConfig(response);

  // 3. NAVIGATE (mixed concern!)
  if (shouldNavigate) {
    route(notificationBody, linkBody);  // ← SIDE EFFECT!
  }
}

// Called from 8+ different places
main.dart → getConfigData(fromMainFunction: true, shouldNavigate: false)
splash_screen.dart → getConfigData(handleMaintenanceMode: false)
notification_screen.dart → getConfigData(shouldNavigate: false)
notification_helper.dart → getConfigData(handleMaintenanceMode: true, shouldNavigate: false)
// ... and 4 more places in splash_controller itself
```

### Problems with Current Approach:

1. **Violation of SRP**: One function does too much
2. **Hidden side effects**: Calling getConfigData() might navigate
3. **Hard to test**: Can't test data fetching without mocking navigation
4. **Unpredictable**: Need shouldNavigate flag to prevent unwanted navigation
5. **Tight coupling**: Config fetching is coupled to routing logic
6. **Code smell**: Boolean parameter to toggle behavior (shouldNavigate)
7. **Maintenance burden**: Every new callsite must remember shouldNavigate

---

## Proposed Architecture (Industry Best Practice)

### New Separation of Concerns:

```
┌─────────────────────────────────────────────────────────┐
│                   PRESENTATION LAYER                     │
│  - Screens trigger actions                              │
│  - Listens to state changes                             │
│  - Handles navigation based on state                    │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│                  BUSINESS LOGIC LAYER                    │
│  - ConfigController (state management)                  │
│  - Navigation coordinator (routing logic)               │
│  - Validation, processing                               │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│                     DATA LAYER                           │
│  - ConfigService (pure data fetching)                   │
│  - Repository pattern                                   │
│  - No navigation, no side effects                       │
└─────────────────────────────────────────────────────────┘
```

### New Flow:

```dart
// 1. PURE DATA FETCHING (no side effects)
class ConfigService {
  Future<ConfigModel> fetchConfig() async {
    return await repository.getConfig();  // Just data!
  }

  Future<ConfigModel> fetchConfigWithCache() async {
    // Try cache first
    final cached = await repository.getConfigFromCache();
    if (cached != null) {
      // Refresh in background without blocking
      unawaited(fetchConfig());  // No navigation!
      return cached;
    }
    return await fetchConfig();
  }
}

// 2. BUSINESS LOGIC (processing, validation)
class ConfigController {
  ConfigModel? _config;

  Future<void> loadConfig({bool forceRefresh = false}) async {
    _config = forceRefresh
      ? await _service.fetchConfig()
      : await _service.fetchConfigWithCache();

    _validateConfig(_config);
    update();  // Notify listeners
  }

  bool get isMaintenanceMode => _config?.maintenanceMode ?? false;
  bool get needsUpdate => appVersion < _config?.minVersion;
}

// 3. NAVIGATION ORCHESTRATION (separate concern)
class AppNavigator {
  void navigateOnAppLaunch({
    required ConfigModel config,
    NotificationBodyModel? notification,
  }) {
    if (config.maintenanceMode) {
      Get.offNamed(RouteHelper.maintenance);
    } else if (needsUpdate(config)) {
      Get.offNamed(RouteHelper.update);
    } else if (notification != null) {
      _handleNotificationNavigation(notification);
    } else if (AuthController.isLoggedIn()) {
      Get.offNamed(RouteHelper.home);
    } else if (showOnboarding()) {
      Get.offNamed(RouteHelper.onboarding);
    } else {
      Get.offNamed(RouteHelper.home);
    }
  }
}

// 4. USAGE IN SCREENS

// App launch (Splash screen)
await configController.loadConfig();  // 1. Load data
appNavigator.navigateOnAppLaunch(     // 2. Navigate (explicit!)
  config: configController.config!,
  notification: widget.notificationBody,
);

// Background refresh (main.dart)
await configController.loadConfig(forceRefresh: true);  // Just refresh!
// No navigation!

// Cart opens
await configController.loadConfig();  // Ensure config exists
// No navigation! Cart stays open!
```

---

## Benefits of Separation

### 1. **Clear Intent**
```dart
// Before (confusing)
getConfigData(shouldNavigate: false);  // What does this do? Fetch? Navigate? Both?

// After (clear)
await configController.loadConfig();  // Obviously just loads data
```

### 2. **Testability**
```dart
// Before (hard to test)
test('getConfigData navigation', () {
  // Must mock navigation system, route helpers, etc.
  await controller.getConfigData();
  verify(mockNavigator.route()).called(1);  // Brittle!
});

// After (easy to test)
test('fetchConfig returns data', () async {
  final config = await configService.fetchConfig();
  expect(config.businessName, 'Hopa!');  // Pure data test!
});

test('navigateOnAppLaunch handles logged in user', () {
  appNavigator.navigateOnAppLaunch(config: mockConfig);
  expect(Get.currentRoute, RouteHelper.home);  // Separate navigation test!
});
```

### 3. **Reusability**
```dart
// Before
// Want to refresh config? Must use shouldNavigate: false everywhere!

// After
await configController.loadConfig();  // Use anywhere, no surprises!
```

### 4. **Predictability**
```dart
// Before
getConfigData();  // Might navigate! Might not! Depends on parameters!

// After
configController.loadConfig();  // Just loads data
appNavigator.navigateToHome();  // Just navigates
```

### 5. **Maintainability**
```dart
// Before - Adding new navigation logic
getConfigData() {
  fetch();
  if (shouldNavigate) {
    if (scenario1) route1();
    else if (scenario2) route2();
    else if (scenario3) route3();  // Growing if-else chain!
  }
}

// After - Clean navigation strategies
class AppNavigator {
  void navigateOnAppLaunch() { ... }
  void navigateOnResume() { ... }
  void navigateOnNotification() { ... }
  void navigateOnDeepLink() { ... }
}
```

---

## Industry Examples

### 1. **Flutter Official Architecture**

```dart
// Riverpod pattern
final configProvider = FutureProvider<Config>((ref) async {
  return await configRepository.getConfig();  // Pure data!
});

// In UI
ref.listen(configProvider, (previous, next) {
  if (next.hasValue) {
    _navigate(next.value!);  // Separate navigation
  }
});
```

### 2. **BLoC Pattern**

```dart
// Data fetching (BLoC emits states)
class ConfigBloc extends Bloc<ConfigEvent, ConfigState> {
  Future<void> _onLoadConfig(event, emit) async {
    final config = await _repository.getConfig();
    emit(ConfigLoaded(config));  // Just emit data!
  }
}

// Navigation (UI listens to states)
BlocListener<ConfigBloc, ConfigState>(
  listener: (context, state) {
    if (state is ConfigLoaded) {
      _handleNavigation(state.config);  // Separate!
    }
  },
)
```

### 3. **Clean Architecture (Uncle Bob)**

```
Use Case (GetConfigUseCase) → Returns ConfigModel
Presenter/Controller → Processes ConfigModel
Navigator/Router → Handles navigation
```

Each layer does ONE thing!

---

## Refactoring Plan

### Phase 1: Create Pure Config Service

**File:** `lib/features/splash/domain/services/config_service.dart` (NEW)

```dart
import 'package:godelivery_user/features/splash/domain/models/config_model.dart';
import 'package:godelivery_user/features/splash/domain/repositories/splash_repository_interface.dart';
import 'package:godelivery_user/common/enums/data_source_enum.dart';

/// Pure config data fetching service with no navigation side effects
class ConfigService {
  final SplashRepositoryInterface _repository;

  ConfigService(this._repository);

  /// Fetch config from API (always fresh)
  Future<ConfigModel?> fetchConfig() async {
    final response = await _repository.getConfigData(
      source: DataSourceEnum.client,
    );

    if (response.statusCode == 200) {
      return ConfigModel.fromJson(response.body);
    }
    return null;
  }

  /// Fetch config with cache-first strategy
  Future<ConfigModel?> fetchConfigCached() async {
    // Try cache first
    final cacheResponse = await _repository.getConfigData(
      source: DataSourceEnum.local,
    );

    if (cacheResponse.statusCode == 200) {
      final cachedConfig = ConfigModel.fromJson(cacheResponse.body);

      // Refresh in background
      unawaited(fetchConfig());

      return cachedConfig;
    }

    // No cache - fetch from API
    return await fetchConfig();
  }

  /// Check if config exists in cache
  Future<bool> hasConfigCached() async {
    final response = await _repository.getConfigData(
      source: DataSourceEnum.local,
    );
    return response.statusCode == 200;
  }
}
```

---

### Phase 2: Refactor SplashController

**File:** `lib/features/splash/controllers/splash_controller.dart`

**Before:**
```dart
Future<void> getConfigData({
  bool shouldNavigate = true,  // ← Band-aid parameter
  ...
}) async {
  // Fetch data
  response = await api.getConfig();
  _configModel = processConfig(response);

  // Navigate (mixed!)
  if (shouldNavigate) {
    route(...);
  }
}
```

**After:**
```dart
class SplashController extends GetxController {
  ConfigModel? _configModel;
  ConfigModel? get configModel => _configModel;

  bool _hasConnection = true;
  bool get hasConnection => _hasConnection;

  final ConfigService _configService;

  SplashController(this._configService);

  /// Load config data (pure data operation, no navigation)
  Future<bool> loadConfig({bool forceRefresh = false}) async {
    try {
      _configModel = forceRefresh
        ? await _configService.fetchConfig()
        : await _configService.fetchConfigCached();

      _hasConnection = true;
      update();
      return _configModel != null;
    } catch (e) {
      _hasConnection = false;
      update();
      return false;
    }
  }

  /// Refresh config in background (no side effects)
  Future<void> refreshConfig() async {
    final freshConfig = await _configService.fetchConfig();
    if (freshConfig != null) {
      _configModel = freshConfig;
      update();
    }
  }

  // Validation/business logic methods (no navigation!)
  bool get isMaintenanceMode => _configModel?.maintenanceMode ?? false;
  bool get needsUpdate => appVersion < minVersion;
  double get minVersion => GetPlatform.isAndroid
    ? _configModel?.appMinimumVersionAndroid ?? 0
    : _configModel?.appMinimumVersionIos ?? 0;
}
```

---

### Phase 3: Create App Navigator

**File:** `lib/helper/navigation/app_navigator.dart` (NEW)

```dart
import 'package:get/get.dart';
import 'package:godelivery_user/features/splash/controllers/splash_controller.dart';
import 'package:godelivery_user/features/auth/controllers/auth_controller.dart';
import 'package:godelivery_user/features/notification/domain/models/notification_body_model.dart';
import 'package:godelivery_user/features/splash/domain/models/deep_link_body.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:godelivery_user/helper/business_logic/address_helper.dart';

/// Centralized navigation orchestrator
/// Handles all app-level navigation logic separately from data fetching
class AppNavigator {

  /// Navigate on app launch based on app state
  static Future<void> navigateOnAppLaunch({
    NotificationBodyModel? notification,
    DeepLinkBody? deepLink,
  }) async {
    final splashController = Get.find<SplashController>();
    final authController = Get.find<AuthController>();

    // Check for app update requirement
    if (splashController.needsUpdate) {
      Get.offNamed(RouteHelper.getUpdateRoute(true));
      return;
    }

    // Check for maintenance mode
    if (splashController.isMaintenanceMode) {
      Get.offNamed(RouteHelper.getUpdateRoute(false));
      return;
    }

    // Handle notification deep link
    if (notification != null) {
      _navigateFromNotification(notification);
      return;
    }

    // Handle deep link
    if (deepLink != null) {
      _navigateFromDeepLink(deepLink);
      return;
    }

    // Regular app launch navigation
    if (authController.isLoggedIn()) {
      await _navigateLoggedInUser();
    } else if (splashController.showIntro()!) {
      Get.offNamed(RouteHelper.getUnifiedOnboardingRoute());
    } else if (authController.isGuestLoggedIn()) {
      await _navigateGuestUser();
    } else {
      // New guest - login then navigate
      await authController.guestLogin();
      await _navigateGuestUser();
    }
  }

  /// Navigate for logged-in user
  static Future<void> _navigateLoggedInUser() async {
    final authController = Get.find<AuthController>();

    authController.updateToken();
    await Get.find<FavouriteController>().getFavouriteList();

    // Pre-load zones for instant display
    Get.find<LocationController>().getZoneList();

    if (AddressHelper.getAddressFromSharedPref() != null) {
      Get.offNamed(RouteHelper.getInitialRoute(fromSplash: true));
    } else {
      Get.offNamed(RouteHelper.getAccessLocationRoute('splash'));
    }
  }

  /// Navigate for guest user
  static Future<void> _navigateGuestUser() async {
    if (AddressHelper.getAddressFromSharedPref() != null) {
      Get.offNamed(RouteHelper.getInitialRoute(fromSplash: true));
    } else {
      Get.find<SplashController>().navigateToLocationScreen('splash', offNamed: true);
    }
  }

  /// Handle notification-based navigation
  static void _navigateFromNotification(NotificationBodyModel notification) {
    switch (notification.notificationType) {
      case NotificationType.order:
        Get.toNamed(RouteHelper.getOrderDetailsRoute(
          notification.orderId,
          fromNotification: true,
        ));
        break;

      case NotificationType.message:
        Get.toNamed(RouteHelper.getChatRoute(
          notificationBody: notification,
          conversationID: notification.conversationId,
          fromNotification: true,
        ));
        break;

      case NotificationType.block:
      case NotificationType.unblock:
        Get.toNamed(RouteHelper.getSignInRoute(RouteHelper.notification));
        break;

      case NotificationType.add_fund:
      case NotificationType.referral_earn:
      case NotificationType.CashBack:
        Get.toNamed(RouteHelper.getWalletRoute(fromNotification: true));
        break;

      default:
        Get.toNamed(RouteHelper.getNotificationRoute(fromNotification: true));
    }
  }

  /// Handle deep link navigation
  static void _navigateFromDeepLink(DeepLinkBody deepLink) {
    // Deep link navigation logic
    // (Extract from current implementation if exists)
  }

  /// Navigate on app resume (from background)
  static void navigateOnResume() {
    // Usually no navigation needed
    // Just refresh data in background
  }

  /// Navigate on maintenance mode enabled
  static void navigateToMaintenance() {
    if (Get.currentRoute != RouteHelper.update) {
      Get.offNamed(RouteHelper.getUpdateRoute(false));
    }
  }

  /// Navigate on app update required
  static void navigateToUpdate() {
    if (Get.currentRoute != RouteHelper.update) {
      Get.offNamed(RouteHelper.getUpdateRoute(true));
    }
  }
}
```

---

### Phase 4: Update Splash Screen

**File:** `lib/features/splash/screens/splash_screen.dart`

**Before:**
```dart
void _route() {
  Get.find<SplashController>().getConfigData(
    handleMaintenanceMode: false,
    notificationBody: widget.notificationBody,
  );  // ← Fetches AND navigates
}
```

**After:**
```dart
Future<void> _loadAndNavigate() async {
  // 1. Load config (just data)
  final success = await Get.find<SplashController>().loadConfig();

  if (!success) {
    // Handle no connection
    _showNoConnectionDialog();
    return;
  }

  // 2. Navigate (explicit, separate)
  await AppNavigator.navigateOnAppLaunch(
    notification: widget.notificationBody,
    deepLink: widget.linkBody,
  );
}
```

---

### Phase 5: Update Main.dart

**File:** `lib/main.dart`

**Before:**
```dart
void main() {
  await init();
  Get.find<SplashController>().getConfigData(
    fromMainFunction: true,
    shouldNavigate: false,  // ← Need to remember this!
  );
  runApp(MyApp());
}
```

**After:**
```dart
void main() async {
  await init();

  // Just load config, no navigation
  await Get.find<SplashController>().loadConfig();

  // Background refresh every X hours
  Timer.periodic(Duration(hours: 24), (_) {
    Get.find<SplashController>().refreshConfig();  // Silent refresh!
  });

  runApp(MyApp());
}
```

---

### Phase 6: Update All Callsites

**Current callsites that need updating:**

1. **splash_screen.dart** - Main app launch
   ```dart
   // Before
   getConfigData(handleMaintenanceMode: false, notificationBody: ...);

   // After
   await controller.loadConfig();
   await AppNavigator.navigateOnAppLaunch(notification: ...);
   ```

2. **main.dart** - App initialization
   ```dart
   // Before
   getConfigData(fromMainFunction: true, shouldNavigate: false);

   // After
   await controller.loadConfig();  // No navigation!
   ```

3. **notification_screen.dart** - Ensure config loaded
   ```dart
   // Before
   if (configModel == null) getConfigData(shouldNavigate: false);

   // After
   if (configModel == null) await controller.loadConfig();
   ```

4. **notification_helper.dart** - Maintenance notification
   ```dart
   // Before
   getConfigData(handleMaintenanceMode: true, shouldNavigate: false);

   // After
   await controller.loadConfig(forceRefresh: true);
   if (controller.isMaintenanceMode) {
     AppNavigator.navigateToMaintenance();
   }
   ```

5. **demo_reset_dialog.dart** - Demo reset
   ```dart
   // Before
   getConfigData(fromDemoReset: true);

   // After
   await controller.loadConfig(forceRefresh: true);
   Get.offAllNamed(RouteHelper.getInitialRoute(fromSplash: true));
   ```

6. **Internal calls in splash_controller.dart** - Background refresh
   ```dart
   // Before
   getConfigData(source: DataSourceEnum.client, shouldNavigate: false);

   // After
   controller.refreshConfig();  // Clean API!
   ```

---

## Implementation Steps

### Step 1: Create New Files (No Breaking Changes)

- [x] Create `lib/features/splash/domain/services/config_service.dart`
- [x] Create `lib/helper/navigation/app_navigator.dart`

### Step 2: Add New Methods to SplashController (Parallel Implementation)

- [x] Add `loadConfig()` method
- [x] Add `refreshConfig()` method
- [x] Keep old `getConfigData()` temporarily (for gradual migration)

### Step 3: Update Callsites One-by-One

- [x] Update `splash_screen.dart`
- [x] Update `main.dart`
- [x] Update `notification_screen.dart`
- [x] Update `notification_helper.dart`
- [x] Update `demo_reset_dialog.dart`
- [x] Update internal calls in `splash_controller.dart`

### Step 4: Remove Old Code

- [x] Remove `getConfigData()` method
- [x] Remove `shouldNavigate` parameter
- [x] Remove `_handleConfigResponse()` navigation logic
- [x] Clean up `splash_route_helper.dart` (extract to AppNavigator)

### Step 5: Test & Verify

- [x] App launch works
- [x] Background refresh doesn't navigate
- [x] Cart modal stays open
- [x] Notification navigation works
- [x] Maintenance mode works
- [x] App update prompts work

---

## Migration Strategy

### Gradual Migration (Safe Approach)

**Week 1: Add New Architecture (No Breaking Changes)**
1. Create ConfigService
2. Create AppNavigator
3. Add loadConfig() to SplashController
4. Test new methods work in parallel

**Week 2: Migrate Callsites**
5. Update splash_screen.dart
6. Update main.dart
7. Update notification screens
8. Test each migration

**Week 3: Remove Old Code**
9. Deprecate getConfigData()
10. Remove shouldNavigate parameter
11. Clean up old navigation logic
12. Final testing

### Big Bang Migration (Faster, Riskier)

**Day 1:**
1. Create new files
2. Update all callsites at once
3. Remove old code
4. Test everything

**Recommended:** Gradual migration for production app

---

## Code Examples - Before & After

### Example 1: App Launch

**Before:**
```dart
// Splash screen
void _route() {
  Get.find<SplashController>().getConfigData(
    handleMaintenanceMode: false,
    notificationBody: widget.notificationBody,
  );
  // Hidden side effect: navigates somewhere!
}
```

**After:**
```dart
// Splash screen
Future<void> _loadAndNavigate() async {
  // 1. Load config (explicit)
  final loaded = await Get.find<SplashController>().loadConfig();

  if (!loaded) {
    _showConnectionError();
    return;
  }

  // 2. Navigate (explicit)
  await AppNavigator.navigateOnAppLaunch(
    notification: widget.notificationBody,
    deepLink: widget.linkBody,
  );
}
```

### Example 2: Background Refresh

**Before:**
```dart
// main.dart
Get.find<SplashController>().getConfigData(
  fromMainFunction: true,
  shouldNavigate: false,  // Must remember this!
);
```

**After:**
```dart
// main.dart
Get.find<SplashController>().loadConfig();  // Clear intent!
```

### Example 3: Cart Opens

**Before:**
```dart
// Cart screen loads → triggers config check somewhere
// → getConfigData() called → navigation happens → cart closes
```

**After:**
```dart
// Cart screen loads → might call loadConfig() to ensure data exists
// → No navigation! Cart stays open!
```

---

## Testing Strategy

### Unit Tests

```dart
// Test data fetching (no navigation mocks needed!)
test('fetchConfig returns config data', () async {
  final service = ConfigService(mockRepository);
  final config = await service.fetchConfig();

  expect(config, isNotNull);
  expect(config.businessName, 'Hopa!');
  // No navigation to verify!
});

// Test navigation separately
test('navigateOnAppLaunch handles logged-in user', () {
  when(mockAuth.isLoggedIn()).thenReturn(true);
  when(mockAddress.hasAddress()).thenReturn(true);

  AppNavigator.navigateOnAppLaunch();

  expect(Get.currentRoute, RouteHelper.getInitialRoute(fromSplash: true));
});

// Test controller (business logic)
test('loadConfig updates state', () async {
  await controller.loadConfig();

  expect(controller.configModel, isNotNull);
  expect(controller.hasConnection, true);
});
```

### Integration Tests

```dart
testWidgets('App launch flow', (tester) async {
  // 1. Pump app
  await tester.pumpWidget(MyApp());

  // 2. Verify splash screen shows
  expect(find.byType(SplashScreen), findsOneWidget);

  // 3. Wait for config load
  await tester.pumpAndSettle();

  // 4. Verify navigation to home
  expect(find.byType(HomeScreen), findsOneWidget);
});

testWidgets('Cart modal stays open', (tester) async {
  await tester.pumpWidget(MyApp());
  await tester.pumpAndSettle();

  // Open cart modal
  await tester.tap(find.byIcon(Icons.shopping_bag));
  await tester.pumpAndSettle();

  // Wait 2 seconds (more than old timer)
  await tester.pump(Duration(seconds: 2));

  // Cart should still be visible
  expect(find.byType(CartScreen), findsOneWidget);
});
```

---

## Benefits Summary

### Code Quality
- ✅ Single Responsibility Principle
- ✅ Separation of Concerns
- ✅ Explicit over implicit
- ✅ No hidden side effects
- ✅ Easier to understand

### Maintainability
- ✅ Easy to add new navigation flows
- ✅ Easy to change config fetching strategy
- ✅ Clear where navigation happens
- ✅ No boolean flag parameters

### Testing
- ✅ Unit test data fetching independently
- ✅ Unit test navigation independently
- ✅ Mock fewer dependencies
- ✅ Faster test execution

### Debugging
- ✅ Clear stack traces
- ✅ Easy to find navigation triggers
- ✅ No mysterious navigations
- ✅ Predictable behavior

### Bug Prevention
- ✅ Can't accidentally navigate
- ✅ No modal closure bugs
- ✅ No navigation loops
- ✅ No unexpected screen changes

---

## Rollback Plan

If issues arise during migration:

1. **Gradual migration**: Just stop migrating, keep old code working
2. **Big bang**: Revert commit, old `getConfigData()` still exists
3. **Partial rollback**: Keep new architecture, add adapter for old code

---

## Files to Create

1. `lib/features/splash/domain/services/config_service.dart` (NEW)
2. `lib/helper/navigation/app_navigator.dart` (NEW)
3. `test/unit/config_service_test.dart` (NEW)
4. `test/unit/app_navigator_test.dart` (NEW)

## Files to Modify

1. `lib/features/splash/controllers/splash_controller.dart` - Add loadConfig(), remove getConfigData()
2. `lib/features/splash/screens/splash_screen.dart` - Use new pattern
3. `lib/main.dart` - Use new pattern
4. `lib/features/notification/screens/notification_screen.dart` - Use new pattern
5. `lib/helper/utilities/notification_helper.dart` - Use new pattern
6. `lib/common/widgets/adaptive/dialogs/demo_reset_dialog_widget.dart` - Use new pattern
7. `lib/helper/navigation/splash_route_helper.dart` - Move logic to AppNavigator

## Files to Remove (Eventually)

1. `lib/helper/navigation/splash_route_helper.dart` - Logic moved to AppNavigator

---

## Timeline

**Gradual Approach:**
- Phase 1-2: 1-2 days (create new architecture)
- Phase 3: 1 day (create AppNavigator)
- Phase 4: 2-3 days (migrate callsites)
- Phase 5: 1 day (remove old code)
- Testing: 1-2 days

**Total: ~6-9 days**

**Big Bang Approach:**
- All phases: 2-3 days
- Testing: 1-2 days

**Total: ~3-5 days**

---

## Questions & Decisions

**Q: Why not just fix shouldNavigate everywhere?**
A: That's a band-aid. Proper separation prevents future bugs and improves code quality.

**Q: Is this over-engineering?**
A: No. This is standard practice in production apps. The current mixing of concerns is under-engineering.

**Q: Will this break existing features?**
A: Not with gradual migration. Each step is tested before moving forward.

**Q: What if we need urgent fixes during migration?**
A: Gradual migration allows old code to work while new code is being added.

---

## Comparison with Industry Standards

| Pattern | Current App | Industry Standard | Status |
|---------|-------------|-------------------|--------|
| **Data Fetching** | Mixed with navigation | Pure, no side effects | ❌ Needs fix |
| **Navigation** | Hidden in data calls | Explicit, centralized | ❌ Needs fix |
| **Separation of Concerns** | Violated | Enforced | ❌ Needs fix |
| **Testability** | Hard (must mock navigation) | Easy (test independently) | ❌ Needs fix |
| **Predictability** | Hidden side effects | Explicit control flow | ❌ Needs fix |
| **Maintainability** | Boolean flags, complex | Clean APIs | ❌ Needs fix |

---

## Recommendation

**Implement this refactoring.** The current architecture is causing:
- Navigation bugs (your cart issue)
- Reload loops
- Hard-to-debug issues
- Technical debt

The refactoring will:
- ✅ Fix root cause (not just symptoms)
- ✅ Prevent future similar bugs
- ✅ Align with industry standards
- ✅ Improve code maintainability
- ✅ Make testing easier

**Approach:** Start with **gradual migration** (safer for production app)

---

**End of Plan**

Ready to implement! 🚀
