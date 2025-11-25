import 'package:godelivery_user/common/models/product_model.dart';
import 'package:godelivery_user/common/widgets/shared/feedback/custom_snackbar_widget.dart';
import 'package:godelivery_user/features/address/domain/models/address_model.dart';
import 'package:godelivery_user/features/category/controllers/category_controller.dart';
import 'package:godelivery_user/features/checkout/controllers/checkout_controller.dart';
import 'package:godelivery_user/features/home/domain/models/home_feed_model.dart';
import 'package:godelivery_user/features/language/controllers/localization_controller.dart';
import 'package:godelivery_user/features/location/controllers/location_controller.dart';
import 'package:godelivery_user/features/location/domain/models/zone_response_model.dart';
import 'package:godelivery_user/features/restaurant/domain/models/cart_suggested_item_model.dart';
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

  List<Product>? _restaurantProducts;
  List<Product>? get restaurantProducts => _restaurantProducts;

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

  ProductModel? _restaurantProductModel;
  ProductModel? get restaurantProductModel => _restaurantProductModel;

  ProductModel? _restaurantSearchProductModel;
  ProductModel? get restaurantSearchProductModel => _restaurantSearchProductModel;

  int _categoryIndex = 0;
  int get categoryIndex => _categoryIndex;

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

  CartSuggestItemModel? _cartSuggestItemModel;
  CartSuggestItemModel? get cartSuggestItemModel => _cartSuggestItemModel;

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
    // Use cached data if available
    if (_orderAgainRestaurantList != null && !reload) {
      print('✅ [RESTAURANT] Using cached order again list');
      return;
    }

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
    // Use cached data if available
    if (_recentlyViewedRestaurantList != null && !reload) {
      print('✅ [RESTAURANT] Using cached recently viewed list');
      return;
    }

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
    // Use cached data if available and not reloading
    if (_restaurantModel != null && !reload && offset == 0) {
      print('✅ [RESTAURANT] Using cached data: ${_restaurantModel!.restaurants!.length} restaurants');
      return;
    }

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
      print('🏪 [RESTAURANT CONTROLLER] Preparing restaurant list - offset: $offset, total: ${restaurantModel.totalSize}, count: ${restaurantModel.restaurants?.length ?? 0}');
      if (offset == 0) {
        _restaurantModel = restaurantModel;
        print('✅ [RESTAURANT CONTROLLER] Restaurant model set: ${_restaurantModel!.restaurants!.length} restaurants');
      } else {
        // Check if initial model exists before appending pagination data
        if (_restaurantModel != null) {
          _restaurantModel!.totalSize = restaurantModel.totalSize;
          _restaurantModel!.offset = restaurantModel.offset;
          _restaurantModel!.restaurants!.addAll(restaurantModel.restaurants!);
          print('✅ [RESTAURANT CONTROLLER] Appended ${restaurantModel.restaurants!.length} restaurants, total: ${_restaurantModel!.restaurants!.length}');
        } else {
          print('⚠️ [RESTAURANT CONTROLLER] Cannot append offset $offset - initial model not loaded yet, setting as initial');
          _restaurantModel = restaurantModel;
        }
      }
      update();
    } else {
      print('❌ [RESTAURANT CONTROLLER] Restaurant model is NULL!');
      // Set empty model to stop shimmer and show empty state
      if (offset == 0) {
        _restaurantModel = RestaurantModel(totalSize: 0, offset: 0, restaurants: []);
      }
      update();
    }
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
    // Use cached data if available
    if (_popularRestaurantList != null && !reload) {
      print('✅ [RESTAURANT] Using cached popular list');
      return;
    }

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
    // Use cached data if available
    if (_latestRestaurantList != null && !reload) {
      print('✅ [RESTAURANT] Using cached latest list');
      return;
    }

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
    _categoryIndex = 0;
    if(restaurant.name != null) {
      _restaurant = restaurant;
    }else {
      _isLoading = true;
      _restaurant = null;
      _restaurant = await restaurantServiceInterface.getRestaurantDetails(restaurant.id.toString(), slug, Get.find<LocalizationController>().locale.languageCode);
      if(_restaurant != null && _restaurant!.latitude != null){
        await _setRequiredDataAfterRestaurantGet(slug, fromCart);
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
    if(offset == 0 || _restaurantProducts == null) {
      _type = type;
      _foodOffsetList = [];
      _restaurantProducts = null;
      _foodOffset = 0;
      if(notify) {
        update();
      }
    }
    if (!_foodOffsetList.contains(offset)) {
      _foodOffsetList.add(offset);
      ProductModel? productModel = await restaurantServiceInterface.getRestaurantProductList(restaurantID, offset,
          (_restaurant != null && _restaurant!.categoryIds!.isNotEmpty && _categoryIndex != 0)
          ? _categoryList![_categoryIndex].id : 0, type);

      if (productModel != null) {
        if (offset == 0) {
          _restaurantProducts = [];
          _restaurantProducts!.addAll(productModel.products!);
        } else {
          // Ensure initial products list exists before appending
          if (_restaurantProducts != null) {
            _restaurantProducts!.addAll(productModel.products!);
          } else {
            print('⚠️ [RESTAURANT CONTROLLER] Cannot append offset $offset products - initial products not loaded yet, setting as initial');
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

  void setCategoryIndex(int index) {
    _categoryIndex = index;
    _restaurantProducts = null;
    getRestaurantProductList(_restaurant!.id, 1, Get.find<RestaurantController>().type, false);
    update();
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
    // Use cached data if available
    if (_homeFeedModel != null && !reload) {
      print('✅ [RESTAURANT] Using cached home feed');
      return;
    }

    if (reload) {
      _homeFeedModel = null;
      _sectionOffsets.clear();
      _sectionHasMore.clear();
      update();
    }

    print('🏠 [RESTAURANT] Fetching home feed...');
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

      print('✅ [RESTAURANT] Home feed loaded: ${homeFeedModel.categories?.length ?? 0} categories');
    } else {
      print('❌ [RESTAURANT] Home feed is NULL');
    }

    update();
  }

  /// Load more restaurants for a section (pagination)
  Future<void> loadMoreForSection(String section, {int? categoryId}) async {
    String key = categoryId != null ? 'category_$categoryId' : section;

    // Check if we have more data to load
    if (_sectionHasMore[key] != true) {
      print('ℹ️ [RESTAURANT] No more data for section: $key');
      return;
    }

    int nextOffset = (_sectionOffsets[key] ?? 1) + 1;
    print('📄 [RESTAURANT] Loading more for $key, offset: $nextOffset');

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

      print('✅ [RESTAURANT] Loaded ${response.restaurants!.length} more for $key');
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

}