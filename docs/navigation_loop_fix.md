# Navigation Loop Bug Fix

**Date**: 2025-01-21
**Status**: ✅ Fixed
**Problematic Commit**: 4c8763f - "CartScreen revamp with tabbed navigation"

---

## Problem Description

After redesigning the CartScreen with tabbed navigation, the app entered an infinite navigation loop on launch:
- Home screen loads → immediately reloads → repeats infinitely
- GetX services repeatedly deleted and recreated
- Routes continuously switching between `/?from-splash=true` and `/?from-splash=false`

---

## Root Cause Analysis

### Investigation Process

Used `git bisect` to binary search through commits:

```
a660a22 ✅ GOOD - No loop
   ↓
aae7bd8 ✅ GOOD - RestaurantScreen changes
   ↓
287cce0 ✅ GOOD - BottomCartWidget layout
   ↓
7a39ace ✅ GOOD - BottomCartWidget gradient
   ↓
4c8763f ❌ BAD - CartScreen tabbed navigation revamp ← CULPRIT
   ↓
fc11edb ❌ BAD - Cart update logic (inherited bug)
```

**Result**: Commit `4c8763f` introduced the bug.

---

## Specific Issues Found

### 1. CartDetailsWidget - Missing Mounted Checks

**File**: `lib/features/cart/widgets/cart_details_widget.dart`

**Problem 1** - Timers without mounted checks (lines 47-57):
```dart
void _initialBottomSheetShowHide() {
  Future.delayed(const Duration(milliseconds: 600), () {
    if (key.currentState != null) {
      key.currentState!.expand();  // ← Calls _onExpanded()
    }
  }).then((_) {
    Future.delayed(const Duration(seconds: 3), () {
      if (key.currentState != null) {
        key.currentState!.contract();  // ← Calls _onContracted()
      }
    });
  });
}
```

**Problem 2** - setState() without mounted check:
```dart
void _onExpanded() {
  _getExpandedBottomSheetHeight();  // ← Contains setState()
}

void _onContracted() {
  setState(() { _height = 0; });  // ← NO MOUNTED CHECK!
}

void _getExpandedBottomSheetHeight() {
  if (_widgetKey.currentContext != null) {
    final RenderBox renderBox = _widgetKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    setState(() { _height = size.height; });  // ← NO MOUNTED CHECK!
  }
}
```

**Problem 3** - No dispose method:
- ScrollController not disposed
- Timers not cancelled

---

### 2. CartScreen - Missing Dispose

**File**: `lib/features/cart/screens/cart_screen.dart`

**Problem**: TabController not disposed
```dart
class _CartScreenState extends State<CartScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
  }

  // NO DISPOSE METHOD!
}
```

---

### 3. DashboardScreen - setState After Dispose

**File**: `lib/features/dashboard/screens/dashboard_screen.dart`

**Problem**: Multiple timers calling setState() without mounted checks
- Line 113: Empty setState() in initState timer
- Lines 128, 135, 150: setState() in bottom sheet callbacks
- Line 193: Timer modifying state

---

### 4. SplashController - Background Refresh Loop

**File**: `lib/features/splash/controllers/splash_controller.dart`

**Problem**: Background config refresh triggers navigation
```dart
if(response.statusCode == 200) {
  _handleConfigResponse(...);
  // Background refresh also calls route() → infinite loop!
  getConfigData(source: DataSourceEnum.client);
}
```

---

## Fixes Applied

### Fix 1: CartDetailsWidget

**Added mounted checks:**
```dart
void _onExpanded() {
  if (mounted) {  // ← ADDED
    _getExpandedBottomSheetHeight();
  }
}

void _onContracted() {
  if (mounted) {  // ← ADDED
    setState(() {
      _height = 0;
    });
  }
}

void _getExpandedBottomSheetHeight() {
  if (_widgetKey.currentContext != null && mounted) {  // ← ADDED mounted check
    final RenderBox renderBox = _widgetKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    setState(() {
      _height = size.height;
    });
  }
}
```

