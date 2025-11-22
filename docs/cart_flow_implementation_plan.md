# Cart Flow Redesign - Implementation Plan

**Status:** ✅ Backend Verified - Ready to Start Phase 1
**Timeline:** 12 weeks (3 months)
**Last Updated:** 2025-11-22

---

## Executive Summary

This document outlines the implementation plan for redesigning the cart → checkout flow from a **single-restaurant cart system** to a **multi-restaurant cart overview** with enhanced checkout experience as defined in `cart_flow.md`.

### Critical Findings

1. **Multi-Restaurant Cart Conflict (BLOCKER)**
   - Current: App prevents multi-restaurant carts via `existAnotherRestaurantProduct` check
   - Desired: Screen A lists multiple restaurant carts simultaneously
   - **Action Required:** Backend verification (see Backend Verification Prompt below)

2. **Completion Status**
   - Screen A (Your Orders): ~70% complete - exists but single-restaurant only
   - Screen B (Order Details): ~40% complete - embedded inline, missing special instructions
   - Screen C (Checkout): ~35% complete - missing map, mode tabs, visual improvements

3. **Google Maps:** ✅ Already integrated - can be reused for checkout map

---

## Backend Verification Prompt

**Send this to backend team before starting implementation:**

```
I need to verify if our backend supports multi-restaurant cart functionality for our Flutter app redesign.

Please check the following:

1. MULTI-RESTAURANT CARTS:
   - Can a single user have active cart items from multiple different restaurants simultaneously?
   - Current API: GET /api/v1/customer/cart - does this return items grouped by restaurant, or just a flat list?
   - When adding items via POST /api/v1/customer/cart/add, is there any restriction preventing items from different restaurants?

2. CART DATA STRUCTURE:
   - Does the cart model include a restaurantId field at the cart level (not just product.restaurantId)?
   - Does cart support storing per-cart special instructions/notes (separate from global order notes)?

3. REQUIRED NEW FIELDS:
   We need these fields in the order placement API:
   - `leave_at_door` (boolean) - for delivery orders
   - `is_gift` (boolean) - if order is a gift
   - `gift_recipient_name`, `gift_recipient_phone`, `gift_message` (strings) - gift recipient info

   Are these supported or can they be added easily?

4. ADDRESS VALIDATION:
   - Is there an endpoint to validate if a delivery address is within a restaurant's zone before placing order?
   - Or should we rely on client-side distance calculations?

Please provide:
- Current capabilities vs what needs to be implemented
- Estimated effort for any backend changes needed
- Any breaking changes or migration concerns
- API contract examples if changes are needed
```

**Backend Response:** ✅ **VERIFIED - All Requirements Met + BONUS**

**Implemented Changes:**

1. ✅ **Gift Order Fields** (all optional in orders table):
   - `leave_at_door` (boolean, default: false)
   - `is_gift` (boolean, default: false)
   - `gift_recipient_name` (string, nullable)
   - `gift_recipient_phone` (string, nullable)
   - `gift_message` (text, nullable)

2. ✅ **Per-Item Special Instructions** (NEW - bonus feature!):
   - `special_instructions` (text) field added to carts table
   - Can be set when adding/updating cart items
   - Returned in GET /api/v1/customer/cart
   - Enables per-item kitchen notes (e.g., "extra spicy", "no onions")

3. ✅ **Multi-Restaurant Cart Behavior:**
   - Users CAN add items from different restaurants to cart
   - Cart API returns flat list (frontend will group by restaurant_id)
   - Order placement supports SINGLE restaurant per order (perfect for our flow)
   - Attempting mixed-restaurant checkout will fail (expected behavior)

4. ℹ️ **Address Validation:**
   - Handle client-side for now (deferred to later phase)

**API Endpoints Updated:**
- POST /api/v1/customer/cart/add - now accepts `special_instructions`
- POST /api/v1/customer/cart/update - now accepts `special_instructions`
- GET /api/v1/customer/cart - now returns `special_instructions` per item
- POST /api/v1/customer/order/place - accepts all 5 gift fields

---

## Current State Analysis

### Screen A: Your Orders (Cart Overview)
**File:** `lib/features/cart/screens/cart_screen.dart`

