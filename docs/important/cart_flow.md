 **blueprint of the Cart → Order Details → Checkout flow**, no code, just logic and behavior.

---

## 0. Core Concepts / Shared State

* **Cart** (per restaurant)

  * `restaurantId`
  * `items[]` (line items, qty, price, options, notes)
  * `subtotal`
  * `status` (active / temporarily offline / etc.)
* **Restaurant**

  * `id`, `name`, `logo`, `isOpen`, `deliveryEstimate`, `zone`, `location`
* **Address**

  * `id`, `label`, `fullAddress`, `geoPoint`, `isDefault`
* **Checkout Session**

  * `cartId`
  * `mode` (Delivery / Pickup)
  * `selectedAddressId` (nullable for Delivery, always null for Pickup)
  * `timeOption` (Standard / Scheduled + time)
  * `tipAmount`
  * `paymentMethod` (Apple Pay / Card / etc.)

All three screens work on the **same cart object** and share the same `CheckoutSession`.

---

## 1. Screen A – **Your Orders (Cart Overview)**

### Purpose

Entry point for all active carts. Lets user jump into any restaurant’s order.

### Layout

* **Header**

  * Back/close chevron
  * Title: “Your orders”
  * Action: “Edit” (optional future: delete carts, etc.)

* **Segmented control**

  * Left: **Shopping carts** (selected by default)
  * Right: **Order again** (past orders / re-order, separate flow)

* **List of active carts** (one card per restaurant)
  For each cart:

  * Restaurant logo thumbnail
  * Restaurant name
  * Status line (e.g. “Delivery in 55–65 min” or “Temporarily offline”)
  * Divider (dotted or light)
  * Either:

    * Single main item image *or*
    * Thumbnail strip of items (like in Jafra Express)
  * Text: `Item subtotal: ₪XXX.XX`
  * CTA: **“View cart”** (full-width, light background)

### Interactions

* Tapping anywhere on the card (or “View cart”) → **Screen B: Order Details** for that restaurant.
* If restaurant is temporarily offline:

  * Still allow viewing cart, but later in checkout we might block payment or show warnings.

### Navigation

* **A is root** of this flow.
* Push **B** on top of A with your custom transition.

---

## 2. Screen B – **Order Details (“Your order”)**

This is the **per-restaurant cart details** screen.

### Purpose

Let user:

* Review line items
* Add special instructions
* Add more items from restaurant
* Get recommendations
* Proceed to checkout

### Layout

* **Header**

  * Back chevron (to Screen A)
  * Restaurant name (e.g., “Jafra Express”)
  * Subtitle: “Your order”

* **Message to restaurant**

  * Row:

    * Icon (chat bubble)
    * Title: “Add a message for the restaurant”
    * Subtitle (placeholder): “Special requests, allergies, dietary restrictions?”
    * Chevron (navigates to separate note editor or inline text field)
  * Saved message persists in `cart.specialInstructions`.

* **Order items list**

  * Section title: “Order items”
  * For each line item:

    * Qty pill (rounded square with number)
    * Item name
    * Item options / description (multi-line)
    * Price
    * Thumbnail on the right
  * At the top-right of section: **“+ Add more”**

    * Tapping navigates to **Restaurant Menu Screen** (external to this 3-step flow) with:

      * Same `restaurantId`
      * Current cart pre-loaded

* **Recommended items**

  * Section title: “Recommended for you”
  * Horizontal cards / grid:

    * Image
    * Tag (e.g. POPULAR)
    * Price
    * “+” add button
  * Adding here appends items to same cart and updates subtotal.

* **Bottom bar**

  * Left: summary text → e.g. `3` (items count)
  * Middle: CTA: **“Go to checkout”**
  * Right: total `₪X.XX` (subtotal only; final pricing will be in Checkout)
  * CTA only enabled if cart has at least one item and restaurant not blocked.

### Interactions

* **Back**:

  * Returns to Screen A.
  * Cart changes (items/notes) are already saved.

* **Add more**:

  * Pushes **Restaurant Menu** screen.
  * Returning from menu brings user back to Screen B with updated cart.

* **Go to checkout**:

  * Creates/updates `CheckoutSession` for this cart.
  * Pushes **Screen C: Checkout**.

### Navigation Stack

* A (Your orders)
* B (Order details – this screen)
* Optionally: Restaurant Menu (between B and B’), but logically considered a side branch.
* Then → C.

---

## 3. Screen C – **Checkout (Address & Payment)**

This is the **single consolidated checkout** screen for this restaurant.

### Purpose

* Choose delivery mode / pickup
* Select / add address
* Set time (standard/scheduled)
* Choose payment method
* Add tip
* Review summary
* Place order

### Overall Layout

Top part = **Map + Mode tabs**
Middle = **Delivery/pickup options & inputs**
Bottom = **Summary + primary CTA**

#### 3.1 Header

* Back chevron (to Screen B)
* Title: Restaurant name (e.g. “Jafra Express”)
* Optional info icon on the right (restaurant info / policies).

