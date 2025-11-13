import 'package:godelivery_user/common/widgets/shared/feedback/custom_loader_widget.dart';
import 'package:godelivery_user/features/address/controllers/address_controller.dart';
import 'package:godelivery_user/features/address/domain/models/address_model.dart';
import 'package:godelivery_user/features/location/controllers/location_controller.dart';
import 'package:godelivery_user/features/location/domain/models/zone_response_model.dart';
import 'package:godelivery_user/features/address/widgets/address_card_widget.dart';
import 'package:godelivery_user/helper/business_logic/address_helper.dart';
import 'package:godelivery_user/helper/ui/responsive_helper.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/images.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:godelivery_user/common/widgets/shared/feedback/custom_snackbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

class AddressBottomSheet extends StatefulWidget {
  const AddressBottomSheet({super.key});

  @override
  State<AddressBottomSheet> createState() => _AddressBottomSheetState();
}

class _AddressBottomSheetState extends State<AddressBottomSheet> with SingleTickerProviderStateMixin {
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius : const BorderRadius.only(
          topLeft: Radius.circular(Dimensions.paddingSizeExtraLarge),
          topRight : Radius.circular(Dimensions.paddingSizeExtraLarge),
        ),
      ),
      child: GetBuilder<AddressController>(
        builder: (addressController) {
          AddressModel? selectedAddress = AddressHelper.getAddressFromSharedPref();
          return Column(mainAxisSize: MainAxisSize.min, children: [

            Center(
              child: Container(
                margin: const EdgeInsets.only(top: Dimensions.paddingSizeDefault, bottom: Dimensions.paddingSizeDefault),
                height: 3, width: 40,
                decoration: BoxDecoration(
                    color: Theme.of(context).highlightColor,
                    borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall)
                ),
              ),
            ),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeSmall),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [

                  Text('${'hey_welcome_back'.tr}\n${'which_location_do_you_want_to_select'.tr}', style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
                  const SizedBox(height: Dimensions.paddingSizeLarge),

                  addressController.addressList != null && addressController.addressList!.isEmpty ? Column(children: [

                    GestureDetector(
                      onTap: _playAnimation,
                      child: AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _scaleAnimation.value,
                            child: Transform.rotate(
                              angle: _rotationAnimation.value,
                              child: Lottie.asset('assets/animations/location_lottie.json', width: 200, height: 150),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeLarge),

                    Text(
                      'you_dont_have_any_saved_address_yet'.tr, textAlign: TextAlign.center,
                      style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeLarge),

                  ]) : const SizedBox(),

                  addressController.addressList != null && addressController.addressList!.isEmpty
                      ? const SizedBox(height: Dimensions.paddingSizeLarge) : const SizedBox(),

                  Align(
                    alignment: addressController.addressList != null && addressController.addressList!.isNotEmpty ? Alignment.centerLeft : Alignment.center,
                    child: TextButton.icon(
                      onPressed: () => _onCurrentLocationButtonPressed(),
                      style: TextButton.styleFrom(
                        backgroundColor: addressController.addressList != null && addressController.addressList!.isEmpty
                            ? Theme.of(context).primaryColor : Colors.transparent,
                      ),

                      icon:  Icon(Icons.my_location, color: addressController.addressList != null && addressController.addressList!.isEmpty
                          ? Theme.of(context).cardColor : Theme.of(context).primaryColor),
                      label: Text('use_current_location'.tr, style: robotoMedium.copyWith(color: addressController.addressList != null && addressController.addressList!.isEmpty
                          ? Theme.of(context).cardColor : Theme.of(context).primaryColor)),
                    ),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeSmall),

                  addressController.addressList != null ? addressController.addressList!.isNotEmpty ? Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeSmall),
                    child: ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: addressController.addressList!.length > 5 ? 5 : addressController.addressList!.length,
                      itemBuilder: (context, index) {
                        bool selected = false;
                        if(selectedAddress!.id == addressController.addressList![index].id){
                          selected = true;
                        }
                        return Center(child: SizedBox(width: 700, child: AddressCardWidget(
                          address: addressController.addressList![index],
                          fromAddress: false, isSelected: selected, fromDashBoard: true,
                          onTap: () {
                            Get.dialog(const CustomLoaderWidget(), barrierDismissible: false);
                            AddressModel address = addressController.addressList![index];
                            Get.find<LocationController>().saveAddressAndNavigate(
                              address, false, null, false, ResponsiveHelper.isDesktop(context),
                            );
                          },
                        )));
                      },
                    ),
                  ) : const SizedBox() : const Center(child: CircularProgressIndicator()),

                  SizedBox(height: addressController.addressList != null && addressController.addressList!.isEmpty ? 0 : Dimensions.paddingSizeSmall),

                  addressController.addressList != null && addressController.addressList!.isNotEmpty ? TextButton.icon(
                    onPressed: () => Get.toNamed(RouteHelper.getAddAddressRoute(false, 0)),
                    icon: const Icon(Icons.add_circle_outline_sharp),
                    label: Text('add_new_address'.tr, style: robotoMedium.copyWith(color: Theme.of(context).primaryColor)),
                  ) : const SizedBox(),

                ]),
              ),
            ),
          ]);
        }
      ),
    );
  }

  void _onCurrentLocationButtonPressed() {
    Get.find<LocationController>().checkPermission(() async {
      Get.dialog(const CustomLoaderWidget(), barrierDismissible: false);
      AddressModel address = await Get.find<LocationController>().getCurrentLocation(true);
      ZoneResponseModel response = await Get.find<LocationController>().getZone(address.latitude, address.longitude, false);
      if(response.isSuccess) {
        Get.find<LocationController>().saveAddressAndNavigate(
          address, false, '', false, ResponsiveHelper.isDesktop(Get.context),
        );
      }else {
        Get.back();
        Get.toNamed(RouteHelper.getPickMapRoute(RouteHelper.accessLocation, false));
        showCustomSnackBar('service_not_available_in_current_location'.tr);
      }
    });
  }
}
