import 'package:godelivery_user/common/models/product_model.dart';
import 'package:godelivery_user/common/widgets/shared/feedback/custom_toast_widget.dart';
import 'package:godelivery_user/features/address/domain/models/address_model.dart';
import 'package:godelivery_user/features/category/controllers/category_controller.dart';
import 'package:godelivery_user/features/category/domain/models/category_model.dart';
import 'package:godelivery_user/features/checkout/controllers/checkout_controller.dart';
import 'package:godelivery_user/features/explore/domain/models/map_explore_response.dart';
import 'package:godelivery_user/features/language/controllers/localization_controller.dart';
import 'package:godelivery_user/features/location/controllers/location_controller.dart';
import 'package:godelivery_user/features/location/domain/models/zone_response_model.dart';
import 'package:godelivery_user/features/restaurant/domain/models/menu_sections_response.dart';
import 'package:godelivery_user/features/restaurant/domain/models/recommended_product_model.dart';
import 'package:godelivery_user/features/restaurant/domain/services/restaurant_service_interface.dart';
import 'package:godelivery_user/common/models/restaurant_model.dart';
import 'package:godelivery_user/helper/business_logic/address_helper.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Cache entry for a loaded restaurant (in-memory only)
class _RestaurantCacheEntry {
  final int id;
  final Restaurant restaurant;
  final List<MenuSection>? sections;
  final List<MenuSectionMeta>? sectionsMeta;
  final DateTime loadedAt;

  _RestaurantCacheEntry({
    required this.id,
    required this.restaurant,
    this.sections,
    this.sectionsMeta,
    required this.loadedAt,
  });

  bool get isStale => DateTime.now().difference(loadedAt) > const Duration(minutes: 10);
}

class RestaurantController extends GetxController implements GetxService {
  final RestaurantServiceInterface restaurantServiceInterface;

  RestaurantController({required this.restaurantServiceInterface});

  // ==================== CORE RESTAURANT DATA ====================

  Restaurant? _restaurant;
  Restaurant? get restaurant => _restaurant;

  // Recently loaded restaurants cache (keeps last 5)
  final List<_RestaurantCacheEntry> _loadedRestaurants = [];

  RestaurantModel? _restaurantModel;
  RestaurantModel? get restaurantModel => _restaurantModel;

  List<Restaurant>? _restaurantList;
  List<Restaurant>? get restaurantList => _restaurantList;

  List<Restaurant>? _popularRestaurantList;
  List<Restaurant>? get popularRestaurantList => _popularRestaurantList;

  List<Restaurant>? _latestRestaurantList;
  List<Restaurant>? get latestRestaurantList => _latestRestaurantList;

  List<Restaurant>? _recentlyViewedRestaurantList;
  List<Restaurant>? get recentlyViewedRestaurantList => _recentlyViewedRestaurantList;

  List<Restaurant>? _orderAgainRestaurantList;
  List<Restaurant>? get orderAgainRestaurantList => _orderAgainRestaurantList;

  int? _currentRestaurantId;
  bool _isTransitioning = false;
  bool get isTransitioning => _isTransitioning;

  // ==================== MENU & PRODUCT DATA ====================

  List<MenuSection>? _menuSections;
  List<MenuSection>? get menuSections => _menuSections;

  List<MenuSectionMeta>? _menuSectionsMeta;
  List<MenuSectionMeta>? get menuSectionsMeta => _menuSectionsMeta;

  List<Product>? _restaurantProducts;
  List<Product>? get restaurantProducts => _restaurantProducts;

  List<Product>? _suggestedItems;
  List<Product>? get suggestedItems => _suggestedItems;

  RecommendedProductModel? _recommendedProductModel;
  RecommendedProductModel? get recommendedProductModel => _recommendedProductModel;

  ProductModel? _restaurantSearchProductModel;
  ProductModel? get restaurantSearchProductModel => _restaurantSearchProductModel;

  List<CategoryModel>? _categoryList;
  List<CategoryModel>? get categoryList => _categoryList;

