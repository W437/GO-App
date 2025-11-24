 Context: The backend has been optimized to reduce API calls when loading restaurant detail pages from 4 calls to 2 calls, improving page
  load speed by 50%.

  🔄 What Changed

  BEFORE (4 API calls):
  1. GET /api/v1/restaurants/details/{id} - Restaurant info
  2. GET /api/v1/products/latest?restaurant_id={id} - All products
  3. GET /api/v1/restaurants/get-coupon?restaurant_id={id} - Coupons
  4. GET /api/v1/products/recommended?restaurant_id={id} - Recommended items

  AFTER (2 API calls):
  1. GET /api/v1/restaurants/details/{id} - Restaurant info + Coupons included
  2. GET /api/v1/products/restaurant/{id}?include=recommended,popular - All products with flags

  📦 New Response Structures

  1. Restaurant Details (Enhanced)

  GET /api/v1/restaurants/details/{id}

  Response:
  {
    // ... all existing restaurant fields remain unchanged ...
    "name": "Restaurant Name",
    "logo": "...",
    "schedules": [...],

    // NEW: Coupons are now included
    "coupons": [
      {
        "code": "SAVE20",
        "discount": 20,
        "discount_type": "percent",
        "min_purchase": 50,
        "expire_date": "2024-12-31"
      }
    ]
  }

  2. Smart Products Endpoint (New)

  GET /api/v1/products/restaurant/{restaurant_id}?include=recommended,popular

  Response:
  {
    "products": [
      {
        "id": 1,
        "name": "Margherita Pizza",
        "price": 12.99,
        "image": "...",
        "description": "...",

        // NEW FLAGS - use these to filter
        "is_recommended": true,  // Replaces separate recommended endpoint
        "is_popular": false,      // Replaces separate popular endpoint

        // ... all other product fields unchanged ...
      }
    ],
    "meta": {
      "total_size": 150,
      "limit": 100,
      "offset": 1,

      // Quick reference arrays for filtering
      "recommended_ids": [1, 5, 8, 12, 15],
      "popular_ids": [2, 3, 7, 9, 11],
      "recommended_count": 5,
      "popular_count": 5
    }
  }

  🔧 Implementation Changes Required

  Update your restaurant detail page loading logic:

  // OLD CODE - Remove this
  async function loadRestaurantPage(restaurantId) {
    const [details, products, coupons, recommended] = await Promise.all([
      api.get(`/restaurants/details/${restaurantId}`),
      api.get(`/products/latest?restaurant_id=${restaurantId}`),
      api.get(`/restaurants/get-coupon?restaurant_id=${restaurantId}`),
      api.get(`/products/recommended?restaurant_id=${restaurantId}`)
    ]);

    return { details, products, coupons, recommended };
  }

  // NEW CODE - Replace with this
  async function loadRestaurantPage(restaurantId) {
    const [details, productsResponse] = await Promise.all([
      api.get(`/restaurants/details/${restaurantId}`),
      api.get(`/products/restaurant/${restaurantId}?include=recommended,popular`)
    ]);

    // Extract products and filter by flags
    const allProducts = productsResponse.products;
    const recommendedProducts = allProducts.filter(p => p.is_recommended);
    const popularProducts = allProducts.filter(p => p.is_popular);

    return {
      details,        // Now includes coupons in details.coupons
      products: allProducts,
      coupons: details.coupons,  // Extract from details
      recommended: recommendedProducts,
      popular: popularProducts  // Bonus: popular products also available
    };
  }

  📍 Important Notes

  1. Coupons are now in restaurant details - No need for separate coupon API call
  2. Use product flags for filtering - is_recommended and is_popular flags on each product
  3. The meta object provides quick ID lists - Use meta.recommended_ids for quick checks
  4. Default limit increased to 100 - To ensure all products load in one call
  5. Legacy endpoints still work - Old endpoints remain for backward compatibility during migration

  🎯 Quick Checklist

  - Remove the separate coupon API call
  - Remove the separate recommended products API call
  - Update to use new /products/restaurant/{id} endpoint
  - Extract coupons from restaurant details response
  - Filter products using is_recommended flag
  - Update any product caching logic to use the new structure
  - Test that restaurant page loads with only 2 API calls