#### 3.2 Map & Mode Tabs

* **Map area (top block)**:

  * Shows:

    * Restaurant pin
    * If `selectedAddressId != null` (Delivery mode):

      * User’s address pin.
      * Route / area if desired.
    * If **no address**:

      * Zone area highlight + restaurant pin only.
  * The map updates when address or mode changes.

* **Mode tabs** directly under map:

  * Segmented control: **Delivery / Pickup**
  * Switching:

    * Updates CheckoutSession `mode`.
    * For Pickup:

      * Address-related sections collapse/disable.
      * CTA becomes “Pay” instead of “Add delivery address”.
      * Map may center only on restaurant.

#### 3.3 Delivery Options & Address

Only relevant when **Delivery** is selected.

* **Choose a delivery address**

  * Row with:

    * Location pin icon
    * Title: “Choose a delivery address”
    * Subtitle:

      * If no address: “Tap here to continue”
      * If selected address: short label / street and number.
    * Chevron / tappable row.
  * On tap → Address selection screen (list of saved + “Add new”), returns with `selectedAddressId`.

* **Leave order at the door** (toggle)

  * Boolean flag.
  * Only visible/active in Delivery mode.

* **Send as a gift** (row)

  * Optional: opens additional recipient info section.

#### 3.4 When? (Time Options)

* Section title: “When?”
* Two options (cards or radio rows):

  * **Standard**:

    * Label: “Standard”
    * Subtitle: “80–90 min” (dynamic ETA)
  * **Schedule**:

    * Label: “Schedule”
    * Subtitle: “Choose a delivery time”
    * When selected, opens a time picker component.

Selected value saved into `CheckoutSession.timeOption`.

#### 3.5 Payment Section

* Title: “Payment”
* Primary payment method row:

  * Example: “Apple Pay – Will be charged for ₪113.25”
  * Tapping opens payment method selector (Apple Pay / Card / X).
* Additional option:

  * “Redeem code – Enter gift card or promo code”
  * Opens promo code input; affects summary totals.

#### 3.6 Add Courier Tip

* Title: “Add courier tip”
* Description: explanatory text about tip behavior.
* Tip options:

  * Pills: `₪0`, `₪5`, `₪10`, `₪15`, `Custom`.
  * Custom opens numeric input.
* Selected value stored in `CheckoutSession.tipAmount`.

#### 3.7 Summary

* Title: “Summary”
* Possible link: “How fees work”
* Line items:

  * `Item subtotal`
  * `Service fee`
  * `Delivery (X km)` with note (“Long distance” or similar)
  * `Total` with taxes note
* All numbers derived from:

  * Cart subtotal
  * Service fee rules
  * Delivery pricing rules based on address/zone
  * Tip (added to total at the very end or separate, depending on product decision).

#### 3.8 Primary CTA (Bottom Button)

This is **conditional based on address state and mode**:

* **Delivery mode**:

  * If `selectedAddressId == null` →

    * Button text: **“Add delivery address”**
    * Disabled until “Choose a delivery address” row is tapped, or always enabled and simply focuses that flow.
    * On tap: open Address selection/creation flow.
  * If `selectedAddressId != null` →

    * Button text: e.g. **“Pay with Apple Pay”** or “Pay with card”.
    * On tap: trigger payment flow and place order.

* **Pickup mode**:

  * No address needed:

    * Button always in “Pay” state.
    * Text: “Pay with Apple Pay” / “Pay and place order”.

### Navigation & State

* Flow:
  `A (Your orders)` → `B (Order details)` → `C (Checkout)`

* Back:

  * From C to B: keep cart & checkout session (so user can modify items and re-open checkout).
  * From B to A: keep carts; updating item counts/subtotals on A.

* Address selection and restaurant menu are **side screens** that:

  * Push on top of B or C.
  * Return with updated data, then previous screen refreshes UI.

---

## 4. Behavioral Rules / Edge Cases

1. **Restaurant temporarily offline**

   * Show status on A and B.
   * On C, block payment:

     * Either hide pay button and show “Restaurant is temporarily offline” message
       or disable button with error.

2. **Empty cart**

   * If items count becomes 0 on B:

     * Either:

       * Pop back to A automatically, or
       * Show empty-state and hide checkout.

3. **Mode switch (Delivery ↔ Pickup)**

   * When switching to Pickup:

     * Ignore `selectedAddressId` for pricing.
     * Hide address-specific sections.
   * When switching back to Delivery:

     * Restore last `selectedAddressId` if any; otherwise require address before pay.

4. **Address / zone constraints**

   * If selected address is outside zone:

     * Show error / disable checkout.
     * Map should visually indicate that (optional).

---

You can hand this straight to Claude as **“Current desired flow spec for Cart → Order details → Checkout”** and ask it to:

* Compare this against your existing navigation + state management.
* Adjust routes, view models, and conditions so this exact behavior emerges.
