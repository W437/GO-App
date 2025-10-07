# Dashboard Performance Optimization Plan

## Goals
- Reduce steady-state memory footprint of the dashboard screens on iOS.
- Lower CPU utilization during idle navigation and tab transitions.
- Preserve the circular reveal experience without keeping every tab alive.

## Current Pain Points
- `DashboardScreen` keeps all five tab screens mounted in an `IndexedStack`, so every heavyweight widget (Google Map, long lists, modals) continues to render even when hidden.
- The Explore tab's live `GoogleMap` remains active while off-screen, retaining map textures and driving CPU usage through continuous compositing.
- Marker icons for the map are rebuilt on every refresh, decoding PNG assets each time and adding to memory churn.
- `HomeScreen.loadData(false)` executes large batches of network calls and fills caches immediately, regardless of whether the user opens Home.

## Recommended Actions
1. **Lazy mount dashboard tabs**
   - Swap dormant `IndexedStack` entries with lightweight placeholders once a transition completes.
   - Keep only the current and outgoing screen alive during circular reveal animations, relying on existing `PageStorageKey`s to restore state.

2. **Animate bitmaps instead of full widgets**
   - Wrap each tab in a `RepaintBoundary` and capture the outgoing screen as an image before detach.
   - Drive the circular reveal animation with the captured bitmap + the newly mounted screen to maintain the effect while freeing inactive tabs.

3. **Pause and dispose Explore resources when hidden**
   - Dispose the `GoogleMapController` and map widget when Explore is not the active tab.
   - Reload markers and controller on re-entry, avoiding background GPU work from an off-screen map.

4. **Cache marker descriptors**
   - Introduce a static cache in `MarkerHelper` so PNG to `BitmapDescriptor` conversion happens once per image per run.
   - Invalidate only when asset dimensions change.

5. **Defer heavy Home data loads**
   - Trigger `HomeScreen.loadData` the first time Home becomes active, or split it so non-essential lists load on demand.
   - Refresh background data opportunistically after the initial view to keep UX responsive without the upfront memory hit.

## Validation Checklist
- Use Flutter DevTools memory profile on iOS to confirm idle dashboard RAM drops below 400 MB.
- Verify CPU usage sits below 20 % while stationary on non-Explore tabs.
- Confirm circular reveal remains smooth on transitions between all tabs.
- Ensure Explore re-initializes quickly and markers appear without noticeable delay.

## Follow-Up
- Capture before/after instrumentation snapshots (RAM/CPU) for regression tracking.
- Document any controller lifecycle changes so future features respect the lazy-mount pattern.
