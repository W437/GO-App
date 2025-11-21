GET /api/v1/restaurants/details/{id}
  Note: You can use either restaurant id (numeric) or slug (string)

  ★ Insight ─────────────────────────────────────
  1. Rich data formatting: The API applies extensive data transformation through
   DataFormatter::restaurant_data_formatting()
  2. Dynamic schedules: Weekly opening hours come from restaurant_schedule table
   (0-6 for days)
  3. Characteristics array: Perfect for displaying "Vegan options available"
  type info from your screenshot
  ─────────────────────────────────────────────────

  🎯 Complete API Response Structure

  {
    // ===== BASIC INFO =====
    "id": 123,
    "name": "The Golden Spoon",
    "slug": "the-golden-spoon",
    "phone": "(123) 456-7890",
    "email": "contact@thegoldenspoon.com",

    // ===== IMAGES WITH BLURHASH =====
    "logo": "restaurant_logo.png",
    "logo_blurhash": "L6PZfSi_.AyE_3t7t7R**0o#DgR4",
    "logo_full_url": "https://hq-secure-panel-1337.hopa.delivery/storage/app/pub
  lic/restaurant/restaurant_logo.png",

    "cover_photo": "cover.jpg",
    "cover_photo_blurhash": "LKO2?U%2Tw=w]~RBVZRi};RPxuwH",
    "cover_photo_full_url": "https://hq-secure-panel-1337.hopa.delivery/storage/
  app/public/restaurant/cover/cover.jpg",

    // ===== DESCRIPTIONS =====
    "description": "Experience authentic Italian dining in the heart of the 
  city. The Golden Spoon offers a culinary journey through Italy with classic 
  recipes, fresh ingredients, and a cozy, inviting ambiance. Perfect for a 
  romantic dinner or a family celebration.",
    "short_description": "Authentic Italian cuisine in the heart of the city",

    // ===== LOCATION =====
    "address": "123 Culinary Lane, Foodie City, FC 45678",
    "latitude": "40.7128",
    "longitude": "-74.0060",
    "distance": 1.2,  // Distance from user (in km or miles based on system 
  setting)

    // ===== RATINGS & REVIEWS =====
    "avg_rating": 4.8,
    "rating_count": 215,
    "positive_rating": 92,  // Percentage of 4-5 star reviews
    "ratings": [5, 10, 15, 30, 155],  // Count: [1-star, 2-star, 3-star, 4-star,
   5-star]
    "reviews_comments_count": 215,

    // ===== CUISINE =====
    "cuisine": [
      {
        "id": 5,
        "name": "Italian",
        "image": "italian.png",
        "image_blurhash": "LEHV6nWB2yk8pyo0adR*.7kCMdnj",
        "status": 1
      }
    ],

    // ===== PRICING & DELIVERY =====
    "minimum_order": 15.00,
    "delivery_time": "30-40",  // Format: "min-max-min" or "min-max"
    "delivery_fee": 3.50,  // Calculated based on distance
    "minimum_shipping_charge": 2.00,
    "per_km_shipping_charge": 0.50,
    "maximum_shipping_charge": 10.00,
    "free_delivery": false,
    "tax": 8.50,  // Tax percentage

    // ===== OPERATING INFO =====
    "delivery": true,
    "take_away": true,
    "schedule_order": true,
    "veg": true,  // Serves vegetarian
    "non_veg": true,  // Serves non-vegetarian

    // ===== OPENING HOURS (Weekly Schedule) =====
    "schedules": [
      {
        "id": 1,
        "restaurant_id": 123,
        "day": 0,  // 0=Sunday, 1=Monday, ..., 6=Saturday
        "opening_time": "11:00:00",
        "closing_time": "22:00:00"
      },
      {
        "id": 2,
        "restaurant_id": 123,
        "day": 1,
        "opening_time": "11:00:00",
        "closing_time": "22:00:00"
      },
      // ... continues for all 7 days
    ],
    "current_opening_time": "11:00",  // Next opening time or "closed"
    "available_time_starts": "11:00",  // Today's opening (if using 
  opening_time)
    "available_time_ends": "22:00",  // Today's closing (if using closeing_time)

    // ===== STATUS =====
    "restaurant_status": 1,  // 1=active, 0=inactive
    "active": true,  // Restaurant is open/closed for business
    "open": 1,  // Currently open (0=closed, 1=open)
    "status": 1,

    // ===== CHARACTERISTICS (Perfect for "Vegan options available" etc.) =====
    "characteristics": [
      "Vegan and gluten-free options are available upon request",
      "Outdoor seating available",
      "Free WiFi",
      "Wheelchair accessible"
    ],

    // ===== TAGS =====
    "tags": [
      "Italian",
      "Pasta",
      "Pizza",
      "Romantic",
      "Family-friendly"
    ],

    // ===== ADDITIONAL INFO =====
    "halal_tag_status": false,
    "is_dine_in_active": true,
    "cutlery": true,  // Provides cutlery with orders

    // ===== PACKAGING =====
    "is_extra_packaging_active": true,
    "extra_packaging_status": true,
    "extra_packaging_amount": 2.00,

    // ===== ORDERING =====
    "instant_order": true,
    "customer_order_date": 3,  // Max days in advance for scheduling
    "customer_date_order_sratus": true,
    "schedule_advance_dine_in_booking_duration": 30,
    "schedule_advance_dine_in_booking_duration_time_format": "min",

    // ===== SAMPLE FOODS (Top 5) =====
    "foods": [
      {
        "id": 101,
        "name": "Margherita Pizza",
        "image": "margherita.jpg"
      },
      {
        "id": 102,
        "name": "Spaghetti Carbonara",
        "image": "carbonara.jpg"
      }
      // ... up to 5 items
    ],

    // ===== AVAILABLE COUPONS =====
    "coupons": [
      {
        "id": 45,
        "title": "10% OFF Your First Order",
        "code": "FIRST10",
        "discount_type": "percentage",
        "discount": 10.00,
        "min_purchase": 20.00,
        "max_discount": 5.00,
        "start_date": "2025-01-01",
        "expire_date": "2025-12-31"
      }
    ],

    // ===== CATEGORY IDS =====
    "category_ids": [1, 3, 5, 8],  // IDs of food categories this restaurant 
  serves

    // ===== OTHER FIELDS =====
    "zone_id": 1,
    "vendor_id": 56,
    "restaurant_model": "commission",  // or "subscription"
    "self_delivery_system": 0,
    "pos_system": 1,
    "order_subscription_active": false,
    "announcement": false,
    "announcement_message": null,
    "stories_enabled": true,
    "foods_count": 45,

    // ===== METADATA =====
    "meta_title": "The Golden Spoon - Best Italian Restaurant",
    "meta_description": "Experience authentic Italian dining...",
    "meta_image": "meta.jpg",
    "meta_image_full_url": "https://...",

    // ===== RELATIONSHIPS (loaded but not always in response) =====
    "storage": [
      {
        "id": 1,
        "data_type": "restaurant",
        "data_id": 123,
        "key": "logo",
        "value": "s3"  // or "public"
      }
    ]
  }

  🔗 Mapping to Your Screenshot

  | Screenshot Section  | API Fields                                   |
  |---------------------|----------------------------------------------|
  | "The Golden Spoon"  | name                                         |
  | "Italian"           | cuisine[0].name                              |
  | "$$"                | Calculate from minimum_order or custom field |
  | "1.2 mi"            | distance                                     |
  | "4.8 (215 reviews)" | avg_rating, rating_count                     |
  | Description box     | description                                  |
  | Opening Hours       | schedules array (map day 0-6 to Mon-Sun)     |
  | Location address    | address                                      |
  | Location map        | latitude, longitude                          |
  | Phone               | phone                                        |
  | Website             | email (or add custom field)                  |
  | "Vegan options..."  | characteristics[0]                           |
  | Reviews section     | avg_rating, rating_count                     |