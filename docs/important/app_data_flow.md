⏺ App Launch Data Fetching Flow

  When & Where:

  1. Splash Screen (once)
  - /api/v1/config - App configuration (features, settings, business hours)

  2. Home Screen Init (once, in HomeScreen.loadData())
  All calls fire in parallel (non-blocking):

  Core Data (always fetched):

  - /api/v1/config - Config refresh (force from API)
  - /api/v1/banners - Promotional banners
  - /api/v1/categories - Food categories ✅ Now cache-first
  - /api/v1/cuisine - Cuisine types
  - /api/v1/restaurants/get-restaurants - Restaurant list
  - /api/v1/zone/list - Delivery zones
  - /api/v1/campaigns/item - Item campaigns
  - Stories API (custom endpoint)
  - Advertisements (custom endpoint)
  - Dine-in restaurants

  Conditional Data (based on config):

  - /api/v1/restaurants/popular - If popularRestaurant == 1
  - /api/v1/products/popular - If popularFood == 1
  - /api/v1/restaurants/latest - If newRestaurant == 1
  - /api/v1/products/most-reviewed - If mostReviewedFoods == 1

  User-Specific (if logged in):

  - /api/v1/customer/info - User profile
  - /api/v1/restaurants/recently-viewed-restaurants - Recently viewed
  - /api/v1/customer/order-again - Order again suggestions
  - /api/v1/customer/notifications - Notifications

  ---
  Optimization Status:

  ✅ Good:
  - Parallel loading (non-blocking)
  - Cache-first for most data (banners, cuisines, categories after fix)
  - Conditional fetching based on config
  - Single load on init

  ⚠️ Issues Found & Fixed:
  - Categories always waited for API ✅ FIXED - Now cache-first
  - Config refreshes on every home screen load (intentional for promo updates)

  ⚠️ Potential Improvements:
  - Stories always fetches fresh (no cache) - could be cached
  - Config refresh on every home visit - could be rate-limited
  - No request deduplication if user navigates away/back quickly
