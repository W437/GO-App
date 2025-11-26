import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:godelivery_user/common/models/restaurant_model.dart';
import 'package:godelivery_user/config/environment.dart';
import 'package:godelivery_user/features/category/controllers/category_controller.dart';
import 'package:godelivery_user/features/location/controllers/location_controller.dart';
import 'package:godelivery_user/features/restaurant/controllers/restaurant_controller.dart';
import 'package:godelivery_user/helper/business_logic/address_helper.dart';
import 'package:godelivery_user/util/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SortOption {
  distance('Distance', Icons.location_on),
  rating('Rating', Icons.star),
  deliveryTime('Delivery Time', Icons.access_time),
  deliveryFee('Delivery Fee', Icons.attach_money),
  popular('Popular', Icons.trending_up);

  final String displayName;
  final IconData icon;

  const SortOption(this.displayName, this.icon);
}

class ExploreController extends GetxController implements GetxService {
  final RestaurantController restaurantController;
  final CategoryController categoryController;
  final LocationController locationController;

  ExploreController({
    required this.restaurantController,
    required this.categoryController,
    required this.locationController,
  });

  GoogleMapController? _mapController;
  GoogleMapController? get mapController => _mapController;

  mapbox.MapboxMap? _mapboxMap;
  mapbox.MapboxMap? get mapboxMap => _mapboxMap;

  List<Restaurant>? _nearbyRestaurants;
  List<Restaurant>? get nearbyRestaurants => _nearbyRestaurants;

  List<Restaurant>? _filteredRestaurants;
  List<Restaurant>? get filteredRestaurants => _filteredRestaurants;

  int? _selectedCategoryId;
  int? get selectedCategoryId => _selectedCategoryId;

  int _selectedRestaurantIndex = -1;
  int get selectedRestaurantIndex => _selectedRestaurantIndex;

  Restaurant? _selectedRestaurant;
  Restaurant? get selectedRestaurant => _selectedRestaurant;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  LatLng? _currentMapCenter;
  LatLng? get currentMapCenter => _currentMapCenter;

  double _currentZoom = 14.0;
  double get currentZoom => _currentZoom;

  // New properties for enhanced features
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  List<String> _searchHistory = [];
  List<String> get searchHistory => _searchHistory;

  SortOption _currentSortOption = SortOption.distance;
  SortOption get currentSortOption => _currentSortOption;

  bool _filterOpenNow = false;
  bool get filterOpenNow => _filterOpenNow;

  bool _filterFreeDelivery = false;
  bool get filterFreeDelivery => _filterFreeDelivery;

  bool _filterTopRated = false;
  bool get filterTopRated => _filterTopRated;

  bool _filterFastDelivery = false;
  bool get filterFastDelivery => _filterFastDelivery;

  // Advanced filters
  double _minRatingFilter = 0;
  double get minRatingFilter => _minRatingFilter;

  int _minPriceFilter = 1;
  int get minPriceFilter => _minPriceFilter;

  int _maxPriceFilter = 4;
  int get maxPriceFilter => _maxPriceFilter;

  double _maxDeliveryFeeFilter = 20;
  double get maxDeliveryFeeFilter => _maxDeliveryFeeFilter;

  double _sheetPosition = 0.5;
  double get sheetPosition => _sheetPosition;

  bool _isFullscreenMode = false;
  bool get isFullscreenMode => _isFullscreenMode;

  // Map position persistence
  Timer? _mapPositionSaveTimer;
  LatLng? _savedMapPosition;
  LatLng? get savedMapPosition => _savedMapPosition;
  double? _savedMapZoom;
  double? get savedMapZoom => _savedMapZoom;

  int get activeFilterCount {
    int count = 0;
    if (_filterOpenNow) count++;
    if (_filterFreeDelivery) count++;
    if (_filterTopRated) count++;
    if (_filterFastDelivery) count++;
    if (_selectedCategoryId != null) count++;
    if (_minRatingFilter > 0) count++;
    if (_maxDeliveryFeeFilter < 20) count++;
    return count;
  }

  void setMapController(GoogleMapController controller) {
    _mapController = controller;
  }

  void setMapboxMap(mapbox.MapboxMap map) {
    _mapboxMap = map;
  }

  Future<void> getNearbyRestaurants({bool reload = false}) async {
    if (reload) {
      _isLoading = true;
      update();
    }

    final response = await restaurantController.getMapExploreRestaurants();
    _nearbyRestaurants = response?.restaurants;
    print('🗺️ [EXPLORE] Loaded ${_nearbyRestaurants?.length ?? 0} restaurants from map-explore API');
    _applyFiltersAndSort(); // Apply filters and sort immediately

    _isLoading = false;
    update();
  }