**Current Implementation:**
- ✅ Header with "Your orders" title and Edit button
- ✅ Segmented control (Shopping carts / Order again tabs)
- ✅ `CartSummaryCard` widget matches blueprint design
- ❌ Only shows single restaurant cart (comment on line 30: "Assuming single restaurant cart for now")
- ❌ Cart details shown inline (`_showDetails` flag) instead of navigating to Screen B

**Gap:** Need to show list of carts grouped by restaurant

---

### Screen B: Order Details (Per-Restaurant Cart)
**File:** `lib/features/cart/widgets/cart_details_widget.dart` (currently embedded)

**Current Implementation:**
- ✅ Order items list with quantity, options, price
- ✅ Suggested items section
- ✅ "Add more" button (navigates to restaurant menu)
- ✅ Bottom bar with pricing and checkout button
- ❌ Not a separate screen - embedded in cart_screen
- ❌ **Missing:** "Add a message for the restaurant" section
  - Current: `orderNote` is in checkout, not cart-specific
  - Needed: Per-cart `specialInstructions` field

**Gap:** Extract to standalone screen, add special instructions widget

---

### Screen C: Checkout (Address & Payment)
**File:** `lib/features/checkout/screens/checkout_screen.dart`

**Current Implementation:**
- ✅ Delivery/Pickup/Dine-in selection (via `DeliveryOptionButton`)
- ✅ Address selection (via `DeliverySection`)
- ✅ Time slot selection (standard/scheduled)
- ✅ Payment method selection
- ✅ Tip support (via `DeliveryManTipsSection`)
- ✅ Summary section
- ❌ **Missing:** Prominent map view at top (showing restaurant + delivery address)
- ❌ **Missing:** Map-based mode tabs (Delivery/Pickup toggle over map)
- ❌ **Missing:** "Leave order at the door" toggle
- ❌ **Missing:** "Send as a gift" option
- ❌ **Missing:** Visual tip selector with pills (₪0, ₪5, ₪10, Custom)
- ❌ **Missing:** Conditional CTA ("Add delivery address" vs "Pay with [method]")

**Gap:** Major UI overhaul with map integration and enhanced widgets

---

## Data Model Changes Required

### 1. New Models

#### RestaurantCart (NEW)
**File:** `lib/features/cart/domain/models/restaurant_cart_model.dart`

```dart
class RestaurantCart {
  final int restaurantId;
  final RestaurantModel restaurant;
  final List<CartModel> items;
  final double subtotal;
  final String? specialInstructions;
  final bool isActive;

  RestaurantCart({
    required this.restaurantId,
    required this.restaurant,
    required this.items,
    required this.subtotal,
    this.specialInstructions,
    this.isActive = true,
  });

  int get itemCount => items.fold(0, (sum, item) => sum + (item.quantity ?? 0));
}
```

#### CheckoutSession (NEW)
**File:** `lib/features/checkout/domain/models/checkout_session_model.dart`

```dart
class CheckoutSession {
  final int restaurantId;
  String mode; // 'delivery', 'take_away'
  int? selectedAddressId;
  String timeOption; // 'standard', 'scheduled'
  DateTime? scheduledTime;
  double tipAmount;
  String? paymentMethod;
  bool leaveAtDoor;
  bool isGift;
  Map<String, String>? giftInfo; // name, phone, message

  CheckoutSession({
    required this.restaurantId,
    this.mode = 'delivery',
    this.selectedAddressId,
    this.timeOption = 'standard',
    this.scheduledTime,
    this.tipAmount = 0,
    this.paymentMethod,
    this.leaveAtDoor = false,
    this.isGift = false,
    this.giftInfo,
  });
}
```

### 2. Enhanced Models

#### CartModel Enhancement
**File:** `lib/features/cart/domain/models/cart_model.dart`

```dart
// ADD THESE FIELDS:
String? specialInstructions;  // Per-cart notes
int? restaurantId;             // Direct reference (optional if backend provides)
String? cartStatus;            // 'active', 'offline' (optional)
```

#### PlaceOrderBodyModel Enhancement
**File:** `lib/features/checkout/domain/models/place_order_body_model.dart`

```dart
// ADD THESE FIELDS:
bool? leaveAtDoor;
bool? isGift;
String? giftRecipientName;
String? giftRecipientPhone;
String? giftMessage;
```

---

## Controller Restructuring

### CartController Changes
**File:** `lib/features/cart/controllers/cart_controller.dart`

