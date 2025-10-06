import 'package:geolocator/geolocator.dart';
import 'package:godelivery_user/common/widgets/custom_asset_image_widget.dart';
import 'package:godelivery_user/common/widgets/custom_loader_widget.dart';
import 'package:godelivery_user/common/widgets/custom_snackbar_widget.dart';
import 'package:godelivery_user/features/address/controllers/address_controller.dart';
import 'package:godelivery_user/features/address/domain/models/address_model.dart';
import 'package:godelivery_user/features/address/widgets/address_card_widget.dart';
import 'package:godelivery_user/features/auth/controllers/auth_controller.dart';
import 'package:godelivery_user/features/location/controllers/location_controller.dart';
import 'package:godelivery_user/features/location/domain/models/zone_response_model.dart';
import 'package:godelivery_user/features/location/widgets/bottom_button.dart';
import 'package:godelivery_user/features/location/widgets/pick_map_dialog.dart';
import 'package:godelivery_user/features/location/widgets/zone_list_widget.dart';
import 'package:godelivery_user/features/profile/controllers/profile_controller.dart';
import 'package:godelivery_user/helper/address_helper.dart';
import 'package:godelivery_user/helper/responsive_helper.dart';
import 'package:godelivery_user/helper/route_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/images.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:godelivery_user/common/widgets/custom_app_bar_widget.dart';
import 'package:godelivery_user/common/widgets/footer_view_widget.dart';
import 'package:godelivery_user/common/widgets/menu_drawer_widget.dart';
import 'package:godelivery_user/common/widgets/no_data_screen_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

class AccessLocationScreen extends StatefulWidget {
  final bool fromSignUp;
  final bool fromHome;
  final String? route;
  final bool hideAppBar;
  const AccessLocationScreen({super.key, required this.fromSignUp, required this.fromHome, required this.route, this.hideAppBar = false});

  @override
  State<AccessLocationScreen> createState() => _AccessLocationScreenState();
}

