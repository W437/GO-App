import 'package:godelivery_user/common/models/product_model.dart';
import 'package:godelivery_user/common/models/restaurant_model.dart';
import 'package:godelivery_user/common/widgets/shared/feedback/custom_snackbar_widget.dart';
import 'package:godelivery_user/features/cart/controllers/cart_controller.dart';
import 'package:godelivery_user/features/checkout/controllers/checkout_controller.dart';
import 'package:godelivery_user/features/checkout/domain/models/place_order_body_model.dart';
import 'package:godelivery_user/features/checkout/widgets/bottom_section_widget.dart';
import 'package:godelivery_user/features/checkout/widgets/checkout_screen_shimmer_view.dart';
import 'package:godelivery_user/features/checkout/widgets/order_place_button.dart';
import 'package:godelivery_user/features/checkout/widgets/top_section_widget.dart';
import 'package:godelivery_user/features/coupon/controllers/coupon_controller.dart';
import 'package:godelivery_user/features/home/controllers/home_controller.dart';
import 'package:godelivery_user/features/location/domain/models/zone_response_model.dart';
import 'package:godelivery_user/features/profile/controllers/profile_controller.dart';
import 'package:godelivery_user/features/splash/controllers/splash_controller.dart';
import 'package:godelivery_user/features/address/controllers/address_controller.dart';
import 'package:godelivery_user/features/address/domain/models/address_model.dart';
import 'package:godelivery_user/features/cart/domain/models/cart_model.dart';
import 'package:godelivery_user/features/auth/controllers/auth_controller.dart';
import 'package:godelivery_user/features/location/controllers/location_controller.dart';
import 'package:godelivery_user/features/splash/domain/models/config_model.dart';
import 'package:godelivery_user/helper/business_logic/address_helper.dart';
import 'package:godelivery_user/helper/business_logic/auth_helper.dart';
import 'package:godelivery_user/helper/utilities/custom_validator.dart';
import 'package:godelivery_user/helper/converters/date_converter.dart';
import 'package:godelivery_user/helper/converters/price_converter.dart';
import 'package:godelivery_user/helper/ui/responsive_helper.dart';
import 'package:godelivery_user/util/app_constants.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:godelivery_user/common/widgets/adaptive/navigation/custom_app_bar_widget.dart';
import 'package:godelivery_user/common/widgets/adaptive/navigation/footer_view_widget.dart';
import 'package:godelivery_user/common/widgets/mobile/menu_drawer_widget.dart';
import 'package:godelivery_user/common/widgets/adaptive/empty_states/not_logged_in_screen.dart';
import 'package:godelivery_user/common/widgets/web/web_page_title_widget.dart';
import 'package:get/get.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:flutter/material.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CartModel>? cartList;
  final bool fromCart;
  final bool fromDineInPage;
  const CheckoutScreen({super.key, required this.fromCart, required this.cartList, this.fromDineInPage = false});

  @override
  CheckoutScreenState createState() => CheckoutScreenState();
}

class CheckoutScreenState extends State<CheckoutScreen> {
  double? taxPercent = 0;
  bool? _isCashOnDeliveryActive = false;
  bool? _isDigitalPaymentActive = false;
  bool _isOfflinePaymentActive = false;
  bool _isWalletActive = false;
  List<CartModel>? _cartList;
  double? _payableAmount = 0;
  String _deliveryChargeForView = '';

  List<AddressModel> address = [];
  bool firstTime = true;
  final tooltipController1 = JustTheController();
  final tooltipController2 = JustTheController();
  final tooltipController3 = JustTheController();
  final loginTooltipController = JustTheController();
  final serviceFeeTooltipController = JustTheController();
  final deliveryFeeTooltipController = JustTheController();

  final ExpansibleController expansionTileController = ExpansibleController();

  final TextEditingController guestContactPersonNameController = TextEditingController();
  final TextEditingController guestContactPersonNumberController = TextEditingController();
  final TextEditingController guestEmailController = TextEditingController();
  final FocusNode guestNumberNode = FocusNode();
  final FocusNode guestEmailNode = FocusNode();

  final TextEditingController estimateArrivalDateController = TextEditingController();
  final TextEditingController estimateArrivalTimeController = TextEditingController();

  final ScrollController scrollController = ScrollController();
  final ScrollController deliveryOptionScrollController = ScrollController();

  double badWeatherChargeForToolTip = 0;
  double extraChargeForToolTip = 0;
  bool _calledOrderTax = false;

  @override
  void initState() {
    super.initState();

    initCall();
  }