  // Computed properties
  List<MenuSection>? get visibleMenuSections {
    if (_menuSections == null) return null;
    return _menuSections!.where((section) => section.isVisible == true).toList();
  }

  bool get isUsingSections => _isTransitioning ||
                               (_menuSections != null && _menuSections!.isNotEmpty) ||
                               (_menuSectionsMeta != null && _menuSectionsMeta!.isNotEmpty);

  List<Product>? get recommendedProducts {
    if (_restaurantProducts == null) return null;
    return _restaurantProducts!.where((product) => product.isRecommended == true).toList();
  }

  List<Product>? get popularProducts {
    if (_restaurantProducts == null) return null;
    return _restaurantProducts!.where((product) => product.isPopular == true).toList();
  }

  // ==================== FILTERS & STATE ====================

  String _restaurantType = 'all';
  String get restaurantType => _restaurantType;

  String _type = 'all';
  String get type => _type;

  int _topRated = 0;
  int get topRated => _topRated;

  int _discount = 0;
  int get discount => _discount;

  int _veg = 0;
  int get veg => _veg;

  int _nonVeg = 0;
  int get nonVeg => _nonVeg;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  int _nearestRestaurantIndex = -1;
  int get nearestRestaurantIndex => _nearestRestaurantIndex;

  // ==================== SEARCH STATE ====================

  bool _isSearching = false;
  bool get isSearching => _isSearching;

  String _searchText = '';
  String get searchText => _searchText;

  String _searchType = 'all';
  String get searchType => _searchType;

  // ==================== PAGINATION STATE ====================

  bool _foodPaginate = false;
  bool get foodPaginate => _foodPaginate;

  int _foodOffset = 0;
  int get foodOffset => _foodOffset;

  int? _foodPageSize;
  int? get foodPageSize => _foodPageSize;

  int? _foodPageOffset;
  int? get foodPageOffset => _foodPageOffset;

  List<int> _foodOffsetList = [];

  // ==================== NAVIGATION STATE ====================

  int? _activeSectionId;
  int? get activeSectionId => _activeSectionId;

  bool _isManualScrolling = false;
  bool get isManualScrolling => _isManualScrolling;

  void setActiveSectionId(int? id) {
    if (_activeSectionId != id) {
      _activeSectionId = id;
      update();
    }
  }

  void setManualScrolling(bool value) {
    _isManualScrolling = value;
  }

  // ==================== PUBLIC API - MAIN ENTRY POINTS ====================

  /// Load restaurant data (single entry point - handles caching internally)
  Future<void> loadRestaurant(int restaurantId, {String slug = ''}) async {
    // Check cache first
    final cached = _getCachedRestaurantData(restaurantId);

    if (cached != null && !cached.isStale) {
      // Restore from cache
      _restaurant = cached.restaurant;
      _menuSections = cached.sections;
      _menuSectionsMeta = cached.sectionsMeta;
      _currentRestaurantId = restaurantId;
      _isTransitioning = false;
      update();
      return;
    }

    // Not in cache or stale - fetch from API
    prepareForNewRestaurant(restaurantId, notify: false);

    // Fetch lightweight menu sections first
    await getMenuSections(restaurantId);

    // Parallel load restaurant details and products
    await Future.wait([
      getRestaurantDetails(Restaurant(id: restaurantId), slug: slug),
      getRestaurantProductList(restaurantId, 0, 'all', false),
    ]);

    // Cache the loaded data
    _cacheLoadedRestaurant(restaurantId);

    completeTransition();
  }

  // ==================== RESTAURANT LIST METHODS ====================

  Future<void> getRestaurantList(int offset, bool reload, {bool fromMap = false}) async {
    if (_restaurantModel != null && !reload && offset == 0) return;

    if (reload) {
      final hadEmptyList = _restaurantModel?.restaurants?.isEmpty ?? false;
      if (!hadEmptyList) {
        _restaurantModel = null;
        update();
      }
    }

    RestaurantModel? restaurantModel = await restaurantServiceInterface.getRestaurantList(
      offset, _restaurantType, _topRated, _discount, _veg, _nonVeg, fromMap: fromMap
    );
    _prepareRestaurantList(restaurantModel, offset);
  }