**New State:**
```dart
// REPLACE: List<CartModel> _cartList;
// WITH:
Map<int, RestaurantCart> _restaurantCarts = {};

List<RestaurantCart> get restaurantCarts => _restaurantCarts.values.toList();
RestaurantCart? get currentCart => _currentRestaurantId != null
  ? _restaurantCarts[_currentRestaurantId]
  : null;
```

**New Methods:**
```dart
void groupCartsByRestaurant(List<CartModel> items);
void setCartSpecialInstructions(int restaurantId, String instructions);
RestaurantCart? getCartForRestaurant(int restaurantId);
List<int> getActiveRestaurantIds();
Future<void> updateCartInstructions(int restaurantId, String instructions);
```

### CheckoutController Changes
**File:** `lib/features/checkout/controllers/checkout_controller.dart`

**New State:**
```dart
Map<int, CheckoutSession> _checkoutSessions = {};
int? _currentRestaurantId;

CheckoutSession? get currentSession => _currentRestaurantId != null
  ? _checkoutSessions[_currentRestaurantId]
  : null;
```

**New Methods:**
```dart
void initCheckoutSession(int restaurantId);
void updateCheckoutMode(String mode);
void setLeaveAtDoor(bool value);
void setGiftOrder(bool value, {Map<String, String>? giftInfo});
void updateSelectedAddress(int addressId);
```

---

## API Integration Changes

### Cart Repository
**File:** `lib/features/cart/domain/repositories/cart_repository_interface.dart`

**New Endpoints:**
```dart
// IF backend supports grouping:
Future<Response> getGroupedCarts(String? guestId);

// OR implement client-side grouping:
Map<int, RestaurantCart> groupCartsByRestaurant(List<OnlineCartModel> carts);

// Per-cart instructions:
Future<Response> updateCartInstructions({
  required int restaurantId,
  required String instructions,
  String? guestId,
});
```

### Checkout Repository
**File:** `lib/features/checkout/domain/repositories/checkout_repository_interface.dart`

**New Endpoints:**
```dart
// Address validation (if backend provides):
Future<Response> validateDeliveryAddress({
  required int restaurantId,
  required int addressId,
});
```

---

## Widget Implementations

### New Widgets to Create

1. **MapCheckoutHeaderWidget**
   - **File:** `lib/features/checkout/widgets/map_checkout_header_widget.dart`
   - **Purpose:** Map view + mode tabs (Delivery/Pickup)
   - **Features:** Restaurant pin, address pin, route, mode switching

2. **MessageToRestaurantWidget**
   - **File:** `lib/features/cart/widgets/message_to_restaurant_widget.dart`
   - **Purpose:** Special instructions input for Screen B
   - **Features:** Chat bubble icon, title, subtitle, chevron

3. **DeliveryOptionsCardWidget**
   - **File:** `lib/features/checkout/widgets/delivery_options_card_widget.dart`
   - **Purpose:** Address selection + toggles
   - **Features:** Address row, "Leave at door" toggle, "Send as gift" row

4. **CourierTipSelectorWidget**
   - **File:** `lib/features/checkout/widgets/courier_tip_selector_widget.dart`
   - **Purpose:** Visual tip selection
   - **Features:** Pills (₪0, ₪5, ₪10, ₪15, Custom), custom input dialog

5. **ConditionalCheckoutCTAWidget**
   - **File:** `lib/features/checkout/widgets/conditional_checkout_cta_widget.dart`
   - **Purpose:** Smart checkout button
   - **Features:** "Add delivery address" vs "Pay with [method]" logic

6. **BottomCartBarWidget**
   - **File:** `lib/features/cart/widgets/bottom_cart_bar_widget.dart`
   - **Purpose:** Bottom bar for Screen B
   - **Features:** Item count, subtotal, "Go to checkout" CTA

---

## Implementation Phases

### Phase 1: Foundation & Data Models (Weeks 1-2)

**Goal:** Prepare data layer without breaking existing functionality

**Tasks:**
1. ✅ Verify backend capabilities (BLOCKER - must complete first)
2. Create new models:
   - [ ] `RestaurantCart` model
   - [ ] `CheckoutSession` model
3. Enhance existing models (nullable fields for compatibility):
   - [ ] Add `specialInstructions`, `restaurantId` to `CartModel`
   - [ ] Add `leaveAtDoor`, `isGift`, gift fields to `PlaceOrderBodyModel`
