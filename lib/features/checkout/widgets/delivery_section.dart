import 'package:godelivery_user/features/checkout/controllers/checkout_controller.dart';
import 'package:godelivery_user/features/address/domain/models/address_model.dart';
import 'package:godelivery_user/features/address/widgets/address_card_widget.dart';
import 'package:godelivery_user/features/auth/controllers/auth_controller.dart';
import 'package:godelivery_user/features/checkout/widgets/checkout_section_card.dart';
import 'package:godelivery_user/features/checkout/widgets/delivery_info_fields.dart';
import 'package:godelivery_user/common/widgets/shared/buttons/custom_button_widget.dart';
import 'package:godelivery_user/features/location/controllers/location_controller.dart';
import 'package:godelivery_user/features/location/widgets/permission_dialog.dart';
import 'package:godelivery_user/helper/ui/responsive_helper.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:godelivery_user/common/widgets/adaptive/forms/custom_dropdown_widget.dart';
import 'package:godelivery_user/common/widgets/shared/feedback/custom_toast_widget.dart';
import 'package:godelivery_user/common/widgets/shared/forms/modern_input_field_widget.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DeliverySection extends StatelessWidget {
  final CheckoutController checkoutController;
  final LocationController locationController;
  final TextEditingController guestNameTextEditingController;
  final TextEditingController guestNumberTextEditingController;
  final TextEditingController guestEmailController;
  final FocusNode guestNumberNode;
  final FocusNode guestEmailNode;
  const DeliverySection({super.key, required this.checkoutController,
    required this.locationController, required this.guestNameTextEditingController,
    required this.guestNumberTextEditingController, required this.guestNumberNode, required this.guestEmailController, required this.guestEmailNode});

  @override
  Widget build(BuildContext context) {
    bool isGuestLoggedIn = Get.find<AuthController>().isGuestLoggedIn();
    bool takeAway = (checkoutController.orderType == 'take_away');
    bool isDineIn = (checkoutController.orderType == 'dine_in');
    bool isDesktop = ResponsiveHelper.isDesktop(context);
    GlobalKey<CustomDropdownState> dropDownKey = GlobalKey<CustomDropdownState>();
    AddressModel addressModel;

    return Column(children: [
      isGuestLoggedIn || isDineIn ? DeliveryInfoFields(
        checkoutController: checkoutController, guestNumberNode: guestNumberNode,
        guestNameTextEditingController: guestNameTextEditingController,
        guestNumberTextEditingController: guestNumberTextEditingController,
        guestEmailController: guestEmailController, guestEmailNode: guestEmailNode,
      ) : !takeAway && !isDineIn ? CheckoutSectionCard(
        title: 'deliver_to'.tr,
        trailing: CustomButtonWidget(
          isCircular: true,
          height: 42,
          width: 42,
          expand: false,
          color: Colors.white,
          border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.4)),
          icon: Icons.arrow_drop_down_rounded,
          iconColor: Theme.of(context).textTheme.bodyMedium?.color,
          iconSize: 26,
          onPressed: () => dropDownKey.currentState?.toggleDropdown(),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                color: Colors.transparent,
                border: Border.all(color: Colors.transparent)
            ),
            child: CustomDropdown<int>(
              key: dropDownKey,
              hideIcon: true,
              onChange: (int? value, int index) async {

                if(value == -1) {
                  var address = await Get.toNamed(RouteHelper.getAddAddressRoute(true, checkoutController.restaurant!.zoneId));
                  if(address != null) {

                    checkoutController.insertAddresses(Get.context!, address, notify: true);

                    checkoutController.streetNumberController.text = address.road ?? '';
                    checkoutController.houseController.text = address.house ?? '';
                    checkoutController.floorController.text = address.floor ?? '';

                    checkoutController.getDistanceInKM(
                      LatLng(double.parse(address.latitude), double.parse(address.longitude )),
                      LatLng(double.parse(checkoutController.restaurant!.latitude!), double.parse(checkoutController.restaurant!.longitude!)),
                    );
                  }
                } else if(value == -2) {
                  _checkPermission(() async {
                    addressModel = await locationController.getCurrentLocation(true, mapController: null, showSnackBar: true);

                    if(addressModel.zoneIds!.isNotEmpty) {

                      checkoutController.insertAddresses(Get.context!, addressModel, notify: true);

                      checkoutController.getDistanceInKM(
                        LatLng(
                          locationController.position.latitude, locationController.position.longitude,
                        ),
                        LatLng(double.parse(checkoutController.restaurant!.latitude!), double.parse(checkoutController.restaurant!.longitude!)),
                      );
                    }
                  });

                } else{
                  checkoutController.getDistanceInKM(
                    LatLng(
                      double.parse(checkoutController.address[value!].latitude!),
                      double.parse(checkoutController.address[value].longitude!),
                    ),
                    LatLng(double.parse(checkoutController.restaurant!.latitude!), double.parse(checkoutController.restaurant!.longitude!)),
                  );
                  checkoutController.setAddressIndex(value);

                  checkoutController.streetNumberController.text = checkoutController.address[value].road ?? '';
                  checkoutController.houseController.text = checkoutController.address[value].house ?? '';
                  checkoutController.floorController.text = checkoutController.address[value].floor ?? '';
                }

              },
              dropdownButtonStyle: DropdownButtonStyle(
                height: 0, width: double.infinity,
                padding: EdgeInsets.zero,
                backgroundColor: Colors.transparent,
                primaryColor: Theme.of(context).textTheme.bodyLarge!.color,
              ),
              dropdownStyle: DropdownStyle(
                elevation: 10,
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
              ),
              items: checkoutController.addressList,
              child: const SizedBox(),

            ),
          ),
          Container(
            constraints: BoxConstraints(minHeight: ResponsiveHelper.isDesktop(context) ? 90 : 75),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
              color: Colors.white,
              border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.4), width: 1),
            ),
            child: AddressCardWidget(
              address: (checkoutController.address.length-1) >= checkoutController.addressIndex ? checkoutController.address[checkoutController.addressIndex] : checkoutController.address[0],
              fromAddress: false, fromCheckout: true,
            ),
          ),

          SizedBox(height: ResponsiveHelper.isDesktop(context) ? Dimensions.paddingSizeExtraLarge : Dimensions.paddingSizeLarge),

          !ResponsiveHelper.isDesktop(context) ? ModernInputFieldWidget(
            hintText: 'write_street_number'.tr,
            labelText: 'street_number'.tr,
            inputType: TextInputType.streetAddress,
            focusNode: checkoutController.streetNode,
            nextFocus: checkoutController.houseNode,
            controller: checkoutController.streetNumberController,
          ) : const SizedBox(),
          SizedBox(height: !ResponsiveHelper.isDesktop(context) ? Dimensions.paddingSizeLarge : 0),

          Row(
            children: [
              ResponsiveHelper.isDesktop(context) ? Expanded(
                child: ModernInputFieldWidget(
                  hintText: 'write_street_number'.tr,
                  labelText: 'street_number'.tr,
                  inputType: TextInputType.streetAddress,
                  focusNode: checkoutController.streetNode,
                  nextFocus: checkoutController.houseNode,
                  controller: checkoutController.streetNumberController,
                ),
              ) : const SizedBox(),
              SizedBox(width: ResponsiveHelper.isDesktop(context) ? Dimensions.paddingSizeSmall : 0),

              Expanded(
                child: ModernInputFieldWidget(
                  hintText: 'write_house_number'.tr,
                  labelText: 'house'.tr,
                  inputType: TextInputType.text,
                  focusNode: checkoutController.houseNode,
                  nextFocus: checkoutController.floorNode,
                  controller: checkoutController.houseController,
                ),
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),

              Expanded(
                child: ModernInputFieldWidget(
                  hintText: 'write_floor_number'.tr,
                  labelText: 'floor'.tr,
                  inputType: TextInputType.text,
                  focusNode: checkoutController.floorNode,
                  inputAction: TextInputAction.done,
                  controller: checkoutController.floorController,
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),

        ]),
      ) : const SizedBox(),
    ]);
  }

  void _checkPermission(Function onTap) async {
    LocationPermission permission = await Geolocator.checkPermission();
    if(permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if(permission == LocationPermission.denied) {
      showCustomSnackBar('you_have_to_allow'.tr);
    }else if(permission == LocationPermission.deniedForever) {
      Get.dialog(const PermissionDialog());
    }else {
      onTap();
    }
  }
}
