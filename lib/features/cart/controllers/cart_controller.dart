import 'package:godelivery_user/api/api_checker.dart';
import 'package:godelivery_user/common/models/online_cart_model.dart';
import 'package:godelivery_user/common/models/product_model.dart';
import 'package:godelivery_user/common/models/restaurant_model.dart';
import 'package:godelivery_user/common/widgets/adaptive/cart/cart_snackbar_widget.dart';
import 'package:godelivery_user/common/widgets/shared/feedback/custom_snackbar_widget.dart';
import 'package:godelivery_user/features/checkout/domain/models/place_order_body_model.dart';
import 'package:godelivery_user/features/cart/domain/models/cart_model.dart';
import 'package:godelivery_user/features/cart/domain/models/restaurant_cart_model.dart';
import 'package:godelivery_user/features/cart/domain/services/cart_service_interface.dart';
import 'package:godelivery_user/features/product/controllers/product_controller.dart';
import 'package:godelivery_user/features/restaurant/controllers/restaurant_controller.dart';
import 'package:godelivery_user/helper/business_logic/auth_helper.dart';
import 'package:godelivery_user/helper/converters/date_converter.dart';
import 'package:godelivery_user/helper/converters/price_converter.dart';
import 'package:godelivery_user/helper/utilities/custom_debouncer_helper.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';

class CartController extends GetxController implements GetxService {
  final CartServiceInterface cartServiceInterface;

  CartController({required this.cartServiceInterface});

  // Debouncer for quantity updates to prevent API spam
  final _quantityDebouncer = CustomDebounceHelper(milliseconds: 500);

  @override
  void onInit() {
    super.onInit();
    // Load cart from local storage on initialization
    getCartDataFromLocal();
  }

  // PHASE 1: Multi-restaurant cart support
  // New state for grouped carts (populated alongside _cartList for backward compatibility)
  Map<int, RestaurantCart> _restaurantCarts = {};
  List<RestaurantCart> get restaurantCarts => _restaurantCarts.values.toList();
  int? _currentRestaurantId;

  // Get cart for specific restaurant
  RestaurantCart? getCartForRestaurant(int restaurantId) => _restaurantCarts[restaurantId];

  // Get list of restaurant IDs with active carts
  List<int> getActiveRestaurantIds() => _restaurantCarts.keys.toList();

  // Existing single cart list (maintained for backward compatibility)
  List<CartModel> _cartList = [];
  List<CartModel> get cartList => _cartList;

  double _subTotal = 0;
  double get subTotal => _subTotal;

  double _itemPrice = 0;
  double get itemPrice => _itemPrice;

  double _itemDiscountPrice = 0;
  double get itemDiscountPrice => _itemDiscountPrice;

  double _addOnsPrice = 0;
  double get addOns => _addOnsPrice;

  List<List<AddOns>> _addOnsList = [];
  List<List<AddOns>> get addOnsList => _addOnsList;

  List<bool> _availableList = [];
  List<bool> get availableList => _availableList;

  bool _addCutlery = false;
  bool get addCutlery => _addCutlery;

  int _notAvailableIndex = -1;
  int get notAvailableIndex => _notAvailableIndex;

  List<String> notAvailableList = ['Remove it from my cart', 'I’ll wait until it’s restocked', 'Please cancel the order', 'Call me ASAP', 'Notify me when it’s back'];

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isClearCartLoading = false;
  bool get isClearCartLoading => _isClearCartLoading;

  double _variationPrice = 0;
  double get variationPrice => _variationPrice;

  bool _needExtraPackage = true;
  bool get needExtraPackage => _needExtraPackage;

  bool _isExpanded = true;
  bool get isExpanded => _isExpanded;

  void toggleExtraPackage({bool willUpdate = true}) {
    _needExtraPackage = !_needExtraPackage;
    if(willUpdate) {
      update();
    }
  }

  void setNeedExtraPackage(bool needExtraPackage) {
    _needExtraPackage = needExtraPackage;
    update();
  }

