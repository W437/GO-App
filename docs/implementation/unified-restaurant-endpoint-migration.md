# Unified Restaurant Endpoint Migration

## Date: November 24, 2025

## Overview
Migrated the frontend to use the new unified restaurant endpoint that consolidates three separate API calls into a single flexible endpoint.

## Changes Made

### 1. AppConstants Update
**File:** `lib/util/app_constants.dart`
- Added new constant: `unifiedRestaurantUri = '/api/v1/restaurants/unified'`
- Kept legacy endpoints for backward compatibility

### 2. RestaurantRepository Updates
**File:** `lib/features/restaurant/domain/repositories/restaurant_repository.dart`

#### getList Method (All Restaurants)
- Updated to use: `${AppConstants.unifiedRestaurantUri}?preset=all`
- Added offset conversion: Frontend uses 0-based indexing, API uses 1-based
- Default limit: 25 (or 20 for map view)

#### _getPopularRestaurantList Method
- Updated to use: `${AppConstants.unifiedRestaurantUri}?preset=popular`
- Default limit: 50
- Handles both array response (legacy) and object response (unified)

#### _getLatestRestaurantList Method
- Updated to use: `${AppConstants.unifiedRestaurantUri}?preset=latest`
- Default limit: 20
- Handles both array response (legacy) and object response (unified)

## API Call Examples

### Before (3 separate endpoints):
```dart
// All restaurants
GET /api/v1/restaurants/get-restaurants/all?offset=0&limit=12

// Popular restaurants
GET /api/v1/restaurants/popular?type=all

// Latest restaurants
GET /api/v1/restaurants/latest?type=all
```

### After (unified endpoint):
```dart
// All restaurants
GET /api/v1/restaurants/unified?preset=all&offset=1&limit=25

// Popular restaurants
GET /api/v1/restaurants/unified?preset=popular&type=all&limit=50&offset=1

// Latest restaurants
GET /api/v1/restaurants/unified?preset=latest&type=all&limit=20&offset=1
```

## Key Implementation Details

1. **Offset Handling:** The unified API uses 1-based offset (1 = first page), while the frontend uses 0-based. Conversion is handled in the repository layer.

2. **Response Handling:** The methods handle both legacy array responses and new object responses with `restaurants` field for backward compatibility.

3. **Limits:** Default limits match the documentation:
   - all: 25 items
   - popular: 50 items
   - latest: 20 items

## Testing Checklist
- [ ] Verify all restaurants load on home screen
- [ ] Test popular restaurants section
- [ ] Test latest restaurants section
- [ ] Verify pagination works correctly
- [ ] Check filters (veg, non-veg, discount, top-rated)
- [ ] Confirm restaurant details still load when clicked

## Notes
- Legacy endpoints remain available for rollback if needed
- The unified endpoint reduces complexity and prepares for future batch endpoint optimization
- Headers (zoneId, longitude, latitude) are handled by the existing ApiClient configuration