  void filterByCategory(int? categoryId) {
    _selectedCategoryId = categoryId;
    _applyFiltersAndSort();
  }

  void selectRestaurant(int index) {
    _selectedRestaurantIndex = index;
    if (index >= 0 && _filteredRestaurants != null && index < _filteredRestaurants!.length) {
      _selectedRestaurant = _filteredRestaurants![index];
    } else {
      _selectedRestaurant = null;
    }
    update();
  }

  void clearSelectedRestaurant() {
    _selectedRestaurantIndex = -1;
    _selectedRestaurant = null;
    update();
  }

  void updateMapPosition(LatLng position, double zoom) {
    _currentMapCenter = position;
    _currentZoom = zoom;

    // Throttle saving to prevent excessive writes
    _mapPositionSaveTimer?.cancel();
    _mapPositionSaveTimer = Timer(const Duration(seconds: 2), () {
      _saveMapPosition(position, zoom);
    });
  }

  void animateToRestaurant(Restaurant restaurant) {
    final lat = double.parse(restaurant.latitude ?? '0');
    final lng = double.parse(restaurant.longitude ?? '0');

    if (Environment.useMapbox && _mapboxMap != null) {
      _mapboxMap!.flyTo(
        mapbox.CameraOptions(
          center: mapbox.Point(coordinates: mapbox.Position(lng, lat)),
          zoom: 16.0,
        ),
        mapbox.MapAnimationOptions(duration: 300),
      );
    } else if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(lat, lng),
          16.0,
        ),
      );
    }
  }

  // New methods for enhanced features
  void updateSheetPosition(double position) {
    _sheetPosition = position;
    update();
  }

  void toggleFullscreenMode() {
    _isFullscreenMode = !_isFullscreenMode;
    update();
  }

  void exitFullscreenMode() {
    _isFullscreenMode = false;
    update();
  }

  void searchRestaurants(String query, {bool saveToHistory = true}) {
    _searchQuery = query.toLowerCase();
    if (saveToHistory && query.trim().isNotEmpty) {
      _addToSearchHistory(query.trim());
    }
    _applyFiltersAndSort();
  }

  void clearSearch() {
    _searchQuery = '';
    _applyFiltersAndSort();
  }

  // Search History Methods
  void _addToSearchHistory(String query) {
    // Remove if already exists (to move to top)
    _searchHistory.remove(query);
    // Add to beginning
    _searchHistory.insert(0, query);
    // Keep only last 10
    if (_searchHistory.length > 10) {
      _searchHistory = _searchHistory.sublist(0, 10);
    }
    _saveSearchHistory();
    update();
  }

  void removeFromSearchHistory(String query) {
    _searchHistory.remove(query);
    _saveSearchHistory();
    update();
  }

  void clearSearchHistory() {
    _searchHistory.clear();
    _saveSearchHistory();
    update();
  }

  Future<void> _loadSearchHistory() async {
    final prefs = Get.find<SharedPreferences>();
    final history = prefs.getStringList(AppConstants.searchHistory) ?? [];
    _searchHistory = history;
  }

  Future<void> _saveSearchHistory() async {
    final prefs = Get.find<SharedPreferences>();
    await prefs.setStringList(AppConstants.searchHistory, _searchHistory);
  }

  // Autocomplete Methods
  List<String> getAutocompleteSuggestions(String query) {
    if (query.isEmpty || _nearbyRestaurants == null) {
      return [];
    }

    final lowerQuery = query.toLowerCase();
    final Set<String> suggestions = {};

    // Add restaurant names
    for (final restaurant in _nearbyRestaurants!) {
      final name = restaurant.name?.toLowerCase() ?? '';
      if (name.contains(lowerQuery)) {
        suggestions.add(restaurant.name!);
      }
    }

    // Add cuisine names
    for (final restaurant in _nearbyRestaurants!) {
      if (restaurant.cuisineNames != null) {
        for (final cuisine in restaurant.cuisineNames!) {
          final cuisineName = cuisine.name?.toLowerCase() ?? '';
          if (cuisineName.contains(lowerQuery)) {
            suggestions.add(cuisine.name!);
          }
        }
      }
    }

    // Return top 5 suggestions
    return suggestions.take(5).toList();
  }

  // Map Position Persistence Methods
  Future<void> _loadMapPosition() async {
    final prefs = Get.find<SharedPreferences>();
    final lat = prefs.getDouble(AppConstants.exploreMapLatitude);
    final lng = prefs.getDouble(AppConstants.exploreMapLongitude);
    final zoom = prefs.getDouble(AppConstants.exploreMapZoom);

    if (lat != null && lng != null && zoom != null) {
      _savedMapPosition = LatLng(lat, lng);
      _savedMapZoom = zoom;
    }
  }

  Future<void> _saveMapPosition(LatLng position, double zoom) async {
    final prefs = Get.find<SharedPreferences>();
    await prefs.setDouble(AppConstants.exploreMapLatitude, position.latitude);
    await prefs.setDouble(AppConstants.exploreMapLongitude, position.longitude);
    await prefs.setDouble(AppConstants.exploreMapZoom, zoom);

    _savedMapPosition = position;
    _savedMapZoom = zoom;
  }

  void setSortOption(SortOption option) {
    _currentSortOption = option;
    _saveFilters();
    _applyFiltersAndSort();
  }

  void toggleOpenNowFilter() {
    _filterOpenNow = !_filterOpenNow;
    _saveFilters();
    _applyFiltersAndSort();
  }

  void toggleFreeDeliveryFilter() {
    _filterFreeDelivery = !_filterFreeDelivery;
    _saveFilters();
    _applyFiltersAndSort();
  }

  void toggleTopRatedFilter() {
    _filterTopRated = !_filterTopRated;
    _saveFilters();
    _applyFiltersAndSort();
  }

  void toggleFastDeliveryFilter() {
    _filterFastDelivery = !_filterFastDelivery;
    _saveFilters();
    _applyFiltersAndSort();
  }

  void clearAllFilters() {
    _filterOpenNow = false;
    _filterFreeDelivery = false;
    _filterTopRated = false;
    _filterFastDelivery = false;
    _selectedCategoryId = null;
    _minRatingFilter = 0;
    _minPriceFilter = 1;
    _maxPriceFilter = 4;
    _maxDeliveryFeeFilter = 20;
    _saveFilters();
    _applyFiltersAndSort();
  }

  void setAdvancedFilters({
    required double minRating,
    required int minPrice,
    required int maxPrice,
    required double maxDeliveryFee,
  }) {
    _minRatingFilter = minRating;
    _minPriceFilter = minPrice;
    _maxPriceFilter = maxPrice;
    _maxDeliveryFeeFilter = maxDeliveryFee;
    _saveFilters();
    _applyFiltersAndSort();
  }

  void showFilterBottomSheet() {
    // This will be implemented to show the advanced filter bottom sheet
    Get.snackbar('Coming Soon', 'Advanced filters will be available soon!');
  }

  void _applyFiltersAndSort() {
    if (_nearbyRestaurants == null) {
      _filteredRestaurants = null;
      update();
      return;
    }

    // Start with all restaurants
    List<Restaurant> result = List.from(_nearbyRestaurants!);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      result = result.where((restaurant) {
        final nameMatch = restaurant.name?.toLowerCase().contains(_searchQuery) ?? false;
        final cuisineMatch = restaurant.cuisineNames?.any((cuisine) =>
            cuisine.name?.toLowerCase().contains(_searchQuery) ?? false) ?? false;
        return nameMatch || cuisineMatch;
      }).toList();
    }

    // Apply category filter
    if (_selectedCategoryId != null) {
      result = result.where((restaurant) {
        return restaurant.categoryIds?.contains(_selectedCategoryId) ?? false;
      }).toList();
    }

    // Apply quick filters
    if (_filterOpenNow) {
      result = result.where((r) => r.open == 1 && r.active == true).toList();
    }

    if (_filterFreeDelivery) {
      result = result.where((r) => r.freeDelivery == true).toList();
    }

    if (_filterTopRated) {
      result = result.where((r) => (r.avgRating ?? 0) >= 4.5).toList();
    }

    // Apply advanced filters
    if (_minRatingFilter > 0) {
      result = result.where((r) => (r.avgRating ?? 0) >= _minRatingFilter).toList();
    }

    if (_maxDeliveryFeeFilter < 20) {
      result = result.where((r) {
        if (_maxDeliveryFeeFilter == 0) {
          return r.freeDelivery == true;
        }
        return r.freeDelivery == true || (r.minimumShippingCharge ?? 999) <= _maxDeliveryFeeFilter;
      }).toList();
    }

    if (_filterFastDelivery) {
      result = result.where((r) {
        final time = r.deliveryTime?.replaceAll(RegExp(r'[^0-9]'), '');
        if (time != null && time.isNotEmpty && time.length >= 2) {
          final minutes = int.tryParse(time.substring(0, 2)) ?? 100;
          return minutes <= 30;
        }
        return false;
      }).toList();
    }

    // Apply sorting
    result = _sortRestaurants(result);

    _filteredRestaurants = result;
    update();
  }

  List<Restaurant> _sortRestaurants(List<Restaurant> restaurants) {
    switch (_currentSortOption) {
      case SortOption.distance:
        return _sortByDistance(restaurants);
      case SortOption.rating:
        restaurants.sort((a, b) => (b.avgRating ?? 0).compareTo(a.avgRating ?? 0));
        return restaurants;
      case SortOption.deliveryTime:
        return _sortByDeliveryTime(restaurants);
      case SortOption.deliveryFee:
        // Sort by free delivery first, then by other criteria
        restaurants.sort((a, b) {
          if (a.freeDelivery == true && b.freeDelivery != true) return -1;
          if (b.freeDelivery == true && a.freeDelivery != true) return 1;
          return 0; // If both same, maintain order
        });
        return restaurants;
      case SortOption.popular:
        restaurants.sort((a, b) => (b.ratingCount ?? 0).compareTo(a.ratingCount ?? 0));
        return restaurants;
    }
  }

  List<Restaurant> _sortByDistance(List<Restaurant> restaurants) {
    final address = AddressHelper.getAddressFromSharedPref();
    if (address == null || address.latitude == null || address.longitude == null) {
      return restaurants;
    }

    final userLat = double.parse(address.latitude!);
    final userLng = double.parse(address.longitude!);

    restaurants.sort((a, b) {
      if (a.latitude == null || a.longitude == null) return 1;
      if (b.latitude == null || b.longitude == null) return -1;

      final distanceA = Geolocator.distanceBetween(
        userLat, userLng,
        double.parse(a.latitude!), double.parse(a.longitude!),
      );
      final distanceB = Geolocator.distanceBetween(
        userLat, userLng,
        double.parse(b.latitude!), double.parse(b.longitude!),
      );

      return distanceA.compareTo(distanceB);
    });

    return restaurants;
  }

  List<Restaurant> _sortByDeliveryTime(List<Restaurant> restaurants) {
    restaurants.sort((a, b) {
      final timeA = _extractDeliveryTime(a.deliveryTime);
      final timeB = _extractDeliveryTime(b.deliveryTime);
      return timeA.compareTo(timeB);
    });
    return restaurants;
  }

  int _extractDeliveryTime(String? timeString) {
    if (timeString == null) return 999;
    final match = RegExp(r'\d+').firstMatch(timeString);
    return match != null ? int.parse(match.group(0)!) : 999;
  }

  // Filter Persistence Methods
  Future<void> _loadSavedFilters() async {
    final prefs = Get.find<SharedPreferences>();

    // Load advanced filters
    _minRatingFilter = prefs.getDouble(AppConstants.exploreMinRatingFilter) ?? 0;
    _minPriceFilter = prefs.getInt(AppConstants.exploreMinPriceFilter) ?? 1;
    _maxPriceFilter = prefs.getInt(AppConstants.exploreMaxPriceFilter) ?? 4;
    _maxDeliveryFeeFilter = prefs.getDouble(AppConstants.exploreMaxDeliveryFeeFilter) ?? 20;

    // Load sort option (by index)
    final sortIndex = prefs.getInt(AppConstants.exploreSortOption) ?? 0;
    _currentSortOption = SortOption.values[sortIndex];

    // Load quick filters
    _filterOpenNow = prefs.getBool(AppConstants.exploreFilterOpenNow) ?? false;
    _filterFreeDelivery = prefs.getBool(AppConstants.exploreFilterFreeDelivery) ?? false;
    _filterTopRated = prefs.getBool(AppConstants.exploreFilterTopRated) ?? false;
    _filterFastDelivery = prefs.getBool(AppConstants.exploreFilterFastDelivery) ?? false;
  }

  Future<void> _saveFilters() async {
    final prefs = Get.find<SharedPreferences>();

    // Save advanced filters
    await prefs.setDouble(AppConstants.exploreMinRatingFilter, _minRatingFilter);
    await prefs.setInt(AppConstants.exploreMinPriceFilter, _minPriceFilter);
    await prefs.setInt(AppConstants.exploreMaxPriceFilter, _maxPriceFilter);
    await prefs.setDouble(AppConstants.exploreMaxDeliveryFeeFilter, _maxDeliveryFeeFilter);

    // Save sort option (by index)
    await prefs.setInt(AppConstants.exploreSortOption, _currentSortOption.index);

    // Save quick filters
    await prefs.setBool(AppConstants.exploreFilterOpenNow, _filterOpenNow);
    await prefs.setBool(AppConstants.exploreFilterFreeDelivery, _filterFreeDelivery);
    await prefs.setBool(AppConstants.exploreFilterTopRated, _filterTopRated);
    await prefs.setBool(AppConstants.exploreFilterFastDelivery, _filterFastDelivery);
  }

  @override
  void onInit() {
    super.onInit();
    _loadSavedFilters().then((_) {
      _loadSearchHistory();
      _loadMapPosition();
      getNearbyRestaurants(reload: true);
    });
  }

  @override
  void onClose() {
    _mapController?.dispose();
    _mapboxMap = null;
    _mapPositionSaveTimer?.cancel();
    super.onClose();
  }
}