  double calculationCart(){
    _itemPrice = 0 ;
    _itemDiscountPrice = 0;
    _subTotal = 0;
    _addOnsPrice = 0;
    _availableList= [];
    _addOnsList = [];
    _variationPrice = 0;
    double variationWithoutDiscountPrice = 0;
    double variationPrice = 0;
    for (var cartModel in _cartList) {

      variationWithoutDiscountPrice = 0;
      variationPrice = 0;

      double? discount = cartModel.product!.restaurantDiscount == 0 ? cartModel.product!.discount : cartModel.product!.restaurantDiscount;
      String? discountType = cartModel.product!.restaurantDiscount == 0 ? cartModel.product!.discountType : 'percent';

      List<AddOns> addOnList = cartServiceInterface.prepareAddonList(cartModel);

      _addOnsList.add(addOnList);
      _availableList.add(DateConverter.isAvailable(cartModel.product!.availableTimeStarts, cartModel.product!.availableTimeEnds));

      _addOnsPrice = cartServiceInterface.calculateAddonsPrice(addOnList, _addOnsPrice, cartModel);

      variationWithoutDiscountPrice = cartServiceInterface.calculateVariationWithoutDiscountPrice(cartModel, variationWithoutDiscountPrice, discount, discountType);
      variationPrice = cartServiceInterface.calculateVariationPrice(cartModel, variationPrice);

      double price = (cartModel.product!.price! * cartModel.quantity!);
      double discountPrice =  (price - (PriceConverter.convertWithDiscount(cartModel.product!.price!, discount, discountType)! * cartModel.quantity!));

      _variationPrice += variationPrice;
      _itemPrice = _itemPrice + price;
      _itemDiscountPrice = _itemDiscountPrice + discountPrice + (variationPrice - variationWithoutDiscountPrice);

      debugPrint('==check : ${_cartList.indexOf(cartModel)} ====> $_itemDiscountPrice = $_itemDiscountPrice + $discountPrice + ($variationPrice - $variationWithoutDiscountPrice)');
    }
    _subTotal = (_itemPrice - _itemDiscountPrice) + _addOnsPrice + _variationPrice;

    if (Get.find<RestaurantController>().restaurant != null && Get.find<RestaurantController>().restaurant!.discount != null) {
      if (Get.find<RestaurantController>().restaurant!.discount!.maxDiscount != 0 && Get.find<RestaurantController>().restaurant!.discount!.maxDiscount! < _itemDiscountPrice) {
        _itemDiscountPrice = Get.find<RestaurantController>().restaurant!.discount!.maxDiscount!;
        _subTotal = (_itemPrice - _itemDiscountPrice) + _addOnsPrice + _variationPrice;
      }
      if (Get.find<RestaurantController>().restaurant!.discount!.minPurchase != 0 && Get.find<RestaurantController>().restaurant!.discount!.minPurchase! > _subTotal) {
        _itemDiscountPrice = 0;
        _subTotal = (_itemPrice - _itemDiscountPrice) + _addOnsPrice + _variationPrice;
      }
    }
    return _subTotal;
  }

  Future<int?> reorderAddToCart(List<OnlineCart> cartList) async {
    await clearCartList();
    return _addMultipleCartItemOnline(cartList);
  }

  Future<void> setQuantity(bool isIncrement, CartModel cart, {int? cartIndex}) async {
    int index = cartIndex ?? _cartList.indexOf(cart);

    // Update quantity locally (optimistic update for instant UI feedback)
    _cartList[index].quantity = await cartServiceInterface.decideProductQuantity(_cartList, isIncrement, index);
    cartServiceInterface.addToSharedPrefCartList(_cartList);
    calculationCart();
    update(); // Update UI immediately

    // Debounce the API call to prevent spam when clicking rapidly
    final cartId = _cartList[index].id!;
    final price = _cartList[index].price!;
    final quantity = _cartList[index].quantity!;

    _quantityDebouncer.run(() {
      // Skip refresh to prevent overwriting local state during rapid clicks
      updateCartQuantityOnline(cartId, price, quantity, skipRefresh: true);
    });
  }

  void removeFromCart(int index) {
    _isLoading = true;
    int cartId = _cartList[index].id!;
    _cartList.removeAt(index);
    update();
    removeCartItemOnline(cartId);
  }

