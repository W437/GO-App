import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:godelivery_user/common/models/restaurant_model.dart';
import 'package:godelivery_user/features/category/controllers/category_controller.dart';
import 'package:godelivery_user/features/location/controllers/location_controller.dart';
import 'package:godelivery_user/features/restaurant/controllers/restaurant_controller.dart';
import 'package:godelivery_user/helper/address_helper.dart';

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

  double _sheetPosition = 0.5;
  double get sheetPosition => _sheetPosition;

  bool _isFullscreenMode = false;
  bool get isFullscreenMode => _isFullscreenMode;

  int get activeFilterCount {
    int count = 0;
    if (_filterOpenNow) count++;
    if (_filterFreeDelivery) count++;
    if (_filterTopRated) count++;
    if (_filterFastDelivery) count++;
    if (_selectedCategoryId != null) count++;
    return count;
  }

  void setMapController(GoogleMapController controller) {
    _mapController = controller;
  }

  Future<void> getNearbyRestaurants({bool reload = false}) async {
    if (reload) {
      _isLoading = true;
      update();
    }

    await restaurantController.getRestaurantList(1, reload, fromMap: true);
    _nearbyRestaurants = restaurantController.restaurantModel?.restaurants;
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
  }

  void animateToRestaurant(Restaurant restaurant) {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(
            double.parse(restaurant.latitude ?? '0'),
            double.parse(restaurant.longitude ?? '0'),
          ),
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

  void searchRestaurants(String query) {
    _searchQuery = query.toLowerCase();
    _applyFiltersAndSort();
  }

  void clearSearch() {
    _searchQuery = '';
    _applyFiltersAndSort();
  }

  void setSortOption(SortOption option) {
    _currentSortOption = option;
    _applyFiltersAndSort();
  }

  void toggleOpenNowFilter() {
    _filterOpenNow = !_filterOpenNow;
    _applyFiltersAndSort();
  }

  void toggleFreeDeliveryFilter() {
    _filterFreeDelivery = !_filterFreeDelivery;
    _applyFiltersAndSort();
  }

  void toggleTopRatedFilter() {
    _filterTopRated = !_filterTopRated;
    _applyFiltersAndSort();
  }

  void toggleFastDeliveryFilter() {
    _filterFastDelivery = !_filterFastDelivery;
    _applyFiltersAndSort();
  }

  void clearAllFilters() {
    _filterOpenNow = false;
    _filterFreeDelivery = false;
    _filterTopRated = false;
    _filterFastDelivery = false;
    _selectedCategoryId = null;
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

  @override
  void onInit() {
    super.onInit();
    getNearbyRestaurants(reload: true);
  }

  @override
  void onClose() {
    _mapController?.dispose();
    super.onClose();
  }
}
