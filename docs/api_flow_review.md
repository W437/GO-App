## API Flow Review

### Current Request Wiring
- `lib/helper/get_di.dart`: registers `SharedPreferences`, then `ApiClient`, repositories, services, and controllers. Every repository receives the shared `ApiClient`, so all HTTP calls flow through the same header, auth, and timeout configuration (`lib/api/api_client.dart`).
- `ApiClient` injects localization, zone, geo, and token headers and exposes REST helpers plus multipart upload support. Error handling funnels through `ApiChecker`.

### Launch-Time Network Calls
- **Web bootstrap (`lib/main.dart:120-134`)**: initializes shared data, runs guest login if needed, fetches remote cart contents, pulls config via `SplashController.getConfigData(fromMainFunction: true)`, refreshes JWT, and loads favourites if the user is authenticated.
- **Mobile splash (`lib/features/splash/screens/splash_screen.dart`)**: after connectivity/video gates, calls `SplashController.getConfigData`. The controller serves cached config JSON first (from `SharedPreferences` key `go_config_cache`) and simultaneously refreshes the remote config (`lib/features/splash/controllers/splash_controller.dart:99-169`). Successful responses trigger maintenance/update checks and route decisions via `lib/helper/splash_route_helper.dart`.
- Both flows kick off cart syncs whenever a logged-in or guest session exists (`lib/features/cart/controllers/cart_controller.dart:279-287`).

### Runtime Triggers
- **Home screen (`lib/features/home/screens/home_screen.dart:73-103`)** fires more than a dozen asynchronous requests every time it loads (banners, categories, cuisines, advertisements, dine-in, stories, zone list, campaigns, multiple restaurant/product collections, etc.). When logged in, it additionally pulls profile, notifications, running orders, addresses, and cashback offers.
- **Controllers** such as Category, Cuisine, Restaurant, Story, and Notification fetch data again whenever the user filters, paginates, or refreshes content. Many of these controllers are written to request cached data first and then re-hit the API (`DataSourceEnum.local` → `DataSourceEnum.client`).
- **Location and zone data** are requested from the API by both splash routing (`lib/helper/splash_route_helper.dart:79-88`) and home initialization (`lib/features/home/screens/home_screen.dart:80-81`), as well as any screen that needs the picker.

### Caching Behavior
- `SplashRepository` caches config responses under `AppConstants.configCacheKey` with a best-effort background refresh.
- Content repositories (banners, cashback, cuisines, restaurants, notifications, etc.) optionally serialize responses via `LocalClient`, which writes to `SharedPreferences` on web and to the Drift database on mobile (`lib/api/local_client.dart`). Controllers usually read from cache first and then trigger a remote refresh.
- Critical flows such as cart sync, zone list, profile, orders, and category list either skip caching entirely or bypass the cached branch in practice, so they always hit the network.

### Identified Issues
1. **Inconsistent cache usage** – E.g., `CategoryController.getCategoryList` always requests `DataSourceEnum.client`, so cached categories are never used on launch. Similar gaps exist for zone lists, profile, orders, and cart data.
2. **Network storms on home entry** – `HomeScreen.loadData` fires 10+ requests simultaneously, regardless of viewport/config flags, with no throttling or batching. Slow connections experience staggered spinners and extra server load.
3. **Zone list over-fetching** – Both splash routing and home initialization trigger `LocationController.getZoneList`, and the controller itself re-fetches even when `_zoneList` isn’t empty, leading to redundant calls.
4. **Cache invalidation/TTL** – `LocalClient` has no timestamp or version tracking; stale responses can persist indefinitely if the app stays offline or never reloads with `DataSourceEnum.client`.
5. **Cart sync churn** – Every cart mutation triggers a full `getCartDataOnline`, and splash/login/checkout screens call the same method. Without request coalescing, quick successive actions flicker loading states and can race.

### Improvement Plan (Validated)
1. **Standardize cache-first patterns**
   - Update controllers (Categories, Zone/Location, Profile, Orders, Cart snapshot) to request `DataSourceEnum.local` on first load, and only hit `DataSourceEnum.client` afterward.
   - Add helper utilities so controllers can share the “local then remote” flow instead of duplicating logic.
   - ✅ Expected impact: reduces cold-start latency and cuts duplicate API traffic because cached payloads already exist for banners/categories/cuisines; no new backend dependencies are introduced, so regression risk is limited to controller wiring changes.
2. **Introduce cache metadata**
   - Extend `LocalClient.organize` to store `updatedAt` timestamps (in Drift rows / shared prefs).
   - Add TTL validation per endpoint (e.g., config 1h, banners 10m) so controllers can skip stale data or force refreshes.
   - ✅ Expected impact: prevents stale data from persisting forever, guarantees eventual refresh even if controllers stay on local data, and the TTL logic can be unit-tested in isolation for determinism.
3. **Batch home-screen bootstrapping**
   - Gate `HomeScreen.loadData` behind a scheduler that (a) skips sections disabled in `configModel`, (b) groups read-only lists into fewer backend calls where possible, and (c) debounces repeated loads; consider lazy-loading sections as the user scrolls into view.
   - ✅ Expected impact: immediately decreases simultaneous API calls >50% in scenarios where features are disabled or off-screen. Because each controller already supports manual reloads, deferring their invocation does not break functionality.
4. **Memoize zone list & cart snapshot**
   - Cache zone polygons in `SharedPreferences`/Drift with TTL, and only re-fetch when missing/expired.
   - For cart data, keep a short-lived in-memory snapshot and coalesce concurrent `getCartDataOnline` calls so multiple UI widgets can await the same Future.
   - ✅ Expected impact: eliminates redundant zone hits (currently duplicated on splash, home, and picker) and stops cart reload thrash when multiple widgets update simultaneously. Uses existing storage stack, so no infra work.
5. **Add instrumentation**
   - Emit analytics/metrics (duration, success/failure) for high-volume endpoints (config, home feed, cart, zone list). Use this to identify the worst offenders when optimizing.
   - ✅ Expected impact: provides quantitative feedback loops for the above optimizations and surfaces regressions quickly; the instrumentation layer is additive and does not modify control flow.
