import 'package:godelivery_user/common/models/product_model.dart';
import 'package:godelivery_user/common/widgets/shared/feedback/custom_toast_widget.dart';
import 'package:godelivery_user/features/address/domain/models/address_model.dart';
import 'package:godelivery_user/features/category/controllers/category_controller.dart';
import 'package:godelivery_user/features/checkout/controllers/checkout_controller.dart';
import 'package:godelivery_user/features/explore/domain/models/map_explore_response.dart';
import 'package:godelivery_user/features/home/domain/models/home_feed_model.dart';
import 'package:godelivery_user/features/language/controllers/localization_controller.dart';
import 'package:godelivery_user/features/location/controllers/location_controller.dart';
import 'package:godelivery_user/features/location/domain/models/zone_response_model.dart';
import 'package:godelivery_user/features/restaurant/domain/models/menu_sections_response.dart';
import 'package:godelivery_user/features/restaurant/domain/models/recommended_product_model.dart';
import 'package:godelivery_user/common/models/restaurant_model.dart';
import 'package:godelivery_user/features/category/domain/models/category_model.dart';
import 'package:godelivery_user/features/restaurant/domain/services/restaurant_service_interface.dart';
import 'package:godelivery_user/helper/business_logic/address_helper.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RestaurantController extends GetxController implements GetxService {
  final RestaurantServiceInterface restaurantServiceInterface;

  RestaurantController({required this.restaurantServiceInterface});

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

  Restaurant? _restaurant;
  Restaurant? get restaurant => _restaurant;

  // Track current restaurant to detect changes
  int? _currentRestaurantId;
  bool _isTransitioning = false;

  bool get isTransitioning => _isTransitioning;

  // === MENU NAVIGATION STATE ===
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

  /// Get cached restaurant data from any loaded list (for optimistic UI)
  Restaurant? getCachedRestaurant(int restaurantId) {
    // Check currently loaded restaurant first
    if (_restaurant?.id == restaurantId) return _restaurant;

    // Search all cached restaurant lists
    Restaurant? findInList(List<Restaurant>? list) {
      return list?.firstWhereOrNull((r) => r.id == restaurantId);
    }

    return findInList(_restaurantModel?.restaurants)
        ?? findInList(_popularRestaurantList)
        ?? findInList(_latestRestaurantList)
        ?? findInList(_recentlyViewedRestaurantList)
        ?? findInList(_orderAgainRestaurantList)
        ?? findInList(_homeFeedModel?.newRestaurants?.restaurants)
        ?? findInList(_homeFeedModel?.popular?.restaurants);
  }

  /// Find section containing a product
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

  // Detect if switching to a different restaurant
  bool isNewRestaurant(int? restaurantId) {
    return _currentRestaurantId != restaurantId;
  }

  // Clear stale data when switching restaurants
  void prepareForNewRestaurant(int restaurantId, {bool notify = true}) {
    if (isNewRestaurant(restaurantId)) {
      _isTransitioning = true;
      _restaurant = null;
      _menuSections = null;
      _menuSectionsMeta = null;
      _restaurantProducts = null;
      _currentRestaurantId = restaurantId;

      // Clear navigation state
      _activeSectionId = null;
      _isManualScrolling = false;

      if (notify) {
        update(); // Trigger rebuild with cleared state
      }
    }
  }

  // Mark transition complete after data loads
  void completeTransition() {
    _isTransitioning = false;
    update();
  }

  /// Load restaurant data (handles caching internally)
  /// This is the single entry point for loading a restaurant - all caching logic is encapsulated here
  Future<void> loadRestaurant(int restaurantId, {String slug = ''}) async {
    // Step 1: Prepare for new restaurant (clears stale data if switching)
    prepareForNewRestaurant(restaurantId, notify: false);

    // Step 2: Check what data we already have
    final bool isSameRestaurant = _restaurant?.id == restaurantId;
    final bool hasFullDetails = isSameRestaurant &&
                                _restaurant != null &&
                                _restaurant!.schedules != null &&
                                _restaurant!.schedules!.isNotEmpty;
    final bool hasCorrectProducts = _restaurantProducts != null &&
                                    _restaurantProducts!.isNotEmpty &&
                                    _restaurantProducts!.first.restaurantId == restaurantId;
    final bool hasCorrectSections = _menuSections != null &&
                                    _menuSections!.isNotEmpty;

    // Step 3: Fetch lightweight menu sections first (shows sticky header immediately)
    if (!isSameRestaurant) {
      await getMenuSections(restaurantId);
    }

    // Step 4: Parallel load restaurant details and products
    final List<Future> parallelCalls = [];

    if (!isSameRestaurant || !hasFullDetails) {
      parallelCalls.add(
        getRestaurantDetails(Restaurant(id: restaurantId), slug: slug)
      );
    }

    if (!isSameRestaurant || (!hasCorrectProducts && !hasCorrectSections)) {
      parallelCalls.add(
        getRestaurantProductList(restaurantId, 0, 'all', false)
      );
    }

    if (parallelCalls.isNotEmpty) {
      await Future.wait(parallelCalls);
    }

    // Step 5: Mark transition complete
    completeTransition();
  }

  List<Product>? _restaurantProducts;
  List<Product>? get restaurantProducts => _restaurantProducts;

  // NEW: Menu sections support
  List<MenuSection>? _menuSections;
  List<MenuSection>? get menuSections => _menuSections;

  // Lightweight section metadata (from /menu-sections endpoint)
  List<MenuSectionMeta>? _menuSectionsMeta;
  List<MenuSectionMeta>? get menuSectionsMeta => _menuSectionsMeta;

  // Filter visible sections only
  List<MenuSection>? get visibleMenuSections {
    if (_menuSections == null) return null;
    return _menuSections!.where((section) => section.isVisible == true).toList();
  }

  // Check if using section-based structure (either full sections or just metadata)
  // Also return true during transitions to show skeleton loading state
  bool get isUsingSections => _isTransitioning ||
                               (_menuSections != null && _menuSections!.isNotEmpty) ||
                               (_menuSectionsMeta != null && _menuSectionsMeta!.isNotEmpty);

  // Filter recommended products from main product list using is_recommended flag
  List<Product>? get recommendedProducts {
    if (_restaurantProducts == null) return null;
    return _restaurantProducts!.where((product) => product.isRecommended == true).toList();
  }

  // Filter popular products from main product list using is_popular flag
  List<Product>? get popularProducts {
    if (_restaurantProducts == null) return null;
    return _restaurantProducts!.where((product) => product.isPopular == true).toList();
  }

  ProductModel? _restaurantSearchProductModel;
  ProductModel? get restaurantSearchProductModel => _restaurantSearchProductModel;

  List<CategoryModel>? _categoryList;
  List<CategoryModel>? get categoryList => _categoryList;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _restaurantType = 'all';
  String get restaurantType => _restaurantType;

  bool _foodPaginate = false;
  bool get foodPaginate => _foodPaginate;

  int? _foodPageSize;
  int? get foodPageSize => _foodPageSize;

  List<int> _foodOffsetList = [];

  int _foodOffset = 0;
  int get foodOffset => _foodOffset;

  String _type = 'all';
  String get type => _type;

  String _searchType = 'all';
  String get searchType => _searchType;

  String _searchText = '';
  String get searchText => _searchText;

  RecommendedProductModel? _recommendedProductModel;
  RecommendedProductModel? get recommendedProductModel => _recommendedProductModel;

  List<Product>? _suggestedItems;
  List<Product>? get suggestedItems => _suggestedItems;

  int? _foodPageOffset;
  int? get foodPageOffset => _foodPageOffset;

  bool _isSearching = false;
  bool get isSearching => _isSearching;

  List<Restaurant>? _orderAgainRestaurantList;
  List<Restaurant>? get orderAgainRestaurantList => _orderAgainRestaurantList;

  int _topRated = 0;
  int get topRated => _topRated;

  int _discount = 0;
  int get discount => _discount;

  int _veg = 0;
  int get veg => _veg;

  int _nonVeg = 0;
  int get nonVeg => _nonVeg;

  int _nearestRestaurantIndex = -1;
  int get nearestRestaurantIndex => _nearestRestaurantIndex;

  // Home Feed data
  HomeFeedModel? _homeFeedModel;
  HomeFeedModel? get homeFeedModel => _homeFeedModel;

  // Pagination state for each section
  final Map<String, int> _sectionOffsets = {};
  final Map<String, bool> _sectionHasMore = {};

  void setNearestRestaurantIndex(int index, {bool notify = true}) {
    _nearestRestaurantIndex = index;
    if(notify) {
      update();
    }
  }

  double getRestaurantDistance(LatLng restaurantLatLng){
    return restaurantServiceInterface.getRestaurantDistanceFromUser(restaurantLatLng);
  }

  String filteringUrl(String slug){
    return restaurantServiceInterface.filterRestaurantLinkUrl(slug, _restaurant?.id, _restaurant?.zoneId);
  }

  Future<void> getOrderAgainRestaurantList(bool reload) async {
    if (_orderAgainRestaurantList != null && !reload) return;

    if(reload) {
      _orderAgainRestaurantList = null;
      update();
    }

    List<Restaurant>? orderAgainRestaurantList = await restaurantServiceInterface.getOrderAgainRestaurantList();
    _prepareOrderAgainRestaurantList(orderAgainRestaurantList);
  }

  _prepareOrderAgainRestaurantList(List<Restaurant>? restaurantList) {
    if (restaurantList != null) {
      _orderAgainRestaurantList = [];
      _orderAgainRestaurantList = restaurantList;
    }
    update();
  }

  Future<void> getRecentlyViewedRestaurantList(bool reload, String type, bool notify) async {
    if (_recentlyViewedRestaurantList != null && !reload) return;

    _type = type;
    if(reload){
      _recentlyViewedRestaurantList = null;
      if(notify) {
        update();
      }
    }

    List<Restaurant>? recentlyViewedRestaurantList = await restaurantServiceInterface.getRecentlyViewedRestaurantList(type);
    _prepareRecentlyViewedRestaurantList(recentlyViewedRestaurantList);
  }

  _prepareRecentlyViewedRestaurantList(List<Restaurant>? restaurantList) {
    if (restaurantList != null) {
      _recentlyViewedRestaurantList = [];
      _recentlyViewedRestaurantList = restaurantList;
    }
    update();
  }

  Future<void> getRestaurantRecommendedItemList(int? restaurantId, bool reload) async {
    _recommendedProductModel = null;
    if(reload) {
      _restaurantModel = null;
      update();
    }
    _recommendedProductModel = await restaurantServiceInterface.getRestaurantRecommendedItemList(restaurantId);
    update();
  }

  Future<void> getRestaurantList(int offset, bool reload, {bool fromMap = false}) async {
    if (_restaurantModel != null && !reload && offset == 0) return;

    if(reload) {
      // Keep empty model if reloading with 0 restaurants (avoids shimmer flash)
      final hadEmptyList = _restaurantModel?.restaurants?.isEmpty ?? false;
      if (!hadEmptyList) {
        _restaurantModel = null;
        update();
      }
    }

    RestaurantModel? restaurantModel = await restaurantServiceInterface.getRestaurantList(offset, _restaurantType, _topRated, _discount, _veg, _nonVeg, fromMap: fromMap);
    _prepareRestaurantList(restaurantModel, offset);
  }

  _prepareRestaurantList(RestaurantModel? restaurantModel, int offset) {
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

  Future<void> getPopularRestaurantList(bool reload, String type, bool notify) async {
    if (_popularRestaurantList != null && !reload) return;

    _type = type;
    if (reload) {
      _popularRestaurantList = null;
      if (notify) {
        update();
      }
    }

    List<Restaurant>? popularRestaurantList = await restaurantServiceInterface.getPopularRestaurantList(type);
    _preparePopularRestaurantList(popularRestaurantList);
  }

  _preparePopularRestaurantList(List<Restaurant>? restaurantList) {
    if (restaurantList != null) {
      _popularRestaurantList = [];
      _popularRestaurantList!.addAll(restaurantList);
    }
    update();
  }

  Future<void> getLatestRestaurantList(bool reload, String type, bool notify) async {
    if (_latestRestaurantList != null && !reload) return;

    _type = type;
    if(reload){
      _latestRestaurantList = null;
      if(notify) {
        update();
      }
    }

    List<Restaurant>? latestRestaurantList = await restaurantServiceInterface.getLatestRestaurantList(type);
    _prepareLatestRestaurantList(latestRestaurantList);
  }

  _prepareLatestRestaurantList(List<Restaurant>? restaurantList) {
    if (restaurantList != null) {
      _latestRestaurantList = [];
      _latestRestaurantList = restaurantList;
    }
    update();
  }

  void setCategoryList() {
    if(Get.find<CategoryController>().categoryList != null && _restaurant != null) {
      _categoryList = restaurantServiceInterface.setCategories(Get.find<CategoryController>().categoryList!, _restaurant!);
    }
  }


  Future<Restaurant?> getRestaurantDetails(Restaurant restaurant, {bool fromCart = false, String slug = ''}) async {
    // Always fetch from API if:
    // 1. Restaurant has no name (only ID passed) - we need full details
    // 2. Restaurant has no schedules - we need full details including hours
    final bool needsFullDetails = restaurant.name == null ||
                                   restaurant.schedules == null ||
                                   restaurant.schedules!.isEmpty;

    if(!needsFullDetails) {
      _restaurant = restaurant;
    } else {
      _isLoading = true;
      // Don't clear existing restaurant data to avoid UI flicker
      final Restaurant? fetchedRestaurant = await restaurantServiceInterface.getRestaurantDetails(
        restaurant.id.toString(),
        slug,
        Get.find<LocalizationController>().locale.languageCode
      );

      if (fetchedRestaurant != null) {
        _restaurant = fetchedRestaurant;
        if(_restaurant!.latitude != null){
          await _setRequiredDataAfterRestaurantGet(slug, fromCart);
        }
      }

      Get.find<CheckoutController>().setOrderType(
        (_restaurant != null && _restaurant!.delivery != null) ? _restaurant!.delivery! ? 'delivery' : 'take_away' : 'delivery', notify: false,
      );

      _isLoading = false;
      update();
    }
    return _restaurant;
  }

  Future<void> _setRequiredDataAfterRestaurantGet(String slug, bool fromCart) async {
    Get.find<CheckoutController>().initializeTimeSlot(_restaurant!);
    if(!fromCart && slug.isEmpty){
      Get.find<CheckoutController>().getDistanceInKM(
        LatLng(
          double.parse(AddressHelper.getAddressFromSharedPref()!.latitude!),
          double.parse(AddressHelper.getAddressFromSharedPref()!.longitude!),
        ),
        LatLng(double.parse(_restaurant!.latitude!), double.parse(_restaurant!.longitude!)),
      );
    }
    if(slug.isNotEmpty){
      await _setStoreAddressToUserAddress(LatLng(double.parse(_restaurant!.latitude!), double.parse(_restaurant!.longitude!)));
    }
  }

  Future<void> _setStoreAddressToUserAddress(LatLng restaurantAddress) async {
    Position storePosition = Position(
      latitude: restaurantAddress.latitude, longitude: restaurantAddress.longitude,
      timestamp: DateTime.now(), accuracy: 1, altitude: 1, heading: 1, speed: 1, speedAccuracy: 1, altitudeAccuracy: 1, headingAccuracy: 1,
    );
    String addressFromGeocode = await Get.find<LocationController>().getAddressFromGeocode(LatLng(restaurantAddress.latitude, restaurantAddress.longitude));
    ZoneResponseModel responseModel = await Get.find<LocationController>().getZone(storePosition.latitude.toString(), storePosition.longitude.toString(), true);
    AddressModel addressModel = restaurantServiceInterface.prepareAddressModel(storePosition, responseModel, addressFromGeocode);
    await AddressHelper.saveAddressInSharedPref(addressModel);
  }

  void makeEmptyRestaurant({bool willUpdate = true}) {
    _restaurant = null;
    if(willUpdate) {
      update();
    }
  }

  Future<void> getCartRestaurantSuggestedItemList(int? restaurantID) async {
    _suggestedItems = await restaurantServiceInterface.getCartRestaurantSuggestedItemList(restaurantID);
    update();
  }

  Future<void> getRestaurantProductList(int? restaurantID, int offset, String type, bool notify) async {
    _foodOffset = offset;
    if(offset == 0 || (_restaurantProducts == null && _menuSections == null)) {
      _type = type;
      _foodOffsetList = [];
      _restaurantProducts = null;
      _menuSections = null; // Clear sections when resetting
      _foodOffset = 0;
      if(notify) {
        update();
      }
    }
    if (!_foodOffsetList.contains(offset)) {
      _foodOffsetList.add(offset);
      // Category filtering is no longer used for section-based menus
      ProductModel? productModel = await restaurantServiceInterface.getRestaurantProductList(restaurantID, offset, 0, type);

      if (productModel != null) {
        // NEW: Handle section-based response
        if (productModel.sections != null && productModel.sections!.isNotEmpty) {
          if (offset == 0) {
            _menuSections = productModel.sections;
          } else {
            // Append products to existing sections (for pagination)
            if (_menuSections != null && productModel.sections != null) {
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
    } else {
      if(_foodPaginate) {
        _foodPaginate = false;
        update();
      }
    }
  }

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

  Future<void> getRestaurantSearchProductList(String searchText, String? storeID, int offset, String type) async {
    if(searchText.isEmpty) {
      showCustomSnackBar('write_item_name'.tr);
    }else {
      _isSearching = true;
      _searchText = searchText;
      if(offset == 0 || _restaurantSearchProductModel == null) {
        _searchType = type;
        _restaurantSearchProductModel = null;
        update();
      }
      ProductModel? productModel = await restaurantServiceInterface.getRestaurantSearchProductList(searchText, storeID, offset, type);
      if (productModel != null) {
        if (offset == 0) {
          _restaurantSearchProductModel = productModel;
        }else {
          _restaurantSearchProductModel!.products!.addAll(productModel.products!);
          _restaurantSearchProductModel!.totalSize = productModel.totalSize;
          _restaurantSearchProductModel!.offset = productModel.offset;
        }
      }
      update();
    }
  }

  void changeSearchStatus({bool isUpdate = true}) {
    _isSearching = !_isSearching;
    if(isUpdate) {
      update();
    }
  }

  void initSearchData() {
    _restaurantSearchProductModel = ProductModel(products: []);
    _searchText = '';
    _searchType = 'all';
  }

  bool isRestaurantClosed(DateTime dateTime, bool active, List<Schedules>? schedules, {int? customDateDuration}) {
    return restaurantServiceInterface.isRestaurantClosed(dateTime, active, schedules);
  }

  bool isRestaurantOpenNow(bool active, List<Schedules>? schedules) {
    return restaurantServiceInterface.isRestaurantOpenNow(active, schedules);
  }

  bool isOpenNow(Restaurant restaurant) => restaurant.open == 1 && restaurant.active!;

  double? getDiscount(Restaurant restaurant) => restaurant.discount != null ? restaurant.discount!.discount : 0;

  String? getDiscountType(Restaurant restaurant) => restaurant.discount != null ? restaurant.discount!.discountType : 'percent';

  // ========== Home Feed Methods ==========

  /// Get the initial home feed data
  Future<void> getHomeFeed(bool reload) async {
    if (_homeFeedModel != null && !reload) return;

    if (reload) {
      _homeFeedModel = null;
      _sectionOffsets.clear();
      _sectionHasMore.clear();
      update();
    }

    HomeFeedModel? homeFeedModel = await restaurantServiceInterface.getHomeFeed();

    if (homeFeedModel != null) {
      _homeFeedModel = homeFeedModel;

      // Initialize pagination state for each section
      if (homeFeedModel.newRestaurants != null) {
        _sectionOffsets['new'] = homeFeedModel.newRestaurants!.offset ?? 1;
        _sectionHasMore['new'] = homeFeedModel.newRestaurants!.hasMore ?? false;
      }
      if (homeFeedModel.popular != null) {
        _sectionOffsets['popular'] = homeFeedModel.popular!.offset ?? 1;
        _sectionHasMore['popular'] = homeFeedModel.popular!.hasMore ?? false;
      }

      // Initialize category pagination
      if (homeFeedModel.categories != null) {
        for (var category in homeFeedModel.categories!) {
          if (category.id != null) {
            _sectionOffsets['category_${category.id}'] = category.offset ?? 1;
            _sectionHasMore['category_${category.id}'] = category.hasMore ?? false;
          }
        }
      }
    }

    update();
  }

  /// Load more restaurants for a section (pagination)
  Future<void> loadMoreForSection(String section, {int? categoryId}) async {
    String key = categoryId != null ? 'category_$categoryId' : section;

    if (_sectionHasMore[key] != true) return;

    int nextOffset = (_sectionOffsets[key] ?? 1) + 1;

    HomeFeedSectionResponse? response = await restaurantServiceInterface.getHomeFeedSection(
      section,
      categoryId: categoryId,
      offset: nextOffset,
    );

    if (response != null && response.restaurants != null) {
      // Update pagination state
      _sectionOffsets[key] = response.offset ?? nextOffset;
      _sectionHasMore[key] = response.hasMore ?? false;

      // Append restaurants to the appropriate section
      if (categoryId != null && _homeFeedModel?.categories != null) {
        final categoryIndex = _homeFeedModel!.categories!.indexWhere((c) => c.id == categoryId);
        if (categoryIndex != -1) {
          _homeFeedModel!.categories![categoryIndex].restaurants?.addAll(response.restaurants!);
        }
      } else if (section == 'new' && _homeFeedModel?.newRestaurants != null) {
        _homeFeedModel!.newRestaurants!.restaurants?.addAll(response.restaurants!);
      } else if (section == 'popular' && _homeFeedModel?.popular != null) {
        _homeFeedModel!.popular!.restaurants?.addAll(response.restaurants!);
      }

      update();
    }
  }

  /// Check if a section has more data to load
  bool hasMoreForSection(String section, {int? categoryId}) {
    String key = categoryId != null ? 'category_$categoryId' : section;
    return _sectionHasMore[key] ?? false;
  }

  /// Get categories from home feed
  List<HomeFeedCategorySection>? get homeFeedCategories => _homeFeedModel?.categories;

  /// Get restaurants for map explore screen
  Future<MapExploreResponse?> getMapExploreRestaurants() async {
    return await restaurantServiceInterface.getMapExploreRestaurants();
  }

  /// Get menu sections metadata for a restaurant (lightweight, fast)
  Future<void> getMenuSections(int restaurantId) async {
    MenuSectionsResponse? response = await restaurantServiceInterface.getMenuSections(restaurantId);
    if (response != null && response.sections != null) {
      _menuSectionsMeta = response.sections;
      update();
    }
  }
}