  Future<void> getPopularRestaurantList(bool reload, String type, bool notify) async {
    if (_popularRestaurantList != null && !reload) return;

    _type = type;
    if (reload) {
      _popularRestaurantList = null;
      if (notify) update();
    }

    List<Restaurant>? popularRestaurantList = await restaurantServiceInterface.getPopularRestaurantList(type);
    _preparePopularRestaurantList(popularRestaurantList);
  }

  Future<void> getLatestRestaurantList(bool reload, String type, bool notify) async {
    if (_latestRestaurantList != null && !reload) return;

    _type = type;
    if (reload) {
      _latestRestaurantList = null;
      if (notify) update();
    }

    List<Restaurant>? latestRestaurantList = await restaurantServiceInterface.getLatestRestaurantList(type);
    _prepareLatestRestaurantList(latestRestaurantList);
  }

  Future<void> getRecentlyViewedRestaurantList(bool reload, String type, bool notify) async {
    if (_recentlyViewedRestaurantList != null && !reload) return;

    _type = type;
    if (reload) {
      _recentlyViewedRestaurantList = null;
      if (notify) update();
    }

    List<Restaurant>? recentlyViewedRestaurantList = await restaurantServiceInterface.getRecentlyViewedRestaurantList(type);
    _prepareRecentlyViewedRestaurantList(recentlyViewedRestaurantList);
  }

  Future<void> getOrderAgainRestaurantList(bool reload) async {
    if (_orderAgainRestaurantList != null && !reload) return;

    if (reload) {
      _orderAgainRestaurantList = null;
      update();
    }

    List<Restaurant>? orderAgainRestaurantList = await restaurantServiceInterface.getOrderAgainRestaurantList();
    _prepareOrderAgainRestaurantList(orderAgainRestaurantList);
  }

  Future<Restaurant?> getRestaurantDetails(Restaurant restaurant, {bool fromCart = false, String slug = ''}) async {
    final bool needsFullDetails = restaurant.name == null ||
                                   restaurant.schedules == null ||
                                   restaurant.schedules!.isEmpty;

    if (!needsFullDetails) {
      _restaurant = restaurant;
    } else {
      _isLoading = true;
      final Restaurant? fetchedRestaurant = await restaurantServiceInterface.getRestaurantDetails(
        restaurant.id.toString(),
        slug,
        Get.find<LocalizationController>().locale.languageCode
      );

      if (fetchedRestaurant != null) {
        _restaurant = fetchedRestaurant;
        if (_restaurant!.latitude != null) {
          await _setRequiredDataAfterRestaurantGet(slug, fromCart);
        }
      }

      Get.find<CheckoutController>().setOrderType(
        (_restaurant != null && _restaurant!.delivery != null)
            ? _restaurant!.delivery! ? 'delivery' : 'take_away'
            : 'delivery',
        notify: false,
      );

      _isLoading = false;
      update();
    }
    return _restaurant;
  }

  // ==================== PRODUCT METHODS ====================