  Future<void> initCall() async {
    bool isLoggedIn = AuthHelper.isLoggedIn();
    CheckoutController checkoutController = Get.find<CheckoutController>();

    checkoutController.streetNumberController.text = AddressHelper.getAddressFromSharedPref()!.road ?? '';
    checkoutController.houseController.text = AddressHelper.getAddressFromSharedPref()!.house ?? '';
    checkoutController.floorController.text = AddressHelper.getAddressFromSharedPref()!.floor ?? '';
    checkoutController.couponController.text = '';

    checkoutController.clearPrevData();
    checkoutController.getDmTipMostTapped();
    checkoutController.setPreferenceTimeForView('', false, isUpdate: false);
    checkoutController.setCustomDate(null, false, canUpdate: false);

    checkoutController.getOfflineMethodList();
    checkoutController.initDineInSetup();
    checkoutController.setExchangeAmount(0);

    Get.find<LocationController>().getZone(
      AddressHelper.getAddressFromSharedPref()!.latitude,
      AddressHelper.getAddressFromSharedPref()!.longitude, false, updateInAddress: true,
    );

    _cartList = [];

    await Get.find<CartController>().getCartDataOnline();
    widget.fromCart ? _cartList!.addAll(Get.find<CartController>().cartList) : _cartList!.addAll(widget.cartList!);

    if(isLoggedIn){
      if(Get.find<ProfileController>().userInfoModel == null && Get.find<ProfileController>().userInfoModel?.userInfo == null) {
        Get.find<ProfileController>().getUserInfo();
      }

      if(Get.find<AddressController>().addressList == null) {
        Get.find<AddressController>().getAddressList(canInsertAddress: true);
      }
    }

    checkoutController.setRestaurantDetails(restaurantId: _cartList![0].product!.restaurantId);

    checkoutController.initCheckoutData(_cartList![0].product!.restaurantId);


    Get.find<CouponController>().setCoupon('', isUpdate: false);

    checkoutController.stopLoader(isUpdate: false);
    checkoutController.updateTimeSlot(0, false, notify: false);

    _isCashOnDeliveryActive = Get.find<SplashController>().configModel!.cashOnDelivery;
    _isDigitalPaymentActive = Get.find<SplashController>().configModel!.digitalPayment;
    _isOfflinePaymentActive = Get.find<SplashController>().configModel!.offlinePaymentStatus!;
    _isWalletActive = Get.find<SplashController>().configModel!.customerWalletStatus == 1;

    checkoutController.updateTips(
      checkoutController.getDmTipIndex().isNotEmpty ? int.parse(checkoutController.getDmTipIndex()) : 0, notify: false,
    );
    checkoutController.tipController.text = checkoutController.selectedTips != -1 ? AppConstants.tips[checkoutController.selectedTips] : '';

    setSinglePaymentActive();

    Future.delayed(const Duration(milliseconds: 500), () {

      if(!Get.find<SplashController>().configModel!.homeDelivery! && Get.find<SplashController>().configModel!.takeAway!) {
        checkoutController.setOrderType('take_away', notify: true);
      }

      if(checkoutController.isPartialPay){
        checkoutController.changePartialPayment(isUpdate: false);
      }

      if(widget.fromDineInPage) {
        _selectDineIn();
      }
    });

    if(AuthHelper.isLoggedIn()) {
      String phone = await _splitPhoneNumber(Get.find<ProfileController>().userInfoModel?.userInfo?.phone ?? '');

      guestContactPersonNameController.text = '${Get.find<ProfileController>().userInfoModel?.userInfo?.fName ?? ''} ${Get.find<ProfileController>().userInfoModel?.userInfo?.lName ?? ''}';
      guestContactPersonNumberController.text = phone;
      guestEmailController.text = Get.find<ProfileController>().userInfoModel?.userInfo?.email ?? '';
    }


  }

  Future<void> _selectDineIn() async {

    Future.delayed(Duration(milliseconds: 800), () {
      Get.find<CheckoutController>().setOrderType('dine_in', notify: true);
      Future.delayed(Duration(milliseconds: 500), () {
        if(Get.find<CheckoutController>().restaurant != null && Get.find<CheckoutController>().distance != null) {
          Get.find<CheckoutController>().setOrderType('dine_in', notify: true);
          _animateDeliverySection();
        } else {
          Future.delayed(Duration(seconds: 3), () {
            Get.find<CheckoutController>().setOrderType('dine_in', notify: true);
            _animateDeliverySection();
          });
        }
      });
    });

  }

  _animateDeliverySection() {
    if(deliveryOptionScrollController.hasClients) {
      deliveryOptionScrollController.animateTo(
        deliveryOptionScrollController.position.maxScrollExtent, // Scroll to the end
        duration: Duration(milliseconds: 500), // Set the duration of the animation
        curve: Curves.easeOut, // Set the curve for the animation
      );
    }
  }

  Future<String> _splitPhoneNumber(String number) async {
    PhoneValid phoneNumber = await CustomValidator.isPhoneValid(number);
    Get.find<CheckoutController>().countryDialCode = '+${phoneNumber.countryCode}';
    return phoneNumber.phone.replaceFirst('+${phoneNumber.countryCode}', '');
  }

  void setSinglePaymentActive() {
    if(!_isCashOnDeliveryActive! && _isDigitalPaymentActive! && Get.find<SplashController>().configModel!.activePaymentMethodList!.length == 1 && !_isWalletActive) {
      Get.find<CheckoutController>().setPaymentMethod(2, willUpdate: false);
      Get.find<CheckoutController>().changeDigitalPaymentName(Get.find<SplashController>().configModel!.activePaymentMethodList![0].getWay!);
    }
  }

