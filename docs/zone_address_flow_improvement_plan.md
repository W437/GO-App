# Zone/Address Selection Flow Improvement Plan

## Summary
Improve the zone/address selection UX with zone-first onboarding, smart defaults for returning users, and better visual feedback. Also includes a **breaking API change** fix.

## Requirements
1. **Zone-first onboarding**: New users see only Zone mode initially
2. **Smart default mode**: Zone mode if no address saved, Address mode if they have one
3. **Pulsing notification badge**: Animated red dot on "Address" tab when no address is set
4. **Zone always visible**: In Address mode, show zone name combined with address (e.g., "Shefa-Amr - 123 Main St")
5. **Dashboard access**: From dashboard, users can open map to change zone or add/edit/select address
6. **API Fix**: Update `update-zone` endpoint from GET to PUT (breaking change from backend)

---

## Files to Modify (4 files)

### 1. `lib/helper/business_logic/address_helper.dart`
**Add helper method to check if user has a "real" address (not just zone selection)**

```dart
/// Check if user has a real address saved (not just zone selection)
static bool hasRealAddress() {
  final address = getAddressFromSharedPref();
  return address != null &&
         address.addressType != 'zone' &&
         address.address != null &&
         address.address!.isNotEmpty;
}
```

---

### 2. `lib/common/widgets/shared/buttons/custom_tabbed_button.dart`
**Add pulsing badge support to tab items**

**A) Update `TabbedButtonItem` class** - add `showBadge` property:
```dart
class TabbedButtonItem {
  final String label;
  final IconData? icon;
  final bool showBadge;  // NEW

  const TabbedButtonItem({
    required this.label,
    this.icon,
    this.showBadge = false,
  });
}
```

**B) Modify `_buildTab` method** - wrap content in Stack with badge:
- Add `Positioned` badge widget when `item.showBadge` is true
- Position badge at top-right corner of the tab

**C) Add private `_PulsingBadge` StatefulWidget**:
- AnimationController with 1200ms duration, repeat(reverse: true)
- Opacity animation from 0.6 to 1.0 with easeInOut curve
- 8x8 red circle with matching glow shadow
- Proper dispose() cleanup

---

### 3. `lib/features/location/screens/pick_map_screen.dart`
**Core integration - smart defaults, badge trigger, combined zone/address display**

**A) Change default mode initialization** (line ~87):
```dart
// FROM:
MapMode _currentMode = MapMode.zoneSelection;

// TO:
late MapMode _currentMode;  // Set in initState based on address state
```

**B) Add smart mode detection in `initState()`** (after saved zone check):
```dart
// Determine initial mode based on whether user has a "real" address
if (AddressHelper.hasRealAddress()) {
  _currentMode = MapMode.addressSelection;
} else {
  _currentMode = MapMode.zoneSelection;
}
```

**C) Add helper method for combined zone/address display**:
```dart
String _getDisplayAddress(String address) {
  final locationController = Get.find<LocationController>();
  final zoneName = locationController.activeZone?.displayName ??
                   locationController.activeZone?.name;
  final cleanAddress = _getAddressWithoutCountry(address);

  if (zoneName != null && zoneName.isNotEmpty && cleanAddress.isNotEmpty) {
    return '$zoneName - $cleanAddress';
  }
  return cleanAddress;
}
```

**D) Update CustomTabbedButton items** (line ~784):
```dart
CustomTabbedButton(
  items: [
    const TabbedButtonItem(label: 'Zone', icon: Icons.map),
    TabbedButtonItem(
      label: 'Address',
      icon: Icons.location_on,
      showBadge: !AddressHelper.hasRealAddress(),  // Pulsing badge when no real address
    ),
  ],
  // ... rest unchanged
)
```

**E) Update address badge display** (line ~660):
```dart
// FROM:
_getAddressWithoutCountry(locationController.pickAddress ?? '')

// TO:
_getDisplayAddress(locationController.pickAddress ?? '')
```

---

## Implementation Order

1. **PRIORITY**: `location_repo.dart` - Fix API breaking change (GET → PUT)
2. **Second**: `address_helper.dart` - Add `hasRealAddress()` (no dependencies)
3. **Third**: `custom_tabbed_button.dart` - Add badge support (no dependencies)
4. **Fourth**: `pick_map_screen.dart` - Integrate all features (depends on #2 and #3)

---

## Edge Cases to Handle

| Scenario | Expected Behavior |
|----------|-------------------|
| First app launch (no address) | Zone mode, badge pulses on Address tab |
| Zone-only selection (`addressType: 'zone'`) | Zone mode, badge shows |
| Real address saved (`home`/`office`/`others`) | Address mode, no badge |
| Empty address string | Treat as zone-only |
| Zone name unavailable (`activeZone` null) | Show address without zone prefix |
| Badge state after saving address | Badge disappears on rebuild |

---

## Testing Checklist

- [ ] New user opens map → Zone mode, pulsing badge on Address tab
- [ ] User with zone-only opens map → Zone mode, badge visible
- [ ] User with home address opens map → Address mode, no badge
- [ ] Badge animation: smooth pulse (0.6 → 1.0 opacity, 1.2s cycle)
- [ ] Address displays as "Zone Name - Street Address" format
- [ ] Address displays without zone when zone name is null
- [ ] Dashboard location button opens map with correct default mode
- [ ] Mode switching works correctly in both directions

---

## Critical Files Reference

| File | Read Before Implementing |
|------|--------------------------|
| `lib/helper/business_logic/address_helper.dart` | Yes - understand existing methods |
| `lib/common/widgets/shared/buttons/custom_tabbed_button.dart` | Yes - already read |
| `lib/features/location/screens/pick_map_screen.dart` | Yes - already read |
| `lib/features/location/controllers/location_controller.dart` | Reference - `activeZone` getter |
| `lib/features/location/domain/reposotories/location_repo.dart` | Yes - API call change |

---

## PRIORITY: API Breaking Change Fix

### 4. `lib/features/location/domain/reposotories/location_repo.dart`
**Fix breaking change: update-zone endpoint now requires PUT instead of GET**

**Change line 68-70:**
```dart
// FROM (broken):
@override
Future<Response> updateZone() async {
  return await apiClient.getData(AppConstants.updateZoneUri);
}

// TO (fixed):
@override
Future<Response> updateZone() async {
  return await apiClient.putData(AppConstants.updateZoneUri, {});
}
```

**Note:** The `putData` method requires a body parameter. Since this endpoint uses headers for zone data (already handled by ApiClient), we pass an empty map `{}`.

### Also check `location_repo_interface.dart`
The interface signature should remain the same (`Future<Response> updateZone()`), but verify it exists.
