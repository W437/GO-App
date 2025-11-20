# Delivery Scheduling System

## Overview

The GO Admin Panel includes a fully implemented delivery scheduling system that allows customers to place orders for future delivery at specific dates and times. This document explains how the scheduling system works, from database structure to API usage.

---

## Table of Contents

- [Database Structure](#database-structure)
- [How It Works](#how-it-works)
- [API Usage](#api-usage)
- [Restaurant Configuration](#restaurant-configuration)
- [Admin Management](#admin-management)
- [Code Examples](#code-examples)
- [Global Settings](#global-settings)

---

## Database Structure

### Orders Table Fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `schedule_at` | TIMESTAMP | NULL | The exact date and time when the order should be delivered |
| `scheduled` | TINYINT | 0 | Boolean flag: 1 = scheduled order, 0 = immediate order |

### Restaurants Table Fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `schedule_order` | TINYINT | 0 | Enable/disable scheduling for this restaurant |
| `delivery_time` | VARCHAR | '30-40' | Expected delivery time range in minutes |

### Restaurant Schedule Table

Stores weekly operating hours for each restaurant:

```sql
CREATE TABLE `restaurant_schedule` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `restaurant_id` bigint unsigned NOT NULL,
  `day` int NOT NULL,                    -- 0 = Sunday, 1 = Monday, ... 6 = Saturday
  `opening_time` time DEFAULT NULL,      -- e.g., '09:00:00'
  `closing_time` time DEFAULT NULL,      -- e.g., '22:00:00'
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
);
```

---

## How It Works

### Order Types

**Immediate Orders:**
- Customer wants delivery ASAP
- `schedule_at` = current timestamp
- `scheduled` = 0
- Processed immediately

**Scheduled Orders:**
- Customer selects future delivery time
- `schedule_at` = future timestamp (provided by customer)
- `scheduled` = 1
- Processed when scheduled time approaches

### Key Logic

The system distinguishes between order types by comparing timestamps:

```php
// In OrderController.php (place_order method)
$schedule_at = $request->schedule_at ? \Carbon\Carbon::parse($request->schedule_at) : now();
$order->schedule_at = $schedule_at;

// Mark as scheduled only if:
// 1. schedule_at is provided in request
// 2. Order type is NOT 'dine_in'
$order->scheduled = $request->schedule_at && $request->order_type != 'dine_in' ? 1 : 0;
```

**Smart Detection:**
- `created_at = schedule_at` → Immediate order
- `created_at < schedule_at` → Scheduled order

**Important:** Dine-in orders cannot be scheduled (hardcoded restriction).

---

## API Usage

### Endpoint

```
POST /api/v1/customer/order/place
```

### Request Parameters

**Required:**
- `order_amount` - Total order amount
- `payment_method` - 'cash_on_delivery', 'digital_payment', 'wallet', 'offline_payment'
- `order_type` - 'take_away', 'delivery', 'dine_in'
- `restaurant_id` - ID of the restaurant
- `order_note` - Customer notes (can be empty)

**For Delivery Orders:**
- `distance` - Distance from restaurant to customer
- `address` - Delivery address object
- `longitude` - Delivery location longitude
- `latitude` - Delivery location latitude

**For Scheduling:**
- `schedule_at` (optional) - ISO 8601 datetime string for scheduled delivery

### Example: Immediate Order

```json
{
  "restaurant_id": 123,
  "order_type": "delivery",
  "payment_method": "cash_on_delivery",
  "order_amount": 25.50,
  "latitude": "40.7128",
  "longitude": "-74.0060",
  "distance": 2.5,
  "address": {
    "contact_person_name": "John Doe",
    "contact_person_number": "+1234567890",
    "address": "123 Main St",
    "floor": "2nd Floor",
    "road": "Main Street"
  }
}
```

Result: Immediate delivery order (`scheduled = 0`)

### Example: Scheduled Order

```json
{
  "restaurant_id": 123,
  "order_type": "delivery",
  "payment_method": "digital_payment",
  "order_amount": 25.50,
  "schedule_at": "2025-11-21 14:30:00",
  "latitude": "40.7128",
  "longitude": "-74.0060",
  "distance": 2.5,
  "address": {
    "contact_person_name": "John Doe",
    "contact_person_number": "+1234567890",
    "address": "123 Main St",
    "floor": "2nd Floor",
    "road": "Main Street"
  }
}
```

Result: Order scheduled for November 21, 2025 at 2:30 PM (`scheduled = 1`)

---

## Restaurant Configuration

### Enabling Scheduling

Restaurants can enable/disable scheduling via the admin panel:

**Database Field:**
```php
$restaurant->schedule_order = 1; // Enable scheduling
$restaurant->schedule_order = 0; // Disable scheduling
```

**Admin UI:**
- Navigate to: `/admin/restaurant/edit/{id}`
- Toggle "Schedule Order" setting

### Setting Operating Hours

Restaurants can define weekly schedules:

**Model Relationship:**
```php
// Restaurant.php
public function schedules()
{
    return $this->hasMany(RestaurantSchedule::class)->orderBy('opening_time');
}
```

**Example Schedule Data:**
```php
RestaurantSchedule::create([
    'restaurant_id' => 123,
    'day' => 1,                    // Monday
    'opening_time' => '09:00:00',
    'closing_time' => '22:00:00',
]);
```

**Admin UI:**
- Navigate to: `/vendor/business-settings/restaurant-index` (for vendor)
- Navigate to: `/admin/restaurant/view/{id}` (for admin)
- Configure schedule for each day of the week

### Delivery Time Estimation

Set expected delivery duration:

```php
$restaurant->delivery_time = '30-40'; // 30-40 minutes
```

This helps customers understand when their order will arrive.

---

## Admin Management

### Viewing Scheduled Orders

**Admin Order List:**
- URL: `/admin/order/list`
- Filter: `scheduled` parameter to show only scheduled orders
- Display: Shows `schedule_at` timestamp in order details

**Order View Page:**
```php
// Display scheduled time
@if ($order->schedule_at && $order->scheduled)
    <span>
        {{ date('d M Y H:i', strtotime($order['schedule_at'])) }}
    </span>
@endif
```

### Processing Orders

The system automatically retrieves orders ready for processing:

**Orders Scheduled Within Next 30 Minutes:**
```php
Order::OrderScheduledIn(30)->get();
```

This query returns:
- Scheduled orders where `schedule_at` is within next 30 minutes
- Overdue scheduled orders (where `schedule_at` has passed)
- All immediate orders (`created_at = schedule_at`)

**Purpose:** Gives restaurants a 30-minute prep window before scheduled delivery time.

---

## Code Examples

### Model Scopes

**Order.php:**

```php
// Get all scheduled orders
public function scopeScheduled($query)
{
    return $query->whereRaw('created_at <> schedule_at')
                 ->where('scheduled', '1');
}

// Get orders scheduled within a specific interval (in minutes)
public function scopeOrderScheduledIn($query, $interval)
{
    return $query->where(function($query) use ($interval) {
        $query->whereRaw('created_at <> schedule_at')
              ->where(function($q) use ($interval) {
                  $q->whereBetween('schedule_at', [
                      Carbon::now()->toDateTimeString(),
                      Carbon::now()->addMinutes($interval)->toDateTimeString()
                  ]);
              })
              ->orWhere('schedule_at', '<', Carbon::now()->toDateTimeString());
    })->orWhereRaw('created_at = schedule_at');
}

// Filter by scheduled date range
public static function scopeApplyDateFilterSchedule($query, $filter, $from = null, $to = null)
{
    return $query->when(isset($from) && isset($to) && $filter == 'custom', function ($query) use ($from, $to) {
        return $query->whereBetween('schedule_at', [
            $from . " 00:00:00",
            $to . " 23:59:59"
        ]);
    });
}
```

### Usage Examples

**Get all scheduled orders:**
```php
$scheduledOrders = Order::scheduled()->get();
```

**Get orders due in next 30 minutes:**
```php
$upcomingOrders = Order::OrderScheduledIn(30)->get();
```

**Get orders scheduled for a specific date range:**
```php
$orders = Order::applyDateFilterSchedule('custom', '2025-11-20', '2025-11-30')->get();
```

**Check if restaurant accepts scheduled orders:**
```php
if ($restaurant->schedule_order) {
    // Scheduling is enabled
}
```

**Get restaurant's operating schedule:**
```php
$schedule = $restaurant->schedules()->get();
foreach ($schedule as $day) {
    echo "Day: {$day->day}, Opens: {$day->opening_time}, Closes: {$day->closing_time}";
}
```

---

## Global Settings

Scheduling can be enabled/disabled globally via business settings:

**Helper Method:**
```php
// In Helpers.php
public static function schedule_order()
{
    return (bool)Helpers::getSettingsDataFromConfig(settings: 'schedule_order')?->value;
}
```

**Usage:**
```php
if (Helpers::schedule_order()) {
    // Global scheduling is enabled
}
```

**Admin Configuration:**
- Navigate to: `/admin/business-settings/restaurant-setup`
- Toggle "Schedule Order" setting

**Priority:**
- Global setting can disable scheduling for all restaurants
- Individual restaurant setting can disable scheduling for that specific restaurant
- Both must be enabled for scheduling to work

---

## Migration History

Key database migrations related to scheduling:

1. **2021_06_29_134119_add_schedule_column_to_orders_table.php**
   - Added `schedule_at` TIMESTAMP column to orders table

2. **2021_08_08_112127_add_scheduled_column_on_orders_table.php**
   - Added `scheduled` BOOLEAN column to orders table

3. **2021_07_29_162336_add_schedule_order_column_to_restaurants_table.php**
   - Added `schedule_order` column to restaurants table

4. **2022_01_19_060356_create_restaurant_schedule_table.php**
   - Created `restaurant_schedule` table for weekly operating hours

5. **2023_06_11_171524_change_delivery_time_col_in_restaurants_table.php**
   - Modified `delivery_time` column format

---

## Best Practices

### For Customers

1. **Check restaurant hours** - Ensure scheduled time falls within restaurant's operating hours
2. **Plan ahead** - Schedule orders at least 1 hour in advance for best results
3. **Consider prep time** - Factor in the restaurant's `delivery_time` estimate

### For Restaurants

1. **Set accurate delivery times** - Update `delivery_time` to reflect actual preparation + delivery duration
2. **Maintain schedule** - Keep `restaurant_schedule` table up to date with operating hours
3. **Monitor scheduled orders** - Check admin panel regularly for upcoming scheduled orders

### For Developers

1. **Always validate schedule_at** - Ensure it's a future timestamp
2. **Respect operating hours** - Check against `restaurant_schedule` before accepting
3. **Handle timezones** - Use Carbon for consistent timezone handling
4. **Cache clearing** - Call `Cache::flush()` after order status changes

---

## Troubleshooting

### Common Issues

**Scheduled orders not appearing:**
- Check if global scheduling is enabled: `Helpers::schedule_order()`
- Verify restaurant's `schedule_order` field is set to 1
- Ensure `schedule_at` is in the future

**Orders marked as immediate instead of scheduled:**
- Verify `schedule_at` parameter is included in API request
- Check if order type is 'dine_in' (dine-in cannot be scheduled)
- Ensure `schedule_at` is different from current timestamp

**Orders not being processed on time:**
- Check the `OrderScheduledIn()` scope interval (default: 30 minutes)
- Verify scheduled job or cron is running to process orders
- Check if `schedule_at` timestamp has passed

---

## Summary

The delivery scheduling system provides:

✅ **Flexible scheduling** - Customers can schedule orders for any future time
✅ **Restaurant control** - Individual restaurants can enable/disable scheduling
✅ **Operating hours management** - Weekly schedule configuration per restaurant
✅ **Smart processing** - Automatic order retrieval based on scheduled time windows
✅ **Admin visibility** - Full order tracking and filtering in admin panel
✅ **Global toggle** - System-wide scheduling enable/disable

The implementation uses simple database fields (`schedule_at` and `scheduled`) combined with sophisticated Eloquent scopes to manage the entire scheduling workflow efficiently.