  void removeAddOn(int index, int addOnIndex) {
    _cartList[index].addOnIds!.removeAt(addOnIndex);
    cartServiceInterface.addToSharedPrefCartList(_cartList);
    calculationCart();
    update();
  }

  Future<void> clearCartList() async {
    _cartList = [];
    // Clear local storage
    cartServiceInterface.addToSharedPrefCartList([]);
    if(AuthHelper.isLoggedIn() || AuthHelper.isGuestLoggedIn()) {
      await clearCartOnline();
    }
  }


  int isExistInCart(int? productID, int? cartIndex) {
    return cartServiceInterface.isExistInCart(productID, cartIndex, _cartList);
  }

  bool existAnotherRestaurantProduct(int? restaurantID) {
    return cartServiceInterface.existAnotherRestaurantProduct(restaurantID, _cartList);
  }

  void updateCutlery({bool isUpdate = true}){
    _addCutlery = !_addCutlery;
    if(isUpdate) {
      update();
    }
  }

  void setAvailableIndex(int index, {bool willUpdate = true}){
    _notAvailableIndex = cartServiceInterface.setAvailableIndex(index, _notAvailableIndex);
    if(willUpdate) {
      update();
    }
  }

  int cartQuantity(int productID) {
    return cartServiceInterface.cartQuantity(productID, _cartList);
  }

  Future<void> addToCartOnline(OnlineCart onlineCart, {CartModel? existCartData, bool fromDirectlyAdd = false}) async {
    _isLoading = true;
    update();
    Response response = await cartServiceInterface.addToCartOnline(onlineCart, AuthHelper.isLoggedIn() ? null : AuthHelper.getGuestId());

    if(response.statusCode == 200) {
      List<OnlineCartModel> onlineCartList = [];
      response.body.forEach((cart) => onlineCartList.add(OnlineCartModel.fromJson(cart)));
      _cartList = [];
      _cartList.addAll(cartServiceInterface.formatOnlineCartToLocalCart(onlineCartModel: onlineCartList));
      calculationCart();
      if(!fromDirectlyAdd) {
        Get.back();
      }
      if(!Get.currentRoute.contains(RouteHelper.restaurant)) {
        showCartSnackBarWidget();
      }
    } else if(response.statusCode == 403 && response.body['errors'][0]['code'] == 'stock_out') {
      showCustomSnackBar(response.body['errors'][0]['message']);
      Get.find<ProductController>().getProductDetails(onlineCart.itemId!, existCartData);
    } else {
      ApiChecker.checkApi(response);
    }

    _isLoading = false;
    update();
  }

  Future<int?> _addMultipleCartItemOnline(List<OnlineCart> cartList) async {
    _isLoading = true;
    update();
    Response response = await cartServiceInterface.addMultipleCartItemOnline(cartList);
    if(response.statusCode == 200) {
      List<OnlineCartModel> onlineCartList = [];
      response.body.forEach((cart) => onlineCartList.add(OnlineCartModel.fromJson(cart)));
      _cartList = [];
      _cartList.addAll(cartServiceInterface.formatOnlineCartToLocalCart(onlineCartModel: onlineCartList));
      calculationCart();
    }
    _isLoading = false;
    update();
    return response.statusCode;
  }

  Future<void> updateCartOnline(OnlineCart onlineCart, {CartModel? existCartData, bool fromDirectlyAdd = false}) async {
    _isLoading = true;
    update();
    Response response = await cartServiceInterface.updateCartOnline(onlineCart, AuthHelper.isLoggedIn() ? null : int.parse(AuthHelper.getGuestId()));
    if(response.statusCode == 200) {
      List<OnlineCartModel> onlineCartList = [];
      response.body.forEach((cart) => onlineCartList.add(OnlineCartModel.fromJson(cart)));
      _cartList = [];
      _cartList.addAll(cartServiceInterface.formatOnlineCartToLocalCart(onlineCartModel: onlineCartList));
      calculationCart();
      if(!fromDirectlyAdd) {
        Get.back();
      }
      if(!Get.currentRoute.contains(RouteHelper.restaurant)) {
        showCartSnackBarWidget();
      }
    } else if(response.statusCode == 403 && response.body['errors'][0]['code'] == 'stock_out') {
      showCustomSnackBar(response.body['errors'][0]['message']);
      Get.find<ProductController>().getProductDetails(onlineCart.itemId!, existCartData);
    } else {
      ApiChecker.checkApi(response);
    }
    _isLoading = false;
    update();
  }