class _AccessLocationScreenState extends State<AccessLocationScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  DateTime? _lastTapTime;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15).chain(CurveTween(curve: Curves.easeOut)), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 0.98).chain(CurveTween(curve: Curves.easeIn)), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.98, end: 1.03).chain(CurveTween(curve: Curves.easeOut)), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.03, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 25),
    ]).animate(_animationController);

    _rotationAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.02), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.02, end: -0.02), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -0.02, end: 0.015), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.015, end: -0.01), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -0.01, end: 0.0), weight: 20),
    ]).animate(_animationController);

    // Load zone list after build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<LocationController>().getZoneList();
    });

    if(ResponsiveHelper.isDesktop(Get.context!)) {
      Future.delayed(const Duration(milliseconds: 600), () {
        _checkPermission();
      });
    }
  }

  void _checkPermission() async {
    await Geolocator.requestPermission();
    LocationPermission permission = await Geolocator.checkPermission();
    if(permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if(permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      showGeneralDialog(context: Get.context!, pageBuilder: (_,__,___) {
        return SizedBox(
          height: 300, width: 300,
          child: PickMapDialog(
            fromSignUp: widget.fromSignUp, canRoute: widget.route != null, fromAddAddress: false, route: widget.route
              ?? (widget.fromSignUp ? RouteHelper.signUp : RouteHelper.accessLocation),
            // canTakeCurrentLocation: false /*(!AuthHelper.isLoggedIn() || route == '/?from-splash=false')*/,
          ),
        );
      });
    } else if(!widget.fromHome){
      _getCurrentLocationAndRoute();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _playAnimation() {
    final now = DateTime.now();
    if (_lastTapTime != null && now.difference(_lastTapTime!).inSeconds < 3) {
      return; // Cooldown active
    }
    _lastTapTime = now;
    _animationController.forward(from: 0.0);
  }

  Future<void> _getCurrentLocationAndRoute() async {
    Get.dialog(const CustomLoaderWidget(), barrierDismissible: false);
    AddressModel address = await Get.find<LocationController>().getCurrentLocation(true);
    ZoneResponseModel response = await Get.find<LocationController>().getZone(address.latitude, address.longitude, false);
    if(response.isSuccess) {
      if(!Get.find<AuthController>().isGuestLoggedIn() || !Get.find<AuthController>().isLoggedIn()) {
        Get.find<AuthController>().guestLogin().then((response) {
          if(response.isSuccess) {
            Get.find<ProfileController>().setForceFullyUserEmpty();
            Get.find<LocationController>().saveAddressAndNavigate(address, false, null, false, ResponsiveHelper.isDesktop(Get.context));
          }
        });
      } else {
        Get.find<LocationController>().saveAddressAndNavigate(address, false, null, false, ResponsiveHelper.isDesktop(Get.context));
      }
    } else {
      showCustomSnackBar('service_not_available_in_current_location'.tr);
    }
  }

  @override
  Widget build(BuildContext context) {
    if(!widget.fromHome && AddressHelper.getAddressFromSharedPref() != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        Get.dialog(const CustomLoaderWidget(), barrierDismissible: false);
        Get.find<LocationController>().autoNavigate(
          AddressHelper.getAddressFromSharedPref()!, widget.fromSignUp, widget.route, widget.route != null, ResponsiveHelper.isDesktop(Get.context),
        );
      });
    }
    bool isLoggedIn = Get.find<AuthController>().isLoggedIn();
    if(isLoggedIn) {
      Get.find<AddressController>().getAddressList();
    }

    return Scaffold(
      appBar: widget.hideAppBar ? null : CustomAppBarWidget(title: 'set_location'.tr, isBackButtonExist: widget.fromHome),
      endDrawer: widget.hideAppBar ? null : const MenuDrawerWidget(),
      endDrawerEnableOpenDragGesture: false,
      body: SafeArea(child: GetBuilder<AddressController>(builder: (addressController) {
        return isLoggedIn ? SingleChildScrollView(
          child: FooterViewWidget(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [

              addressController.addressList != null ? addressController.addressList!.isNotEmpty ? ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: addressController.addressList!.length,
                padding: ResponsiveHelper.isDesktop(context) ? const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraLarge, vertical: Dimensions.paddingSizeSmall) : const EdgeInsets.all(Dimensions.paddingSizeDefault),
                itemBuilder: (context, index) {
                  return Center(child: SizedBox(width: 700, child: AddressCardWidget(
                    address: addressController.addressList![index],
                    fromAddress: false,
                    onTap: () {
                      Get.dialog(const CustomLoaderWidget(), barrierDismissible: false);
                      AddressModel address = addressController.addressList![index];
                      Get.find<LocationController>().saveAddressAndNavigate(address, widget.fromSignUp, widget.route, widget.route != null, ResponsiveHelper.isDesktop(Get.context));
                    },
                  )));
                },
              ) : NoDataScreen(title: 'no_saved_address_found'.tr, isEmptyAddress: true) : const Center(child: CircularProgressIndicator()),

              const SizedBox(height: Dimensions.paddingSizeLarge),

              // Zone List Section
              Padding(
                padding: ResponsiveHelper.isDesktop(context)
                  ? const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraLarge)
                  : const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'select_delivery_zone'.tr,
                      style: robotoBold.copyWith(
                        fontSize: Dimensions.fontSizeLarge,
                        color: Theme.of(context).textTheme.bodyLarge!.color,
                      ),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                    const Center(
                      child: SizedBox(
                        width: 700,
                        child: ZoneListWidget(),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: (addressController.addressList != null && addressController.addressList!.length < 4) ? 100 : Dimensions.paddingSizeLarge),

              ResponsiveHelper.isDesktop(context) ? BottomButton(addressController: addressController, fromSignUp: widget.fromSignUp, route: widget.route) : const SizedBox(),

            ]),
          ),
        ) : Center(child: SingleChildScrollView(
          child: FooterViewWidget(
            child: Center(child: Padding(
              padding: context.width > 700 ? const EdgeInsets.all(50) : EdgeInsets.zero,
              child: SizedBox(width: 700, child: Column(children: [
                GestureDetector(
                  onTap: _playAnimation,
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Transform.rotate(
                          angle: _rotationAnimation.value,
                          child: Lottie.asset('assets/animations/location_lottie.json', height: 220),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeLarge),
                Text(
                  'find_restaurants_and_foods'.tr.toUpperCase(), textAlign: TextAlign.center,
                  style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraLarge),
                ),
                Padding(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                  child: Text(
                    'by_allowing_location_access'.tr, textAlign: TextAlign.center,
                    style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeLarge),
                BottomButton(addressController: addressController, fromSignUp: widget.fromSignUp, route: widget.route),

                const SizedBox(height: Dimensions.paddingSizeExtraLarge),

                // Zone List for non-logged-in users
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'select_delivery_zone'.tr,
                        style: robotoBold.copyWith(
                          fontSize: Dimensions.fontSizeLarge,
                          color: Theme.of(context).textTheme.bodyLarge!.color,
                        ),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeSmall),
                      const ZoneListWidget(),
                    ],
                  ),
                ),
              ])),
            )),
          ),
        ));
      })),
      bottomNavigationBar: !ResponsiveHelper.isDesktop(context) && isLoggedIn ? GetBuilder<AddressController>(
        builder: (addressController) {
          return SizedBox(height: context.height * 0.24, child: BottomButton(addressController: addressController, fromSignUp: widget.fromSignUp, route: widget.route));
        }
      ) : const SizedBox(),
    );
  }
}