  @override
  Widget build(BuildContext context) {

    bool guestCheckoutPermission = AuthHelper.isGuestLoggedIn() && Get.find<SplashController>().configModel!.guestCheckoutStatus!;
    bool isLoggedIn = AuthHelper.isLoggedIn();
    bool isGuestLogIn = AuthHelper.isGuestLoggedIn();

    return Scaffold(
      appBar: CustomAppBarWidget(title: 'checkout'.tr),
      endDrawer: const MenuDrawerWidget(), endDrawerEnableOpenDragGesture: false,
      body: guestCheckoutPermission || AuthHelper.isLoggedIn() ? GetBuilder<CheckoutController>(builder: (checkoutController) {
        return (checkoutController.distance != null && checkoutController.restaurant != null) ? GetBuilder<LocationController>(builder: (locationController) {

          bool todayClosed = false;
          bool tomorrowClosed = false;

          if(checkoutController.restaurant != null) {
            todayClosed = checkoutController.isRestaurantClosed(DateTime.now(), checkoutController.restaurant!.active!, checkoutController.restaurant!.schedules);
            tomorrowClosed = checkoutController.isRestaurantClosed(DateTime.now().add(const Duration(days: 1)), checkoutController.restaurant!.active!, checkoutController.restaurant!.schedules);
            taxPercent = checkoutController.restaurant!.tax;
          }
          return GetBuilder<CouponController>(builder: (couponController) {
            bool showTips = checkoutController.orderType != 'take_away' && Get.find<SplashController>().configModel!.dmTipsStatus == 1 && !checkoutController.subscriptionOrder;
            double deliveryCharge = -1;
            double charge = -1;
            double? maxCodOrderAmount;
            if(checkoutController.restaurant != null && checkoutController.distance != null && checkoutController.distance != -1 ) {

              deliveryCharge = _getDeliveryCharge(restaurant: checkoutController.restaurant, checkoutController: checkoutController, returnDeliveryCharge: true)!;
              charge = _getDeliveryCharge(restaurant: checkoutController.restaurant, checkoutController: checkoutController, returnDeliveryCharge: false)!;
              maxCodOrderAmount = _getDeliveryCharge(restaurant: checkoutController.restaurant, checkoutController: checkoutController, returnMaxCodOrderAmount: true);

              if(checkoutController.orderType != 'take_away' && checkoutController.orderType != 'dine_in') {
                _deliveryChargeForView = (checkoutController.orderType == 'delivery' ? checkoutController.restaurant!.freeDelivery! : true) ? 'free'.tr
                    : deliveryCharge != -1 ? PriceConverter.convertPrice(deliveryCharge) : 'calculating'.tr;
              }
            }

            double price = _cartList != null ? _calculatePrice(_cartList) : 0;
            double addOnsPrice = _cartList != null ? _calculateAddonsPrice(_cartList) : 0;

            double? discount = _calculateDiscountPrice(cartList: _cartList, restaurant: checkoutController.restaurant, price: price, addOns: addOnsPrice);

            double? couponDiscount = PriceConverter.toFixed(couponController.discount!);

            double subTotal = _calculateSubTotal(price, addOnsPrice);

            double referralDiscount = _calculateReferralDiscount(subTotal, discount, couponDiscount, checkoutController.subscriptionOrder);

            double orderAmount = _calculateOrderAmount(price, addOnsPrice, discount, couponDiscount, referralDiscount);

            Future.delayed(const Duration(milliseconds: 100), () {
              if(checkoutController.isFirstTime || (couponController.discount! > 0 && !checkoutController.isFirstTime && !_calledOrderTax)){
                if(couponController.discount! > 0){
                  _calledOrderTax = true;
                }
                List<OnlineCart> carts = [];
                for (int index = 0; index < _cartList!.length; index++) {
                  CartModel cart = _cartList![index];
                  List<int?> addOnIdList = [];
                  List<int?> addOnQtyList = [];
                  List<OrderVariation> variations = [];
                  List<int?> optionIds = [];
                  for (var addOn in cart.addOnIds!) {
                    addOnIdList.add(addOn.id);
                    addOnQtyList.add(addOn.quantity);
                  }
                  if(cart.product!.variations != null){
                    for(int i=0; i<cart.product!.variations!.length; i++) {
                      if(cart.variations![i].contains(true)) {
                        variations.add(OrderVariation(name: cart.product!.variations![i].name, values: OrderVariationValue(label: [])));
                        for(int j=0; j<cart.product!.variations![i].variationValues!.length; j++) {
                          if(cart.variations![i][j]!) {
                            variations[variations.length-1].values!.label!.add(cart.product!.variations![i].variationValues![j].level);
                            if(cart.product!.variations![i].variationValues![j].optionId != null) {
                              optionIds.add(cart.product!.variations![i].variationValues![j].optionId);
                            }
                          }
                        }
                      }
                    }
                  }
                  carts.add(OnlineCart(
                    cart.id, cart.product!.id, cart.isCampaign! ? cart.product!.id : null,
                    cart.discountedPrice.toString(), variations,
                    cart.quantity, addOnIdList, cart.addOns, addOnQtyList, 'Food', variationOptionIds: optionIds, itemType: ! widget.fromCart ? "AppModelsItemCampaign" : null,
                  ));
                }

                PlaceOrderBodyModel placeOrderBody = PlaceOrderBodyModel(
                  cart: carts, couponDiscountAmount: Get.find<CouponController>().discount, distance: checkoutController.distance,
                  couponDiscountTitle: Get.find<CouponController>().discount! > 0 ? Get.find<CouponController>().coupon!.title : null,
                  orderAmount: subTotal, orderNote: checkoutController.noteController.text, orderType: checkoutController.orderType,
                  paymentMethod: checkoutController.paymentMethodIndex == 0 ? 'cash_on_delivery'
                      : checkoutController.paymentMethodIndex == 1 ? 'wallet'
                      : checkoutController.paymentMethodIndex == 2 ? 'digital_payment' : 'offline_payment',
                  couponCode: (Get.find<CouponController>().discount! > 0 || (Get.find<CouponController>().coupon != null
                      && Get.find<CouponController>().freeDelivery)) ? Get.find<CouponController>().coupon!.code : null,
                  restaurantId: _cartList?[0].product?.restaurantId,
                  discountAmount: discount, cutlery: Get.find<CartController>().addCutlery ? 1 : 0,
                  dmTips: (checkoutController.orderType == 'take_away' || checkoutController.subscriptionOrder || checkoutController.selectedTips == 0) ? '' : checkoutController.tips.toString(),
                  subscriptionOrder: checkoutController.subscriptionOrder ? '1' : '0',
                  subscriptionStartAt: checkoutController.subscriptionOrder ? DateConverter.dateToDateAndTime(checkoutController.subscriptionRange!.start) : '',
                  subscriptionEndAt: checkoutController.subscriptionOrder ? DateConverter.dateToDateAndTime(checkoutController.subscriptionRange!.end) : '',
                  unavailableItemNote: Get.find<CartController>().notAvailableIndex != -1 ? Get.find<CartController>().notAvailableList[Get.find<CartController>().notAvailableIndex] : '',
                  deliveryInstruction: checkoutController.selectedInstruction != -1 ? AppConstants.deliveryInstructionList[checkoutController.selectedInstruction] : '',
                  partialPayment: checkoutController.isPartialPay ? 1 : 0,
                  guestId: isGuestLogIn ? int.parse(Get.find<AuthController>().getGuestId()) : 0,
                  extraPackagingAmount: Get.find<CartController>().needExtraPackage ? checkoutController.restaurant!.extraPackagingAmount : 0,
                  isBuyNow: widget.fromCart ? 0 : 1,
                );

                checkoutController.getOrderTax(placeOrderBody);
              }
            });



            bool restaurantSubscriptionActive = false;
            int subscriptionQty = checkoutController.subscriptionOrder ? 0 : 1;
            double additionalCharge =  Get.find<SplashController>().configModel!.additionalChargeStatus! ? Get.find<SplashController>().configModel!.additionCharge! : 0;

            if(checkoutController.restaurant != null) {

              ConfigModel? configModel = Get.find<SplashController>().configModel;

              restaurantSubscriptionActive =  checkoutController.restaurant!.orderSubscriptionActive! && widget.fromCart;

              subscriptionQty = _getSubscriptionQty(checkoutController: checkoutController, restaurantSubscriptionActive: restaurantSubscriptionActive);

              if (checkoutController.orderType == 'take_away' || checkoutController.orderType == 'dine_in' || checkoutController.restaurant!.freeDelivery!
                  || (configModel?.adminFreeDelivery?.status == true && (configModel?.adminFreeDelivery?.type != null && configModel?.adminFreeDelivery?.type == 'free_delivery_to_all_store'))
                  || (configModel?.adminFreeDelivery?.status == true && (configModel?.adminFreeDelivery?.type != null &&  configModel?.adminFreeDelivery?.type == 'free_delivery_by_specific_criteria') && (configModel!.adminFreeDelivery!.freeDeliveryOver! > 0 && orderAmount >= configModel.adminFreeDelivery!.freeDeliveryOver!))
                  || (configModel?.adminFreeDelivery?.status == true && (configModel?.adminFreeDelivery?.type != null &&  configModel?.adminFreeDelivery?.type == 'free_delivery_by_specific_criteria') && (configModel!.adminFreeDelivery!.freeDeliveryDistance! > 0 && configModel.adminFreeDelivery!.freeDeliveryDistance! >= checkoutController.distance!))
                  || couponController.freeDelivery) {
                deliveryCharge = 0;
              }
            }

            deliveryCharge = PriceConverter.toFixed(deliveryCharge);

            double extraPackagingCharge = _calculateExtraPackagingCharge(checkoutController);
            print('Extra Packaging Charge: $extraPackagingCharge');

            double total = _calculateTotal(subTotal, deliveryCharge, discount, couponDiscount, (checkoutController.taxIncluded == 1), checkoutController.orderTax!, showTips, checkoutController.tips, additionalCharge, extraPackagingCharge);

            total = total - referralDiscount;

            checkoutController.setTotalAmount(total - (checkoutController.isPartialPay ? Get.find<ProfileController>().userInfoModel?.walletBalance ?? 0 : 0));

            if(_payableAmount != checkoutController.viewTotalPrice && checkoutController.distance != null && isLoggedIn && Get.find<HomeController>().cashBackOfferList != null && Get.find<HomeController>().cashBackOfferList!.isNotEmpty) {
              _payableAmount = checkoutController.viewTotalPrice;
              showCashBackSnackBar();
            }

            if(isLoggedIn && firstTime && (price > 0.0)){
              couponController.getCouponList(orderRestaurantId: _cartList![0].product!.restaurantId, orderAmount: price);
              firstTime = false;
            }

            return Column(
              children: [
                WebScreenTitleWidget(title: 'checkout'.tr),

                Expanded(child: SingleChildScrollView(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  child: FooterViewWidget(
                    child: Center(
                      child: SizedBox(
                        width: Dimensions.webMaxWidth,
                        child: ResponsiveHelper.isDesktop(context) ? Padding(
                          padding: const EdgeInsets.only(top: Dimensions.paddingSizeLarge),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [

                            Expanded(flex: 6, child: TopSectionWidget(
                              charge: charge, deliveryCharge: deliveryCharge,
                              locationController: locationController, tomorrowClosed: tomorrowClosed, todayClosed: todayClosed,
                              price: price, discount: discount, addOns: addOnsPrice, restaurantSubscriptionActive: restaurantSubscriptionActive,
                              showTips: showTips, isCashOnDeliveryActive: _isCashOnDeliveryActive!, isDigitalPaymentActive: _isDigitalPaymentActive!,
                              isWalletActive: _isWalletActive, fromCart: widget.fromCart, total: total, tooltipController3: tooltipController3, tooltipController2: tooltipController2,
                              guestNameTextEditingController: guestContactPersonNameController, guestNumberTextEditingController: guestContactPersonNumberController,
                              guestEmailController: guestEmailController, guestEmailNode: guestEmailNode,
                              guestNumberNode: guestNumberNode, isOfflinePaymentActive: _isOfflinePaymentActive, loginTooltipController: loginTooltipController,
                              callBack: () => initCall(), deliveryChargeForView: _deliveryChargeForView, deliveryFeeTooltipController: deliveryFeeTooltipController,
                              badWeatherCharge: badWeatherChargeForToolTip, extraChargeForToolTip: extraChargeForToolTip,
                              deliveryOptionScrollController: deliveryOptionScrollController,
                            )),
                            const SizedBox(width: Dimensions.paddingSizeLarge),

                            Expanded(
                              flex: 4,
                              child: BottomSectionWidget(
                                isCashOnDeliveryActive: _isCashOnDeliveryActive!, isDigitalPaymentActive: _isDigitalPaymentActive!, isWalletActive: _isWalletActive,
                                total: total, subTotal: subTotal, discount: discount, couponController: couponController,
                                taxIncluded: (checkoutController.taxIncluded == 1), tax: checkoutController.orderTax!, deliveryCharge: deliveryCharge, checkoutController: checkoutController, locationController: locationController,
                                todayClosed: todayClosed, tomorrowClosed: tomorrowClosed, orderAmount: orderAmount, maxCodOrderAmount: maxCodOrderAmount,
                                subscriptionQty: subscriptionQty, taxPercent: taxPercent!, fromCart: widget.fromCart, cartList: _cartList,
                                price: price, addOns: addOnsPrice, charge: charge,
                                guestNumberTextEditingController: guestContactPersonNumberController, guestNumberNode: guestNumberNode,
                                guestEmailController: guestEmailController, guestEmailNode: guestEmailNode,
                                guestNameTextEditingController: guestContactPersonNameController, isOfflinePaymentActive: _isOfflinePaymentActive,
                                expansionTileController: expansionTileController, serviceFeeTooltipController: serviceFeeTooltipController, referralDiscount: referralDiscount,
                                extraPackagingAmount: extraPackagingCharge, /*extraDiscount: extraDiscount*/
                              ),
                            )
                          ]),
                        ) : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                          TopSectionWidget(
                            charge: charge, deliveryCharge: deliveryCharge,
                            locationController: locationController, tomorrowClosed: tomorrowClosed, todayClosed: todayClosed,
                            price: price, discount: discount, addOns: addOnsPrice, restaurantSubscriptionActive: restaurantSubscriptionActive,
                            showTips: showTips, isCashOnDeliveryActive: _isCashOnDeliveryActive!, isDigitalPaymentActive: _isDigitalPaymentActive!,
                            isWalletActive: _isWalletActive, fromCart: widget.fromCart, total: total, tooltipController3: tooltipController3, tooltipController2: tooltipController2,
                            guestNameTextEditingController: guestContactPersonNameController, guestNumberTextEditingController: guestContactPersonNumberController,
                            guestEmailController: guestEmailController, guestEmailNode: guestEmailNode,
                            guestNumberNode: guestNumberNode, isOfflinePaymentActive: _isOfflinePaymentActive, loginTooltipController: loginTooltipController,
                            callBack: () => initCall(), deliveryChargeForView: _deliveryChargeForView, deliveryFeeTooltipController: deliveryFeeTooltipController,
                            badWeatherCharge: badWeatherChargeForToolTip, extraChargeForToolTip: extraChargeForToolTip,
                            deliveryOptionScrollController: deliveryOptionScrollController,
                          ),

                          BottomSectionWidget(
                            isCashOnDeliveryActive: _isCashOnDeliveryActive!, isDigitalPaymentActive: _isDigitalPaymentActive!, isWalletActive: _isWalletActive,
                            total: total, subTotal: subTotal, discount: discount, couponController: couponController,
                            taxIncluded: (checkoutController.taxIncluded == 1), tax: checkoutController.orderTax!, deliveryCharge: deliveryCharge, checkoutController: checkoutController, locationController: locationController,
                            todayClosed: todayClosed, tomorrowClosed: tomorrowClosed, orderAmount: orderAmount, maxCodOrderAmount: maxCodOrderAmount,
                            subscriptionQty: subscriptionQty, taxPercent: taxPercent!, fromCart: widget.fromCart, cartList: _cartList!,
                            price: price, addOns: addOnsPrice, charge: charge,
                            guestNumberTextEditingController: guestContactPersonNumberController, guestNumberNode: guestNumberNode,
                            guestEmailController: guestEmailController, guestEmailNode: guestEmailNode,
                            guestNameTextEditingController: guestContactPersonNameController, isOfflinePaymentActive: _isOfflinePaymentActive,
                            expansionTileController: expansionTileController, serviceFeeTooltipController: serviceFeeTooltipController, referralDiscount: referralDiscount,
                            extraPackagingAmount: extraPackagingCharge, /*extraDiscount: extraDiscount*/
                          ),
                        ]),
                      ),
                    ),
                  ),
                )),

                ResponsiveHelper.isDesktop(context) ? const SizedBox() : Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    boxShadow: [BoxShadow(color: Theme.of(context).primaryColor.withValues(alpha: 0.1), blurRadius: 10)],
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeExtraSmall),
                        child: Row(children: [
                          Text(
                            'total_amount'.tr,
                            style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).primaryColor),
                          ),


                          (checkoutController.taxIncluded == 1) ? Text(' ${'vat_tax_inc'.tr}', style: robotoMedium.copyWith(
                            fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).primaryColor,
                          )) : const SizedBox(),

                          const Expanded(child: SizedBox()),

                          PriceConverter.convertAnimationPrice(
                            total * (checkoutController.subscriptionOrder ? (subscriptionQty == 0 ? 1 : subscriptionQty) : 1),
                            textStyle: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).primaryColor),
                          ),
                        ]),
                      ),