4. Update `CartController`:
   - [ ] Add `_restaurantCarts` map (populate alongside `_cartList`)
   - [ ] Implement `groupCartsByRestaurant()` method
   - [ ] Keep all existing methods working
5. Coordinate with backend:
   - [ ] Confirm multi-restaurant cart support
   - [ ] Define API contracts for new endpoints
   - [ ] Implement per-cart instructions endpoint (backend)
6. Testing:
   - [ ] Unit tests for cart grouping logic
   - [ ] Test backward compatibility

**Deliverables:**
- New model files created
- Controllers enhanced (backward compatible)
- API documentation updated
- Tests passing

**Feature Flag:** `ENABLE_MULTI_RESTAURANT_CARTS = false` (not enabled yet)

**Risk Mitigation:**
- Existing flow continues to work
- New data structures populated in parallel
- Can rollback by disabling feature flag

---

### Phase 2: Screen B - Order Details (Weeks 3-4)

**Goal:** Create standalone order details screen with special instructions

**Tasks:**
1. Create new screen:
   - [ ] `OrderDetailsScreen` (`lib/features/cart/screens/order_details_screen.dart`)
   - [ ] Extract logic from `CartDetailsWidget`
   - [ ] Add header with restaurant name + "Your order" subtitle
2. Create new widgets:
   - [ ] `MessageToRestaurantWidget` (special instructions input)
   - [ ] `BottomCartBarWidget` (item count + checkout CTA)
3. Update routing:
   - [ ] Add `/order-details?restaurant_id={id}` route
   - [ ] Update `RouteHelper.getOrderDetailsRoute(int restaurantId)`
4. Wire up special instructions:
   - [ ] Save to `CartController`
   - [ ] Sync with backend (if API ready)
   - [ ] Display saved instructions
5. Navigation testing:
   - [ ] Screen A → Screen B (tap "View cart")
   - [ ] Screen B → Screen A (back button)
   - [ ] Screen B → Restaurant Menu (tap "Add more")
   - [ ] Screen B → Screen C (tap "Go to checkout")
6. Widget testing:
   - [ ] Test `MessageToRestaurantWidget` input/save
   - [ ] Test bottom bar calculations
   - [ ] Test recommended items section

**Deliverables:**
- `OrderDetailsScreen` fully functional
- Navigation flow working
- Special instructions saving to backend
- Widget tests passing

**Risk Mitigation:**
- Keep old `cart_screen` inline view as fallback
- Feature flag: `ENABLE_ORDER_DETAILS_SCREEN`
- Gradual rollout to beta users first

---

### Phase 3: Screen A - Multi-Restaurant Support (Weeks 5-6)

**Goal:** Enable multi-restaurant cart listing

**Tasks:**
1. Refactor `CartScreen`:
   - [ ] Remove `_showDetails` inline logic
   - [ ] Replace single cart view with `ListView.builder`
   - [ ] Show `CartSummaryCard` for each restaurant
   - [ ] Handle empty state (no carts)
2. Remove multi-restaurant restrictions:
   - [ ] Update `existAnotherRestaurantProduct()` logic
   - [ ] Allow adding items from different restaurants
   - [ ] Show confirmation dialog: "Start a new cart with [Restaurant]?"
3. Backend integration:
   - [ ] Use grouped carts API (or implement client-side grouping)
   - [ ] Fetch restaurant data for each cart
   - [ ] Handle cart syncing per restaurant
4. Restaurant status handling:
   - [ ] Show "Temporarily offline" on cart cards
   - [ ] Gray out or disable offline carts
   - [ ] Allow viewing but block checkout for offline restaurants
5. Edge case testing:
   - [ ] Empty cart state
   - [ ] Single restaurant (should look same as before)
   - [ ] Multiple restaurants (new behavior)
   - [ ] Restaurant goes offline while in cart
   - [ ] Cart cleared from another device
6. Integration testing:
   - [ ] Add items from Restaurant A
   - [ ] Add items from Restaurant B
   - [ ] Verify both show on Screen A
   - [ ] Checkout Restaurant A, verify Restaurant B still in cart

**Deliverables:**
- Screen A displaying multiple restaurant carts
- Multi-restaurant cart support working end-to-end
- Restaurant offline handling implemented
- Integration tests passing

**Feature Flag:** Enable `ENABLE_MULTI_RESTAURANT_CARTS = true`

