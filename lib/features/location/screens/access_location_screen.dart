import 'package:geolocator/geolocator.dart';
import 'package:godelivery_user/common/widgets/shared/images/custom_asset_image_widget.dart';
import 'package:godelivery_user/common/widgets/shared/feedback/custom_loader_widget.dart';
import 'package:godelivery_user/common/widgets/shared/feedback/custom_snackbar_widget.dart';
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
import 'package:godelivery_user/helper/business_logic/address_helper.dart';
import 'package:godelivery_user/helper/ui/responsive_helper.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/images.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:godelivery_user/common/widgets/adaptive/navigation/custom_app_bar_widget.dart';
import 'package:godelivery_user/common/widgets/adaptive/navigation/footer_view_widget.dart';
import 'package:godelivery_user/common/widgets/mobile/menu_drawer_widget.dart';
import 'package:godelivery_user/common/widgets/adaptive/empty_states/no_data_screen_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AccessLocationScreen extends StatefulWidget {
  final bool fromSignUp;
  final bool fromHome;
  final String? route;
  final bool hideAppBar;
  const AccessLocationScreen({super.key, required this.fromSignUp, required this.fromHome, required this.route, this.hideAppBar = false});

  @override
  State<AccessLocationScreen> createState() => _AccessLocationScreenState();
}

class _AccessLocationScreenState extends State<AccessLocationScreen> {
  bool _hasAutoNavigated = false;

  @override
  void initState() {
    super.initState();

    // Check and request location permission for all platforms
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load zone list after build to avoid setState during build
      Get.find<LocationController>().getZoneList();
      _checkPermission();

      // Auto-navigate if address already exists (only once)
      if(!widget.fromHome && AddressHelper.getAddressFromSharedPref() != null && !_hasAutoNavigated) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted || _hasAutoNavigated) return; // Prevent if already navigated via permission flow
          _hasAutoNavigated = true;
          Get.find<LocationController>().autoNavigate(
            AddressHelper.getAddressFromSharedPref()!, widget.fromSignUp, widget.route, widget.route != null, ResponsiveHelper.isDesktop(Get.context),
          );
        });
      }
    });
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

  Future<void> _getCurrentLocationAndRoute() async {
    if (_hasAutoNavigated) return; // Prevent duplicate navigation
    _hasAutoNavigated = true;

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
      _hasAutoNavigated = false; // Reset on error
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isLoggedIn = Get.find<AuthController>().isLoggedIn();
    if(isLoggedIn) {
      Get.find<AddressController>().getAddressList();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: widget.hideAppBar ? null : CustomAppBarWidget(title: 'set_location'.tr, isBackButtonExist: widget.fromHome),
      endDrawer: widget.hideAppBar ? null : const MenuDrawerWidget(),
      endDrawerEnableOpenDragGesture: false,
      body: GetBuilder<AddressController>(builder: (addressController) {
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
        ) : widget.hideAppBar
          ? SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Dimensions.paddingSizeLarge,
                  0,
                  Dimensions.paddingSizeLarge,
                  Dimensions.paddingSizeLarge
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Zone List for non-logged-in users
                    Column(
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

                    const SizedBox(height: Dimensions.paddingSizeLarge),

                    BottomButton(addressController: addressController, fromSignUp: widget.fromSignUp, route: widget.route),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              child: FooterViewWidget(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Dimensions.paddingSizeLarge,
                    0,
                    Dimensions.paddingSizeLarge,
                    Dimensions.paddingSizeLarge
                  ),
                  child: Column(children: [

                    // Zone List for non-logged-in users
                    Column(
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

                    const SizedBox(height: Dimensions.paddingSizeLarge),

                    BottomButton(addressController: addressController, fromSignUp: widget.fromSignUp, route: widget.route),

                  ]),
                ),
              ),
            );
      }),
      bottomNavigationBar: !ResponsiveHelper.isDesktop(context) && isLoggedIn ? GetBuilder<AddressController>(
        builder: (addressController) {
          return SizedBox(height: context.height * 0.24, child: BottomButton(addressController: addressController, fromSignUp: widget.fromSignUp, route: widget.route));
        }
      ) : const SizedBox(),
    );
  }
}