                      OrderPlaceButton(
                        checkoutController: checkoutController, locationController: locationController,
                        todayClosed: todayClosed, tomorrowClosed: tomorrowClosed, orderAmount: orderAmount, deliveryCharge: deliveryCharge,
                        discount: discount, total: total, maxCodOrderAmount: maxCodOrderAmount, subscriptionQty: subscriptionQty,
                        cartList: _cartList!, isCashOnDeliveryActive: _isCashOnDeliveryActive!, isDigitalPaymentActive: _isDigitalPaymentActive!,
                        isWalletActive: _isWalletActive, fromCart: widget.fromCart, guestNumberTextEditingController: guestContactPersonNumberController,
                        guestNumberNode: guestNumberNode, guestNameTextEditingController: guestContactPersonNameController,
                        guestEmailController: guestEmailController, guestEmailNode: guestEmailNode,
                        isOfflinePaymentActive: _isOfflinePaymentActive, subTotal: subTotal, couponController: couponController,
                        taxPercent: taxPercent!, extraPackagingAmount: extraPackagingCharge,
                        taxIncluded: (checkoutController.taxIncluded == 1), tax: checkoutController.orderTax!,
                      ),
                    ],
                  ),
                ),

              ],
            );
          });
        }) : const CheckoutScreenShimmerView();
      }) : NotLoggedInScreen(callBack: (value) {
        initCall();
        setState(() {});
      }),
    );
  }

  double? _getDeliveryCharge({required Restaurant? restaurant, required CheckoutController checkoutController, bool returnDeliveryCharge = true, bool returnMaxCodOrderAmount = false}) {

    ConfigModel? configModel = Get.find<SplashController>().configModel;

    ZoneData zoneData = AddressHelper.getAddressFromSharedPref()!.zoneData!.firstWhere((data) => data.id == restaurant!.zoneId);
    double perKmCharge = restaurant!.selfDeliverySystem == 1 ? restaurant.perKmShippingCharge!
        : zoneData.perKmShippingCharge ?? 0;

    double minimumCharge = restaurant.selfDeliverySystem == 1 ? restaurant.minimumShippingCharge!
        :  zoneData.minimumShippingCharge ?? 0;

    double? maximumCharge = restaurant.selfDeliverySystem == 1 ? restaurant.maximumShippingCharge
        : zoneData.maximumShippingCharge;

    double deliveryCharge = checkoutController.distance! * perKmCharge;
    double charge = checkoutController.distance! * perKmCharge;

    if(deliveryCharge < minimumCharge) {
      deliveryCharge = minimumCharge;
      charge = minimumCharge;
    }

    if(restaurant.selfDeliverySystem == 0 && checkoutController.extraCharge != null){
      extraChargeForToolTip = checkoutController.extraCharge!;
      deliveryCharge = deliveryCharge + checkoutController.extraCharge!;
      charge = charge + checkoutController.extraCharge!;
    }

    if(maximumCharge != null && deliveryCharge > maximumCharge){
      deliveryCharge = maximumCharge;
      charge = maximumCharge;
    }

    if(restaurant.selfDeliverySystem == 0 && zoneData.increasedDeliveryFeeStatus == 1){
      badWeatherChargeForToolTip = (deliveryCharge * (zoneData.increasedDeliveryFee!/100));
      deliveryCharge = deliveryCharge + (deliveryCharge * (zoneData.increasedDeliveryFee!/100));
      charge = charge + charge * (zoneData.increasedDeliveryFee!/100);
    }

    if(restaurant.selfDeliverySystem == 0 && (configModel?.adminFreeDelivery?.status == true && (configModel?.adminFreeDelivery?.type != null &&  configModel?.adminFreeDelivery?.type == 'free_delivery_by_specific_criteria') && (configModel!.adminFreeDelivery!.freeDeliveryDistance! > 0 && configModel.adminFreeDelivery!.freeDeliveryDistance! >= checkoutController.distance!))){
      deliveryCharge = 0;
      charge = 0;
    }

/*    if(restaurant.selfDeliverySystem == 0 && Get.find<SplashController>().configModel!.freeDeliveryDistance != null && Get.find<SplashController>().configModel!.freeDeliveryDistance! >= checkoutController.distance!){
      deliveryCharge = 0;
      charge = 0;
    }*/

    if(restaurant.selfDeliverySystem == 1 && restaurant.freeDeliveryDistanceStatus! && restaurant.freeDeliveryDistanceValue! >= checkoutController.distance!){
      deliveryCharge = 0;
      charge = 0;
    }

    double? maxCodOrderAmount;
    if(zoneData.maxCodOrderAmount != null) {
      maxCodOrderAmount = zoneData.maxCodOrderAmount;
    }

    if(returnMaxCodOrderAmount) {
      return maxCodOrderAmount;
    } else {
      if(returnDeliveryCharge) {
        return deliveryCharge;
      }else {
        return charge;
      }
    }

  }

  double _calculatePrice(List<CartModel>? cartList) {
    double price = 0;
    double variationPrice = 0;
    if(cartList != null) {
      for (var cartModel in cartList) {

        price = price + (cartModel.product!.price! * cartModel.quantity!);

        for(int index = 0; index< cartModel.product!.variations!.length; index++) {
          for(int i=0; i<cartModel.product!.variations![index].variationValues!.length; i++) {
            if(cartModel.variations![index][i]!) {
              variationPrice += (cartModel.product!.variations![index].variationValues![i].optionPrice! * cartModel.quantity!);
            }
          }
        }
      }
    }
    return PriceConverter.toFixed(price + variationPrice);
  }

  double _calculateAddonsPrice(List<CartModel>? cartList) {
    double addonPrice = 0;
    if(cartList != null) {
      for (var cartModel in cartList) {
        List<AddOns> addOnList = [];
        for (var addOnId in cartModel.addOnIds!) {
          for (AddOns addOns in cartModel.product!.addOns!) {
            if (addOns.id == addOnId.id) {
              addOnList.add(addOns);
              break;
            }
          }
        }
        for (int index = 0; index < addOnList.length; index++) {
          addonPrice = addonPrice + (addOnList[index].price! * cartModel.addOnIds![index].quantity!);
        }
      }
    }
    return PriceConverter.toFixed(addonPrice);
  }

  double _calculateDiscountPrice({List<CartModel>? cartList, Restaurant? restaurant, required double price, required double addOns}) {
    double? discount = 0;
    if(restaurant != null && cartList != null) {
      for (var cartModel in cartList) {
        double? dis = (restaurant.discount != null
          && DateConverter.isAvailable(restaurant.discount!.startTime, restaurant.discount!.endTime))
          ? restaurant.discount!.discount : cartModel.product!.discount;

        String? disType = (restaurant.discount != null
          && DateConverter.isAvailable(restaurant.discount!.startTime, restaurant.discount!.endTime))
          ? 'percent' : cartModel.product!.discountType;

        double d = ((cartModel.product!.price! - PriceConverter.convertWithDiscount(cartModel.product!.price!, dis, disType)!) * cartModel.quantity!);
        discount = discount! + d;
        discount = discount + _calculateVariationPrice(restaurant: restaurant, cartModel: cartModel);
      }

      if (restaurant.discount != null) {
        if (restaurant.discount!.maxDiscount != 0 && restaurant.discount!.maxDiscount! < discount!) {
          discount = restaurant.discount!.maxDiscount;
        }
        if (restaurant.discount!.minPurchase != 0 && restaurant.discount!.minPurchase! > (price + addOns)) {
          discount = 0;
        }
      }

    }
    return PriceConverter.toFixed(discount!);
  }

  double _calculateVariationPrice({required Restaurant? restaurant, required CartModel? cartModel}) {
    double variationPrice = 0;
    double variationDiscount = 0;
    if(restaurant != null && cartModel != null) {

      double? discount = (restaurant.discount != null
        && DateConverter.isAvailable(restaurant.discount!.startTime, restaurant.discount!.endTime))
         ? restaurant.discount!.discount : cartModel.product!.discount;

      String? discountType = (restaurant.discount != null
        && DateConverter.isAvailable(restaurant.discount!.startTime, restaurant.discount!.endTime))
        ? 'percent' : cartModel.product!.discountType;

      for(int index = 0; index< cartModel.product!.variations!.length; index++) {
        for(int i=0; i<cartModel.product!.variations![index].variationValues!.length; i++) {
          if(cartModel.variations![index][i]!) {
            variationPrice += (PriceConverter.convertWithDiscount(cartModel.product!.variations![index].variationValues![i].optionPrice!, discount, discountType, isVariation: true)! * cartModel.quantity!);
            variationDiscount += (cartModel.product!.variations![index].variationValues![i].optionPrice! * cartModel.quantity!);
          }
        }
      }
    }

    return variationDiscount - variationPrice;
  }

  double _calculateSubTotal(double price, double addOnsPrice) {
    double subTotal = price + addOnsPrice;
    return PriceConverter.toFixed(subTotal);
  }

  double _calculateOrderAmount(double price, double addOnsPrice, double discount, double couponDiscount, double referralDiscount) {
    double orderAmount = (price - discount) + addOnsPrice - couponDiscount - referralDiscount;
    return PriceConverter.toFixed(orderAmount);
  }

  int _getSubscriptionQty({required CheckoutController checkoutController, required bool restaurantSubscriptionActive}) {
    int subscriptionQty = checkoutController.subscriptionOrder ? 0 : 1;
    if(restaurantSubscriptionActive){
      if(checkoutController.subscriptionOrder && checkoutController.subscriptionRange != null) {
        if(checkoutController.subscriptionType == 'weekly') {
          List<int> weekDays = [];
          for(int index=0; index<checkoutController.selectedDays.length; index++) {
            if(checkoutController.selectedDays[index] != null) {
              weekDays.add(index + 1);
            }
          }
          subscriptionQty = DateConverter.getWeekDaysCount(checkoutController.subscriptionRange!, weekDays);
        }else if(checkoutController.subscriptionType == 'monthly') {
          List<int> days = [];
          for(int index=0; index<checkoutController.selectedDays.length; index++) {
            if(checkoutController.selectedDays[index] != null) {
              days.add(index + 1);
            }
          }
          subscriptionQty = DateConverter.getMonthDaysCount(checkoutController.subscriptionRange!, days);
        }else {
          subscriptionQty = checkoutController.subscriptionRange!.duration.inDays + 1;
        }
      }
    }
    return subscriptionQty;
  }

  double _calculateTotal(
      double subTotal, double deliveryCharge, double discount, double couponDiscount,
      bool taxIncluded, double tax, bool showTips, double tips, double additionalCharge, double extraPackagingCharge) {

    double total = subTotal + deliveryCharge - discount - couponDiscount + (taxIncluded ? 0 : tax)
        + (showTips ? tips : 0) + additionalCharge + extraPackagingCharge;

    return PriceConverter.toFixed(total);
  }

  double _calculateExtraPackagingCharge(CheckoutController checkoutController) {
    if(((checkoutController.restaurant != null && checkoutController.restaurant!.isExtraPackagingActive! && !checkoutController.restaurant!.extraPackagingStatusIsMandatory! && Get.find<CartController>().needExtraPackage)
        || (checkoutController.restaurant != null && checkoutController.restaurant!.isExtraPackagingActive! && checkoutController.restaurant!.extraPackagingStatusIsMandatory!)) && checkoutController.orderType != 'dine_in') {
      return checkoutController.restaurant?.extraPackagingAmount ?? 0;
    }
    return 0;
  }

  double _calculateReferralDiscount(double subTotal, double discount, double couponDiscount, bool isSubscriptionOrder) {
    double referralDiscount = 0;
    if(Get.find<ProfileController>().userInfoModel != null &&  Get.find<ProfileController>().userInfoModel!.isValidForDiscount! && !isSubscriptionOrder) {
      if (Get.find<ProfileController>().userInfoModel!.discountAmountType! == "percentage") {
        referralDiscount = (Get.find<ProfileController>().userInfoModel!.discountAmount! / 100) * (subTotal - discount - couponDiscount);
      } else {
        referralDiscount = Get.find<ProfileController>().userInfoModel!.discountAmount!;
      }
    }
    return PriceConverter.toFixed(referralDiscount);
  }

  Future<void> showCashBackSnackBar() async {
    await Get.find<HomeController>().getCashBackData(_payableAmount!);
    double? cashBackAmount = Get.find<HomeController>().cashBackData?.cashbackAmount ?? 0;
    String? cashBackType = Get.find<HomeController>().cashBackData?.cashbackType ?? '';
    String text = '${'you_will_get'.tr} ${cashBackType == 'amount' ? PriceConverter.convertPrice(cashBackAmount) : '${cashBackAmount.toStringAsFixed(0)}%'} ${'cash_back_after_completing_order'.tr}';
    if(cashBackAmount > 0) {
      showCustomSnackBar(text, isError: false);
    }
  }

}