**Risk Mitigation:**
- Phased rollout by user percentage (10% → 50% → 100%)
- Monitor crash rates and cart conversion
- Fallback to single-restaurant mode if critical issues
- A/B test to compare metrics

---

### Phase 4: Screen C - Enhanced Checkout (Weeks 7-10)

**Goal:** Implement map-based checkout with all blueprint features

**Week 7-8: Map & Mode Switching**
1. Create `MapCheckoutHeaderWidget`:
   - [ ] Integrate Google Maps (reuse existing SDK)
   - [ ] Show restaurant pin (fixed position)
   - [ ] Show user address pin (dynamic based on selection)
   - [ ] Draw route/polyline between pins
   - [ ] Calculate and display distance
2. Implement mode tabs:
   - [ ] Segmented control: Delivery / Pickup
   - [ ] Position over or under map
   - [ ] Update map on mode change (hide address pin for Pickup)
3. Map optimization:
   - [ ] Lazy load map (only when checkout screen visible)
   - [ ] Cache map tiles
   - [ ] Static map fallback for low-end devices
   - [ ] Test memory usage (target: < 200MB)

**Week 8-9: Delivery Options & Widgets**
4. Create `DeliveryOptionsCardWidget`:
   - [ ] "Choose a delivery address" row
   - [ ] Address selection dialog
   - [ ] "Leave order at the door" toggle
   - [ ] "Send as a gift" row (opens gift dialog)
5. Create `CourierTipSelectorWidget`:
   - [ ] Visual pills: ₪0, ₪5, ₪10, ₪15, Custom
   - [ ] Highlight selected tip
   - [ ] Custom tip input dialog
   - [ ] Integration with `CheckoutController`
6. Create gift order flow:
   - [ ] Gift info dialog (recipient name, phone, message)
   - [ ] Save to `CheckoutSession`
   - [ ] Display in order summary
   - [ ] Send in `PlaceOrderBodyModel`

**Week 9-10: Checkout Session & CTA**
7. Implement `CheckoutSession` management:
   - [ ] Initialize session when entering checkout
   - [ ] Persist session per restaurant
   - [ ] Restore session if user navigates back
   - [ ] Clear session after successful order
8. Create `ConditionalCheckoutCTAWidget`:
   - [ ] Show "Add delivery address" if `selectedAddressId == null` (Delivery mode)
   - [ ] Show "Pay with [method]" if address selected
   - [ ] Show "Pay with [method]" always (Pickup mode)
   - [ ] Disable if restaurant offline
   - [ ] Handle tap: open address selector OR place order
9. Refactor `CheckoutScreen` layout:
   - [ ] Top: `MapCheckoutHeaderWidget`
   - [ ] Middle: Scrollable options (delivery, time, payment, tip, summary)
   - [ ] Bottom: `ConditionalCheckoutCTAWidget`
   - [ ] Responsive layout (mobile/tablet/desktop)
10. Mode switching logic:
    - [ ] Delivery → Pickup: Collapse address sections, update map
    - [ ] Pickup → Delivery: Restore address sections, show pins
    - [ ] Update pricing calculations based on mode
11. Testing:
    - [ ] Test on physical devices (iOS/Android)
    - [ ] Test on emulators with different specs
    - [ ] Memory profiling (map impact)
    - [ ] Navigation flow: B → C → B (back) → C
    - [ ] Mode switching behavior
    - [ ] Address validation
    - [ ] Gift order placement
    - [ ] Tip calculations

**Deliverables:**
- Full Screen C matching blueprint
- All new widgets created and tested
- Map integration performant (< 2s load time)
- CheckoutSession working
- E2E tests covering all scenarios
- Performance benchmarks met

**Risk Mitigation:**
- Progressive enhancement: basic checkout works, map is optional
- Feature flag: `ENABLE_MAP_CHECKOUT`
- Static map fallback: `USE_STATIC_MAP_FALLBACK`
- Device capability detection (disable map on low-memory devices)
- Monitor performance metrics in production

---

### Post-Implementation: Polish & Optimization (Weeks 11-12)

**Goal:** Final polish, performance, accessibility

**Tasks:**
1. Animation polish:
   - [ ] Screen transitions (A → B → C)
   - [ ] Mode switching animations
   - [ ] Map pin animations
   - [ ] Tip pill selection animations