  Future<void> getRestaurantProductList(int? restaurantID, int offset, String type, bool notify) async {
    _foodOffset = offset;
    if (offset == 0 || (_restaurantProducts == null && _menuSections == null)) {
      _type = type;
      _foodOffsetList = [];
      _restaurantProducts = null;
      _menuSections = null;
      _foodOffset = 0;
      if (notify) update();
    }

    if (!_foodOffsetList.contains(offset)) {
      _foodOffsetList.add(offset);
      ProductModel? productModel = await restaurantServiceInterface.getRestaurantProductList(restaurantID, offset, 0, type);

      if (productModel != null) {
        // Handle section-based response
        if (productModel.sections != null && productModel.sections!.isNotEmpty) {
          if (offset == 0) {
            _menuSections = productModel.sections;
          } else if (_menuSections != null && productModel.sections != null) {
            for (var newSection in productModel.sections!) {
              var existingSection = _menuSections!.firstWhereOrNull((s) => s.id == newSection.id);
              if (existingSection != null && newSection.products != null) {
                existingSection.products ??= [];
                existingSection.products!.addAll(newSection.products!);
              } else {
                _menuSections!.add(newSection);
              }
            }
          }
        }
        // Legacy: Handle flat products array
        else if (productModel.products != null) {
          if (offset == 0) {
            _restaurantProducts = [];
            _restaurantProducts!.addAll(productModel.products!);
          } else if (_restaurantProducts != null) {
            _restaurantProducts!.addAll(productModel.products!);
          } else {
            _restaurantProducts = [];
            _restaurantProducts!.addAll(productModel.products!);
          }
        }

        _foodPageSize = productModel.totalSize;
        _foodPageOffset = productModel.offset;
        _foodPaginate = false;
        update();
      }
    } else if (_foodPaginate) {
      _foodPaginate = false;
      update();
    }
  }

  Future<void> getRestaurantSearchProductList(String searchText, String? storeID, int offset, String type) async {
    if (searchText.isEmpty) {
      showCustomSnackBar('write_item_name'.tr);
      return;
    }

    _isSearching = true;
    _searchText = searchText;
    if (offset == 0 || _restaurantSearchProductModel == null) {
      _searchType = type;
      _restaurantSearchProductModel = null;
      update();
    }

    ProductModel? productModel = await restaurantServiceInterface.getRestaurantSearchProductList(searchText, storeID, offset, type);
    if (productModel != null) {
      if (offset == 0) {
        _restaurantSearchProductModel = productModel;
      } else {
        _restaurantSearchProductModel!.products!.addAll(productModel.products!);
        _restaurantSearchProductModel!.totalSize = productModel.totalSize;
        _restaurantSearchProductModel!.offset = productModel.offset;
      }
    }
    update();
  }

  Future<void> getRestaurantRecommendedItemList(int? restaurantId, bool reload) async {
    _recommendedProductModel = null;
    if (reload) {
      _restaurantModel = null;
      update();
    }
    _recommendedProductModel = await restaurantServiceInterface.getRestaurantRecommendedItemList(restaurantId);
    update();
  }

  Future<void> getCartRestaurantSuggestedItemList(int? restaurantID) async {
    _suggestedItems = await restaurantServiceInterface.getCartRestaurantSuggestedItemList(restaurantID);
    update();
  }

  Future<void> getMenuSections(int restaurantId) async {
    MenuSectionsResponse? response = await restaurantServiceInterface.getMenuSections(restaurantId);
    if (response != null && response.sections != null) {
      _menuSectionsMeta = response.sections;
      update();
    }
  }

  // ==================== FILTER SETTERS ====================

  void setRestaurantType(String type) {
    _restaurantType = type;
    getRestaurantList(0, true);
  }

  void setTopRated() {
    _topRated = restaurantServiceInterface.setTopRated(_topRated);
    getRestaurantList(0, true);
  }

  void setDiscount() {
    _discount = restaurantServiceInterface.setDiscounted(_discount);
    getRestaurantList(0, true);
  }

  void setVeg() {
    _veg = restaurantServiceInterface.setVeg(_veg);
    getRestaurantList(0, true);
  }

  void setNonVeg() {
    _nonVeg = restaurantServiceInterface.setNonVeg(_nonVeg);
    getRestaurantList(0, true);
  }

  void setNearestRestaurantIndex(int index, {bool notify = true}) {
    _nearestRestaurantIndex = index;
    if (notify) update();
  }

  void setCategoryList() {
    if (Get.find<CategoryController>().categoryList != null && _restaurant != null) {
      _categoryList = restaurantServiceInterface.setCategories(
        Get.find<CategoryController>().categoryList!,
        _restaurant!
      );
    }
  }

  // ==================== SEARCH METHODS ====================

  void changeSearchStatus({bool isUpdate = true}) {
    _isSearching = !_isSearching;
    if (isUpdate) update();
  }