  Future<void> updateCartQuantityOnline(int cartId, double price, int quantity, {bool skipRefresh = false}) async {
    // _isLoading = true;
    // update();
    bool success = await cartServiceInterface.updateCartQuantityOnline(cartId, price, quantity, AuthHelper.isLoggedIn() ? null : AuthHelper.getGuestId());
    if(success && !skipRefresh) {
      getCartDataOnline();
      calculationCart();
    }
    // _isLoading = false;
    // update();
  }

  /// Load cart data from local storage (SharedPreferences)
  /// This serves as a fallback when API is unavailable or user session expires
  void getCartDataFromLocal() {
    _cartList = cartServiceInterface.getCartListFromSharedPref();
    if (_cartList.isNotEmpty) {
      calculationCart();
      groupCartsByRestaurant();
      update();
      debugPrint('✅ Loaded ${_cartList.length} items from local storage');
    }
  }

  Future<void> getCartDataOnline() async {
    _isLoading = true;
    List<OnlineCartModel> onlineCartList = await cartServiceInterface.getCartDataOnline(AuthHelper.isLoggedIn() ? null : AuthHelper.getGuestId());
    _cartList = [];
    _cartList.addAll(cartServiceInterface.formatOnlineCartToLocalCart(onlineCartModel: onlineCartList));

    // Save to local storage for offline access
    cartServiceInterface.addToSharedPrefCartList(_cartList);

    calculationCart();

    // PHASE 1: Group carts by restaurant after fetching
    groupCartsByRestaurant();

    _isLoading = false;
    update();
  }

  Future<bool> removeCartItemOnline(int cartId) async {
    _isLoading = true;
    update();
    bool isSuccess = await cartServiceInterface.removeCartItemOnline(cartId, AuthHelper.isLoggedIn() ? null : AuthHelper.getGuestId());
    getCartDataOnline();
    _isLoading = false;
    update();
    return isSuccess;
  }

  Future<bool> clearCartOnline() async {
    _isLoading = true;
    _isClearCartLoading = true;
    update();
    bool success = await cartServiceInterface.clearCartOnline(AuthHelper.isLoggedIn() ? null : AuthHelper.getGuestId());
    if(success) {
      getCartDataOnline();
    }
    _isLoading = false;
    _isClearCartLoading = false;
    update();
    return success;
  }

  void setExpanded(bool setExpand) {
    _isExpanded = setExpand;
    update();
  }

  // ============================================================================
  // PHASE 1: Multi-Restaurant Cart Grouping Methods
  // ============================================================================

  /// Group cart items by restaurant ID
  /// This method is called after fetching cart data to organize items by restaurant
  void groupCartsByRestaurant() {
    _restaurantCarts.clear();

    if (_cartList.isEmpty) {
      _currentRestaurantId = null;
      return;
    }

    // Group items by restaurant ID
    Map<int, List<CartModel>> groupedItems = {};
    for (var cartItem in _cartList) {
      int? restaurantId = cartItem.product?.restaurantId;
      if (restaurantId != null) {
        if (!groupedItems.containsKey(restaurantId)) {
          groupedItems[restaurantId] = [];
        }
        groupedItems[restaurantId]!.add(cartItem);
      }
    }

    // Create RestaurantCart objects for each restaurant
    for (var entry in groupedItems.entries) {
      int restaurantId = entry.key;
      List<CartModel> items = entry.value;

      // Get restaurant details from the first item's product
      Restaurant? restaurant = items.first.product?.restaurantId != null
          ? _getRestaurantFromCartItem(items.first)
          : null;

      if (restaurant != null) {
        // Calculate subtotal for this restaurant's cart
        double subtotal = _calculateSubtotalForItems(items);

        _restaurantCarts[restaurantId] = RestaurantCart(
          restaurantId: restaurantId,
          restaurant: restaurant,
          items: items,
          subtotal: subtotal,
          isActive: restaurant.active == true,
        );
      }
    }

    // Set current restaurant ID (for backward compatibility)
    if (_restaurantCarts.isNotEmpty) {
      _currentRestaurantId = _restaurantCarts.keys.first;
    }
  }

