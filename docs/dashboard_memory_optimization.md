# Dashboard Memory Optimization Plan

**Date**: 2025-11-23
**Status**: Ready for Implementation
**Goal**: Reduce memory usage from 5 screens → 1 screen (2 during animations)

---

## Current State

### Memory Usage
- **All 5 screens rendered simultaneously** using `IndexedStack`
- Memory: ~5x screen size constantly in RAM
- Benefits: Instant tab switching, perfect state preservation
- Drawbacks: High memory footprint

### How It Works Now
```dart
IndexedStack(
  index: displayIndex,
  children: _screens, // All 5 screens always in memory
)
```

---

## Optimization Strategy

### New Approach: On-Demand Rendering + Temporary Cache

**Idle State**:
- Only render current screen
- Memory: 1 screen

**During Animation** (~500ms):
- Cache previous screen as live widget
- Render new screen
- Apply circular reveal animation
- Memory: 2 screens (temporary)

**After Animation**:
- Drop cached screen
- Memory: 1 screen

### Why This Works
1. **Screens are stateless shells** - They pull data from GetX controllers
2. **Controllers stay in memory** - State persists independently
3. **PageStorage handles scroll positions** - Built-in Flutter restoration
4. **Circular reveal preserved** - Both screens available during transition

---

## Implementation Steps

### 1. Add Cache Variable
**File**: `lib/features/dashboard/screens/dashboard_screen.dart`
**Location**: Line ~56 (after `_tapPosition`)

```dart
Widget? _previousScreenCache; // Cache previous screen during animation
```

---

### 2. Remove Static Screens Array
**Location**: `initState()` method, lines ~99-120

**DELETE**:
```dart
_screens = [
  KeyedSubtree(key: _screenKeys[0], child: const ExploreScreen(...)),
  KeyedSubtree(key: _screenKeys[1], child: const MartScreen(...)),
  // ... etc
];
```

**KEEP**:
```dart
_screenKeys = List.generate(5, (_) => GlobalKey());
```

---

### 3. Add On-Demand Screen Builder
**Location**: After `initState()` method

```dart
/// Creates screen widget on-demand based on index
Widget _getScreen(int index) {
  switch (index) {
    case 0:
      return const ExploreScreen(key: PageStorageKey('explore'));
    case 1:
      return const MartScreen(key: PageStorageKey('mart'));
    case 2:
      return const HomeScreen(key: PageStorageKey('home'));
    case 3:
      return const OrderScreen(key: PageStorageKey('orders'));
    case 4:
      return const MenuScreen(key: PageStorageKey('menu'));
    default:
      return const HomeScreen(key: PageStorageKey('home'));
  }
}
```

---

### 4. Replace IndexedStack with Optimized Stack
**Location**: `build()` method, lines ~254-316

**Replace entire `ExpandableBottomSheet.background` Stack with**:

```dart
background: Stack(
  children: [
    // BASE: Current screen (only when NOT animating)
    if (!_isAnimating)
      KeyedSubtree(
        key: _screenKeys[_pageIndex],
        child: _getScreen(_pageIndex),
      ),

    // ANIMATION LAYER 1: Previous screen (cached during animation)
    if (_isAnimating && _previousScreenCache != null)
      KeyedSubtree(
        key: _screenKeys[_previousPageIndex],
        child: _previousScreenCache!,
      ),

    // ANIMATION LAYER 2: New screen with circular reveal
    if (_isAnimating)
      IgnorePointer(
        child: AnimatedBuilder(
          animation: _animation,
          child: KeyedSubtree(
            key: _screenKeys[_pageIndex],
            child: _getScreen(_pageIndex),
          ),
          builder: (context, child) {
            final scale = _calculateOverlayScale(_animation.value);
            return LayoutBuilder(
              builder: (context, constraints) {
                final size = constraints.biggest;
                final rawTap = _tapPosition ?? Offset(size.width / 2, size.height / 2);
                final safeTap = Offset(
                  rawTap.dx.clamp(0.0, size.width),
                  rawTap.dy.clamp(0.0, size.height),
                );
                final alignment = Alignment(
                  size.width > 0 ? (safeTap.dx / size.width) * 2 - 1 : 0,
                  size.height > 0 ? (safeTap.dy / size.height) * 2 - 1 : 0,
                );

                return ClipPath(
                  clipper: CircularRevealClipper(
                    fraction: _animation.value,
                    centerOffset: safeTap,
                  ),
                  child: Transform.scale(
                    scale: scale,
                    alignment: alignment,
                    child: child,
                  ),
                );
              },
            );
          },
        ),
      ),
  ],
),
```

