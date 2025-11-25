# Hidden Home Screen Sections

These sections have been temporarily hidden from the home screen. This document tracks what was hidden and the API/data dependencies for each section.

## Hidden Sections

### 5. Item Campaign (Trending Food Offers)
- **Widget**: `ItemCampaignWidget1`
- **File**: `lib/features/home/widgets/theme1/item_campaign_widget1.dart`
- **Controller**: `CampaignController`
- **Data**: `itemCampaignList`
- **API Endpoint**: Campaign items endpoint

### 6. Today Trends
- **Widget**: `TodayTrendsViewWidget`
- **File**: `lib/features/home/widgets/today_trends_view_widget.dart`
- **Controller**: `CampaignController`
- **Data**: `itemCampaignList`
- **API Endpoint**: Campaign items endpoint (same as Item Campaign)

### 8. Order Again
- **Widget**: `OrderAgainViewWidget`
- **File**: `lib/features/home/widgets/order_again_view_widget.dart`
- **Controller**: `RestaurantController`
- **Data**: `orderAgainRestaurantList`
- **API Endpoint**: Order again restaurants endpoint
- **Note**: Only shown to logged-in users

### 9. Best Reviewed Food
- **Widget**: `BestReviewItemViewWidget`
- **File**: `lib/features/home/widgets/best_review_item_view_widget.dart`
- **Controller**: `ReviewController`
- **Data**: `reviewedProductList`
- **API Endpoint**: Most reviewed foods endpoint
- **Config**: `configModel.mostReviewedFoods == 1`

### 10. Dine In
- **Widget**: `DineInWidget`
- **File**: `lib/features/home/widgets/dine_in_widget.dart`
- **Controller**: None (static widget)
- **Config**: `configModel.dineInOrderOption`
- **Note**: Links to dine-in restaurant screen

### 11. Popular Restaurants
- **Widget**: `PopularRestaurantsViewWidget`
- **File**: `lib/features/home/widgets/popular_restaurants_view_widget.dart`
- **Controller**: `RestaurantController`
- **Data**: `popularRestaurantList`
- **API Endpoint**: Popular restaurants endpoint
- **Config**: `configModel.popularRestaurant == 1`

### 12. Refer Banner
- **Widget**: `ReferBannerViewWidget`
- **File**: `lib/features/home/widgets/refer_banner_view_widget.dart`
- **Controller**: `SplashController`
- **Config**: `configModel.refEarningStatus == 1`, `configModel.refEarningExchangeRate`
- **Note**: Promotional banner for referral program

### 13. Recently Viewed Restaurants
- **Widget**: `PopularRestaurantsViewWidget` (with `isRecentlyViewed: true`)
- **File**: `lib/features/home/widgets/popular_restaurants_view_widget.dart`
- **Controller**: `RestaurantController`
- **Data**: `recentlyViewedRestaurantList`
- **API Endpoint**: Recently viewed restaurants endpoint
- **Note**: Only shown to logged-in users

### 14. Popular Food Nearby
- **Widget**: `PopularFoodNearbyViewWidget`
- **File**: `lib/features/home/widgets/popular_foods_nearby_view_widget.dart`
- **Controller**: `ProductController`
- **Data**: `popularProductList`
- **API Endpoint**: Popular products endpoint
- **Config**: `configModel.popularFood == 1`

### 15. New on GO
- **Widget**: `NewOnGOViewWidget`
- **File**: `lib/features/home/widgets/new_on_go_view_widget.dart`
- **Controller**: `RestaurantController`
- **Data**: `latestRestaurantList`
- **API Endpoint**: Latest/new restaurants endpoint
- **Config**: `configModel.newRestaurant == 1`

### 16. Promotional Banner
- **Widget**: `PromotionalBannerViewWidget`
- **File**: `lib/features/home/widgets/enjoy_off_banner_view_widget.dart`
- **Controller**: `SplashController`
- **Data**: `configModel.bannerData.promotionalBannerImageFullUrl`
- **Note**: Promotional banner from config

---

## To Restore

To restore any section, uncomment the corresponding widget in:
`lib/features/home/screens/home_screen.dart`

Look for the `// HIDDEN:` comments in the `_buildStandardHomeLayout()` method.