  void initSearchData() {
    _restaurantSearchProductModel = ProductModel(products: []);
    _searchText = '';
    _searchType = 'all';
  }

  // ==================== PAGINATION HELPERS ====================

  void showFoodBottomLoader() {
    _foodPaginate = true;
    update();
  }

  void setFoodOffset(int offset) {
    _foodOffset = offset;
  }

  void showBottomLoader() {
    _isLoading = true;
    update();
  }

  // ==================== STATE MANAGEMENT ====================

  bool isNewRestaurant(int? restaurantId) {
    return _currentRestaurantId != restaurantId;
  }

  void prepareForNewRestaurant(int restaurantId, {bool notify = true}) {
    // Only clear if switching to a DIFFERENT restaurant than what's currently loaded
    if (_restaurant?.id != restaurantId) {
      _isTransitioning = true;
      _restaurant = null;
      _menuSections = null;
      _menuSectionsMeta = null;
      _restaurantProducts = null;
      _currentRestaurantId = restaurantId;
      _activeSectionId = null;
      _isManualScrolling = false;

      if (notify) update();
    }
  }

  void completeTransition() {
    _isTransitioning = false;
    update();
  }

  void makeEmptyRestaurant({bool willUpdate = true}) {
    _restaurant = null;
    if (willUpdate) update();
  }

  // ==================== HELPER METHODS ====================

  /// Get cached restaurant from any loaded list (for optimistic UI)
  Restaurant? getCachedRestaurant(int restaurantId) {
    if (_restaurant?.id == restaurantId) return _restaurant;

    Restaurant? findInList(List<Restaurant>? list) {
      return list?.firstWhereOrNull((r) => r.id == restaurantId);
    }

    return findInList(_restaurantModel?.restaurants)
        ?? findInList(_popularRestaurantList)
        ?? findInList(_latestRestaurantList)
        ?? findInList(_recentlyViewedRestaurantList)
        ?? findInList(_orderAgainRestaurantList);
  }

  MenuSection? findSectionForProduct(int productId) {
    final sections = visibleMenuSections;
    if (sections == null) return null;
    for (final section in sections) {
      if (section.products?.any((p) => p.id == productId) ?? false) {
        return section;
      }
    }
    return null;
  }

  double getRestaurantDistance(LatLng restaurantLatLng) {
    return restaurantServiceInterface.getRestaurantDistanceFromUser(restaurantLatLng);
  }

  String filteringUrl(String slug) {
    return restaurantServiceInterface.filterRestaurantLinkUrl(slug, _restaurant?.id, _restaurant?.zoneId);
  }

  // ==================== UTILITY METHODS ====================

  bool isRestaurantClosed(DateTime dateTime, bool active, List<Schedules>? schedules, {int? customDateDuration}) {
    return restaurantServiceInterface.isRestaurantClosed(dateTime, active, schedules);
  }

  bool isRestaurantOpenNow(bool active, List<Schedules>? schedules) {
    return restaurantServiceInterface.isRestaurantOpenNow(active, schedules);
  }

  bool isOpenNow(Restaurant restaurant) => restaurant.open == 1 && restaurant.active!;

  double? getDiscount(Restaurant restaurant) => restaurant.discount != null ? restaurant.discount!.discount : 0;

  String? getDiscountType(Restaurant restaurant) => restaurant.discount != null ? restaurant.discount!.discountType : 'percent';

  Future<MapExploreResponse?> getMapExploreRestaurants() async {
    return await restaurantServiceInterface.getMapExploreRestaurants();
  }

  // ==================== PRIVATE METHODS ====================

  void _prepareRestaurantList(RestaurantModel? restaurantModel, int offset) {
    if (restaurantModel != null) {
      if (offset == 0) {
        _restaurantModel = restaurantModel;
      } else if (_restaurantModel != null) {
        _restaurantModel!.totalSize = restaurantModel.totalSize;
        _restaurantModel!.offset = restaurantModel.offset;
        _restaurantModel!.restaurants!.addAll(restaurantModel.restaurants!);
      } else {
        _restaurantModel = restaurantModel;
      }
    } else if (offset == 0) {
      _restaurantModel = RestaurantModel(totalSize: 0, offset: 0, restaurants: []);
    }
    update();
  }