---

### 5. Update `_setPage()` Method
**Location**: Lines ~373-408

**Replace entire `_setPage()` method with**:

```dart
void _setPage(int pageIndex, [Offset? tapPosition]) {
  // If clicking explore tab while already on explore and in fullscreen mode, exit fullscreen
  if (pageIndex == 0 && _pageIndex == 0) {
    final exploreController = Get.find<ExploreController>();
    if (exploreController.isFullscreenMode) {
      exploreController.exitFullscreenMode();
    }
    return;
  }

  // Exit fullscreen mode when navigating away from explore screen
  if (_pageIndex == 0 && pageIndex != 0) {
    final exploreController = Get.find<ExploreController>();
    if (exploreController.isFullscreenMode) {
      exploreController.exitFullscreenMode();
    }
  }

  if (pageIndex == _pageIndex) return;

  setState(() {
    // Cache current screen before switching
    _previousScreenCache = _getScreen(_pageIndex);
    _previousPageIndex = _pageIndex;
    _pageIndex = pageIndex;
    _tapPosition = tapPosition;
    _isAnimating = true;
  });

  // Start animation
  _animationController.forward(from: 0.0).then((_) {
    if (mounted) {
      setState(() {
        _isAnimating = false;
        _previousScreenCache = null; // Clear cache to free memory
      });
    }
  });
}
```

---

## Expected Results

### Memory Comparison

| State | Before | After | Improvement |
|-------|--------|-------|-------------|
| **Idle** | 5 screens | 1 screen | **80% reduction** |
| **Animating** | 5 screens | 2 screens | **60% reduction** |
| **Duration** | Always | ~500ms | - |

### Performance

| Metric | Status |
|--------|--------|
| **Tab Switch Speed** | ✅ Unchanged (instant) |
| **State Preservation** | ✅ Maintained (controllers + PageStorage) |
| **Circular Reveal Animation** | ✅ Preserved |
| **Scroll Positions** | ✅ Restored via PageStorage |
| **Form State** | ✅ Kept in controllers |

---

## Technical Details

### Why Previous Screen is Live (Not Snapshot)

During the 500ms animation, the cached previous screen is a **live widget tree**, not a frozen image:

**Pros**:
- Simple implementation
- No async snapshot capture
- Pixel-perfect (no compression artifacts)
- Updates if needed (edge case)

**Cons**:
- Slightly higher memory during animation
- Widget still runs during transition

**Alternative**: Could capture as image using `RenderRepaintBoundary.toImage()`, but adds complexity for minimal gain given the brief animation duration.

### State Preservation Mechanism

1. **Data State**: Lives in GetX controllers (independent of widget lifecycle)
2. **Scroll Positions**: Restored via `PageStorageKey` + Flutter's PageStorage
3. **UI State**: Controllers provide reactive rebuilds
4. **Widget Tree**: Rebuilt from scratch each time (cheap operation)

---

## Testing Checklist

After implementation, verify:

- [ ] All 5 tabs switch correctly
- [ ] Circular reveal animation works on all transitions
- [ ] Scroll positions preserved when returning to tabs
- [ ] Cart state persists across navigation
- [ ] Order list maintained
- [ ] Explore fullscreen mode exits properly
- [ ] Running orders bottom sheet works
- [ ] Memory usage reduced (use Flutter DevTools)

---

## Rollback Plan

If issues occur, revert to original `IndexedStack` approach:

1. Restore `_screens` array in `initState()`
2. Replace optimized Stack with original IndexedStack
3. Remove `_getScreen()` method
4. Remove `_previousScreenCache` variable
5. Restore original `_setPage()` logic

---

## Notes

- Optimization is **backwards compatible** - no API changes
- No impact on user experience
- All existing features preserved
- Pure performance/memory win