  /// Helper method to get Restaurant object from cart item
  /// In production, this should fetch from RestaurantController or API
  Restaurant? _getRestaurantFromCartItem(CartModel cartItem) {
    // Try to get from RestaurantController first
    try {
      var restaurantController = Get.find<RestaurantController>();
      if (restaurantController.restaurant != null &&
          restaurantController.restaurant!.id == cartItem.product?.restaurantId) {
        return restaurantController.restaurant;
      }
    } catch (e) {
      debugPrint('RestaurantController not found: $e');
    }

    // Fallback: Create minimal Restaurant object from product data
    // Note: In Phase 3, we should fetch full restaurant data from API
    if (cartItem.product?.restaurantId != null) {
      return Restaurant(
        id: cartItem.product!.restaurantId,
        name: cartItem.product!.restaurantName ?? 'Restaurant',
        logoFullUrl: cartItem.product!.imageFullUrl ?? '',
        coverPhotoFullUrl: '',
        address: '',
        latitude: '',
        longitude: '',
        minimumOrder: 0,
        avgRating: 0,
        tax: 0,
        active: true,
        open: 1,
        delivery: true,
        takeAway: true,
        deliveryTime: '30-40 min',
      );
    }

    return null;
  }

  /// Calculate subtotal for a list of cart items
  double _calculateSubtotalForItems(List<CartModel> items) {
    double itemPrice = 0;
    double itemDiscountPrice = 0;
    double addOnsPrice = 0;
    double variationPrice = 0;

    for (var cartModel in items) {
      double? discount = cartModel.product!.restaurantDiscount == 0
          ? cartModel.product!.discount
          : cartModel.product!.restaurantDiscount;
      String? discountType = cartModel.product!.restaurantDiscount == 0
          ? cartModel.product!.discountType
          : 'percent';

      List<AddOns> addOnList = cartServiceInterface.prepareAddonList(cartModel);
      addOnsPrice = cartServiceInterface.calculateAddonsPrice(addOnList, addOnsPrice, cartModel);

      double variationWithoutDiscountPrice = 0;
      double currentVariationPrice = 0;
      variationWithoutDiscountPrice = cartServiceInterface.calculateVariationWithoutDiscountPrice(
        cartModel,
        variationWithoutDiscountPrice,
        discount,
        discountType,
      );
      currentVariationPrice = cartServiceInterface.calculateVariationPrice(cartModel, currentVariationPrice);

      double price = (cartModel.product!.price! * cartModel.quantity!);
      double discountPrice = (price -
          (PriceConverter.convertWithDiscount(cartModel.product!.price!, discount, discountType)! * cartModel.quantity!));

      variationPrice += currentVariationPrice;
      itemPrice += price;
      itemDiscountPrice += discountPrice + (currentVariationPrice - variationWithoutDiscountPrice);
    }

    return (itemPrice - itemDiscountPrice) + addOnsPrice + variationPrice;
  }

  /// Set the current restaurant context (for backward compatibility with single-restaurant flow)
  void setCurrentRestaurant(int restaurantId) {
    _currentRestaurantId = restaurantId;
    update();
  }

  /// Get cart items for a specific restaurant
  List<CartModel> getCartItemsForRestaurant(int restaurantId) {
    return _restaurantCarts[restaurantId]?.items ?? [];
  }

  /// Update special instructions for a restaurant's cart
  /// Note: Currently stores in memory only. In Phase 2, this will sync with checkout session
  void setCartSpecialInstructions(int restaurantId, String instructions) {
    if (_restaurantCarts.containsKey(restaurantId)) {
      _restaurantCarts[restaurantId] = _restaurantCarts[restaurantId]!.copyWith(
        specialInstructions: instructions.isEmpty ? null : instructions,
      );
      update();
    }
  }

}