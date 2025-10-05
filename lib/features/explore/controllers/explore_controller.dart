import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:godelivery_user/common/models/restaurant_model.dart';
import 'package:godelivery_user/features/category/controllers/category_controller.dart';
import 'package:godelivery_user/features/location/controllers/location_controller.dart';
import 'package:godelivery_user/features/restaurant/controllers/restaurant_controller.dart';

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
    _filteredRestaurants = _nearbyRestaurants;

    _isLoading = false;
    update();
  }

  void filterByCategory(int? categoryId) {
    _selectedCategoryId = categoryId;

    if (categoryId == null) {
      // Show all restaurants
      _filteredRestaurants = _nearbyRestaurants;
    } else {
      // Filter by category
      _filteredRestaurants = _nearbyRestaurants?.where((restaurant) {
        return restaurant.categoryIds?.contains(categoryId) ?? false;
      }).toList();
    }

    update();
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