  void _preparePopularRestaurantList(List<Restaurant>? restaurantList) {
    if (restaurantList != null) {
      _popularRestaurantList = [];
      _popularRestaurantList!.addAll(restaurantList);
    }
    update();
  }

  void _prepareLatestRestaurantList(List<Restaurant>? restaurantList) {
    if (restaurantList != null) {
      _latestRestaurantList = [];
      _latestRestaurantList = restaurantList;
    }
    update();
  }

  void _prepareRecentlyViewedRestaurantList(List<Restaurant>? restaurantList) {
    if (restaurantList != null) {
      _recentlyViewedRestaurantList = [];
      _recentlyViewedRestaurantList = restaurantList;
    }
    update();
  }

  void _prepareOrderAgainRestaurantList(List<Restaurant>? restaurantList) {
    if (restaurantList != null) {
      _orderAgainRestaurantList = [];
      _orderAgainRestaurantList = restaurantList;
    }
    update();
  }

  /// Get cached restaurant data by ID
  _RestaurantCacheEntry? _getCachedRestaurantData(int restaurantId) {
    return _loadedRestaurants.firstWhereOrNull((entry) => entry.id == restaurantId);
  }

  /// Cache loaded restaurant data (keeps last 5)
  void _cacheLoadedRestaurant(int restaurantId) {
    if (_restaurant == null) return;

    // Remove old entry if exists
    _loadedRestaurants.removeWhere((entry) => entry.id == restaurantId);

    // Add new entry at the front
    _loadedRestaurants.insert(
      0,
      _RestaurantCacheEntry(
        id: restaurantId,
        restaurant: _restaurant!,
        sections: _menuSections,
        sectionsMeta: _menuSectionsMeta,
        loadedAt: DateTime.now(),
      ),
    );

    // Keep only last 5 restaurants
    if (_loadedRestaurants.length > 5) {
      _loadedRestaurants.removeLast();
    }
  }

  Future<void> _setRequiredDataAfterRestaurantGet(String slug, bool fromCart) async {
    Get.find<CheckoutController>().initializeTimeSlot(_restaurant!);
    if (!fromCart && slug.isEmpty) {
      Get.find<CheckoutController>().getDistanceInKM(
        LatLng(
          double.parse(AddressHelper.getAddressFromSharedPref()!.latitude!),
          double.parse(AddressHelper.getAddressFromSharedPref()!.longitude!),
        ),
        LatLng(double.parse(_restaurant!.latitude!), double.parse(_restaurant!.longitude!)),
      );
    }
    if (slug.isNotEmpty) {
      await _setStoreAddressToUserAddress(LatLng(double.parse(_restaurant!.latitude!), double.parse(_restaurant!.longitude!)));
    }
  }

  Future<void> _setStoreAddressToUserAddress(LatLng restaurantAddress) async {
    Position storePosition = Position(
      latitude: restaurantAddress.latitude,
      longitude: restaurantAddress.longitude,
      timestamp: DateTime.now(),
      accuracy: 1,
      altitude: 1,
      heading: 1,
      speed: 1,
      speedAccuracy: 1,
      altitudeAccuracy: 1,
      headingAccuracy: 1,
    );
    String addressFromGeocode = await Get.find<LocationController>().getAddressFromGeocode(
      LatLng(restaurantAddress.latitude, restaurantAddress.longitude)
    );
    ZoneResponseModel responseModel = await Get.find<LocationController>().getZone(
      storePosition.latitude.toString(),
      storePosition.longitude.toString(),
      true
    );
    AddressModel addressModel = restaurantServiceInterface.prepareAddressModel(storePosition, responseModel, addressFromGeocode);
    await AddressHelper.saveAddressInSharedPref(addressModel);
  }
}