2. Error handling:
   - [ ] Offline mode support
   - [ ] API failure graceful degradation
   - [ ] Invalid address handling
   - [ ] Restaurant offline during checkout
   - [ ] Payment failures
3. Accessibility:
   - [ ] Screen reader labels (Semantics)
   - [ ] Sufficient color contrast (WCAG AA)
   - [ ] Touch target sizes (min 48x48)
   - [ ] Keyboard navigation support (web/desktop)
4. Performance optimization:
   - [ ] Profile with Flutter DevTools
   - [ ] Reduce unnecessary rebuilds
   - [ ] Image caching and lazy loading
   - [ ] Code splitting for heavy widgets
5. Documentation:
   - [ ] Update developer documentation
   - [ ] API integration guide
   - [ ] Widget usage examples
   - [ ] Troubleshooting guide
6. Final testing:
   - [ ] E2E regression tests
   - [ ] Cross-platform testing (iOS/Android/Web)
   - [ ] User acceptance testing (UAT)
   - [ ] Load testing (multiple carts, large orders)

**Deliverables:**
- Production-ready code
- Performance benchmarks met
- Accessibility compliance
- Complete documentation
- Test coverage > 80%

---

## Feature Flags

```dart
class FeatureFlags {
  // Phase 1
  static bool get enableMultiRestaurantCarts =>
    _getFlag('ENABLE_MULTI_RESTAURANT_CARTS', defaultValue: false);

  // Phase 2
  static bool get enableOrderDetailsScreen =>
    _getFlag('ENABLE_ORDER_DETAILS_SCREEN', defaultValue: false);

  static bool get enablePerCartInstructions =>
    _getFlag('ENABLE_PER_CART_INSTRUCTIONS', defaultValue: false);

  // Phase 4
  static bool get enableMapCheckout =>
    _getFlag('ENABLE_MAP_CHECKOUT', defaultValue: false);

  static bool get enableGiftOrders =>
    _getFlag('ENABLE_GIFT_ORDERS', defaultValue: false);

  // Performance
  static bool get useStaticMapFallback =>
    _getFlag('USE_STATIC_MAP_FALLBACK', defaultValue: false);
}
```

**Usage:**
- Store flags in Firebase Remote Config or local config
- Enable progressively for user segments
- A/B test new vs old flows
- Quick rollback if issues detected

---

## Success Metrics

### User Engagement
- **Multi-restaurant cart adoption:** % of users with items from 2+ restaurants
- **Checkout time:** Average time from cart view to order placed (target: < 2 min)
- **Completion rate:** % of checkouts that result in successful order (target: > 85%)

### Performance
- **Screen load time:**
  - Cart Screen (A): < 1s
  - Order Details (B): < 1s
  - Checkout Screen (C): < 2s (including map)
- **Memory usage:** < 200MB app-wide
- **Map render time:** < 1s

### Business
- **Order conversion rate:** % increase in orders placed
- **Average order value (AOV):** Impact of multi-restaurant carts
- **Restaurant diversity:** Average restaurants per user per week

### Technical
- **Crash rate:** < 0.5%
- **API error rate:** < 1%
- **Test coverage:** > 80%

---

## Risk Matrix

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Backend doesn't support multi-restaurant | HIGH | CRITICAL | Verify in Phase 1; use sequential checkout fallback |
| Map performance issues | MEDIUM | HIGH | Static map fallback; lazy loading; device detection |
| Navigation breaking changes | MEDIUM | MEDIUM | Comprehensive testing; backward compatibility |
| State management complexity | MEDIUM | MEDIUM | Controller refactoring; proper separation of concerns |
| API version mismatch | LOW | HIGH | Versioned endpoints; nullable fields; feature flags |
| User confusion with new flow | MEDIUM | MEDIUM | User testing; onboarding tooltips; gradual rollout |

---

## Alternative Approaches

### If Multi-Restaurant Backend NOT Supported

**Option A: Sequential Checkout (Recommended)**
- User can have multiple restaurant carts
- Can only checkout one at a time
- Screen A shows all carts
- After order placed, return to Screen A for next restaurant
- Still implements Screen B and C enhancements

**Option B: Single-Cart with Warning**
- Keep `existAnotherRestaurant` check
- Show warning: "Clear cart from [Restaurant X] to add from [Restaurant Y]?"
- Only one active cart at a time
- Simpler implementation, but doesn't match full blueprint