**Added dispose method:**
```dart
@override
void dispose() {
  scrollController.dispose();
  super.dispose();
}
```

---

### Fix 2: CartScreen

**Added dispose method:**
```dart
@override
void dispose() {
  _tabController.dispose();
  super.dispose();
}
```

---

### Fix 3: DashboardScreen

**Added mounted checks to all async setState calls:**
```dart
Future.delayed(const Duration(seconds: 1), () {
  if (mounted) {  // ← ADDED
    setState(() {});
  }
});

// Same for all bottom sheet callbacks and timers
```

---

### Fix 4: SplashController

**Added shouldNavigate parameter to prevent background refresh from navigating:**
```dart
Future<void> getConfigData({
  bool shouldNavigate = true,  // ← NEW parameter
  // ...
}) async {
  if(source == DataSourceEnum.local) {
    if(response.statusCode == 200) {
      _handleConfigResponse(..., shouldNavigate: shouldNavigate);
      // Background refresh doesn't navigate!
      getConfigData(source: DataSourceEnum.client, shouldNavigate: false);
    }
  }
}

void _handleConfigResponse(..., {required bool shouldNavigate}) {
  if(shouldNavigate) {  // ← Only navigate on initial load
    route(notificationBody: notificationBody, linkBody: linkBody);
  }
}
```

---

## Why This Caused the Loop

### The Cascade:

1. **App launches** → DashboardScreen created
2. **All 5 tabs created** (including CartScreen) in PageView
3. **CartScreen.initState()** runs even though tab not visible
4. **initCall()** fetches cart data, order history, restaurant details
5. **CartDetailsWidget created** when _showDetails = true (or always in new design)
6. **Timers start** in _initialBottomSheetShowHide()
7. **User navigates** or screen rebuilds
8. **Widgets disposed** but timers still running
9. **Timers fire** → call setState() on disposed widgets
10. **Flutter throws error** → triggers rebuild/navigation
11. **Dashboard recreates** → CartScreen.initState() runs again
12. **Loop repeats infinitely**

---

## Prevention Pattern

**Always follow this pattern for async operations:**

```dart
// 1. Check mounted before setState
Future.delayed(duration, () {
  if (mounted) {
    setState(() {});
  }
});

// 2. Dispose controllers and cancel timers
@override
void dispose() {
  _controller.dispose();
  _timer?.cancel();
  super.dispose();
}

// 3. Check mounted in callbacks
someAsyncOperation().then((value) {
  if (mounted) {
    setState(() {});
  }
});
```

---

## Testing Verification

After fixes applied:

- [x] App launches cleanly without loops
- [x] Home screen loads once and stays loaded
- [x] No setState() after dispose errors
- [x] No infinite navigation between splash and home
- [x] All tabs work correctly (including cart tab)
- [x] Cart screen functions properly
- [x] No GetX services being repeatedly deleted/recreated

---

## Files Modified

1. `lib/features/cart/widgets/cart_details_widget.dart`
   - Added mounted checks to _onExpanded(), _onContracted(), _getExpandedBottomSheetHeight()
   - Added dispose() method

2. `lib/features/cart/screens/cart_screen.dart`
   - Added dispose() method for TabController

3. `lib/features/dashboard/screens/dashboard_screen.dart`
   - Added mounted checks to 4 setState() calls in async callbacks

4. `lib/features/splash/controllers/splash_controller.dart`
   - Added shouldNavigate parameter to prevent background refresh navigation

---

## Lessons Learned

1. **Always check `mounted`** before calling setState() in async callbacks
2. **Always dispose controllers** (TabController, ScrollController, AnimationController)
3. **Test in PageView context** - widgets initialize even when not visible
4. **Watch for cascading rebuilds** - one error can trigger infinite loops
5. **Use git bisect** to find problematic commits efficiently

---

**End of Fix Documentation**