---

## Dependencies & Prerequisites

### Backend Dependencies
- [ ] Multi-restaurant cart API support verified
- [ ] Per-cart special instructions endpoint
- [ ] New PlaceOrderBody fields supported
- [ ] Address validation endpoint (optional)

### Frontend Dependencies
- [x] Google Maps SDK integrated
- [ ] GetX state management (already in use)
- [ ] Existing cart/checkout controllers refactored
- [ ] Feature flag system (Firebase Remote Config or local)

### Design Dependencies
- [ ] Final map UI design review
- [ ] Mode toggle visual design
- [ ] Tip selector design
- [ ] Gift order flow UX

---

## Timeline Summary

| Phase | Duration | Start | End | Status |
|-------|----------|-------|-----|--------|
| Phase 1: Foundation | 2 weeks | 2025-11-22 | 2025-11-22 | ✅ **COMPLETED** |
| Phase 2: Screen B | 2 weeks | TBD | TBD | ⏳ Ready to Start |
| Phase 3: Screen A | 2 weeks | TBD | TBD | ⏳ Blocked by Phase 2 |
| Phase 4: Screen C | 4 weeks | TBD | TBD | ⏳ Blocked by Phase 3 |
| Polish & Testing | 2 weeks | TBD | TBD | ⏳ Blocked by Phase 4 |
| **Total** | **12 weeks** | **2025-11-22** | **TBD** | **✅ Phase 1 Complete - Phase 2 Ready** |

---

## Phase 1 Completion Summary

**Status:** ✅ COMPLETED (2025-11-22)

**Files Created:**
1. `lib/features/cart/domain/models/restaurant_cart_model.dart` - RestaurantCart model for grouping cart items by restaurant
2. `lib/features/checkout/domain/models/checkout_session_model.dart` - CheckoutSession model for managing per-restaurant checkout state
3. `lib/helper/utilities/feature_flags.dart` - Feature flag system for gradual rollout
4. `test/features/cart/cart_grouping_test.dart` - Unit tests for cart grouping logic

**Files Modified:**
1. `lib/features/checkout/domain/models/place_order_body_model.dart` - Added gift order fields (leaveAtDoor, isGift, giftRecipientName, giftRecipientPhone, giftMessage)
2. `lib/features/cart/controllers/cart_controller.dart` - Added multi-restaurant cart grouping logic, new getters, and helper methods

**Key Features Implemented:**
- ✅ RestaurantCart model with itemCount, canOrder, copyWith, clearInstructions
- ✅ CheckoutSession model with isReadyForCheckout, copyWith, reset
- ✅ PlaceOrderBodyModel enhanced with 5 new optional gift fields
- ✅ CartController enhanced with:
  - `_restaurantCarts` map for multi-restaurant support
  - `groupCartsByRestaurant()` method
  - `getCartForRestaurant()` getter
  - `getActiveRestaurantIds()` getter
  - `setCartSpecialInstructions()` method
  - Automatic grouping after `getCartDataOnline()`
- ✅ Feature flags system with 8 flags for controlling rollout
- ✅ Unit tests covering RestaurantCart model and grouping logic

**Backward Compatibility:**
- ✅ Existing `_cartList` maintained alongside new `_restaurantCarts`
- ✅ All existing cart methods continue to work unchanged
- ✅ Feature flags default to `false` (existing behavior)
- ✅ No breaking changes to existing code

**Ready for Phase 2:**
- Backend API supports all required fields
- Data models ready for Screen B implementation
- Cart grouping logic tested and working
- Feature flags in place for safe rollout

---

## Next Steps

1. ✅ **Send backend verification prompt** (see top of document)
2. ✅ **Backend team response received**
3. ✅ **Phase 1 implementation COMPLETED**
4. 🚀 **Ready to start Phase 2: Screen B - Order Details**
   - Create OrderDetailsScreen
   - Build MessageToRestaurantWidget
   - Implement navigation flow
   - Wire up special instructions

---

## Notes

- This plan assumes full backend support for multi-restaurant carts
- Timeline may adjust based on backend response
- Each phase is independently deliverable
- Feature flags enable safe, gradual rollout
- Backward compatibility maintained throughout

---

**Document Owner:** Development Team
**Stakeholders:** Product, Design, Backend, QA
**Review Cadence:** Weekly during implementation
