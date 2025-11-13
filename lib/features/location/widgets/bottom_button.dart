import 'package:godelivery_user/common/widgets/custom_button_widget.dart';
import 'package:godelivery_user/common/widgets/custom_loader_widget.dart';
import 'package:godelivery_user/features/address/controllers/address_controller.dart';
import 'package:godelivery_user/features/address/domain/models/address_model.dart';
import 'package:godelivery_user/features/auth/controllers/auth_controller.dart';
import 'package:godelivery_user/features/location/controllers/location_controller.dart';
import 'package:godelivery_user/features/location/domain/models/zone_response_model.dart';
import 'package:godelivery_user/features/location/widgets/permission_dialog.dart';
import 'package:godelivery_user/features/location/widgets/pick_map_dialog.dart';
import 'package:godelivery_user/features/profile/controllers/profile_controller.dart';
import 'package:godelivery_user/helper/ui/responsive_helper.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:godelivery_user/common/widgets/custom_snackbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

class BottomButton extends StatelessWidget {
  final AddressController addressController;
  final bool fromSignUp;
  final String? route;
  const BottomButton({super.key, required this.addressController, required this.fromSignUp, required this.route});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      child: Column(children: [

        CustomButtonWidget(
          width: double.infinity,
          buttonText: 'user_current_location'.tr,
          onPressed: () async {
            _checkPermission(() async {
              Get.dialog(const CustomLoaderWidget(), barrierDismissible: false);
              AddressModel address = await Get.find<LocationController>().getCurrentLocation(true);
              ZoneResponseModel response = await Get.find<LocationController>().getZone(address.latitude, address.longitude, false);
              if(response.isSuccess) {
                if(!Get.find<AuthController>().isGuestLoggedIn() || !Get.find<AuthController>().isLoggedIn()) {
                  Get.find<AuthController>().guestLogin().then((response) {
                    if(response.isSuccess) {
                      Get.find<ProfileController>().setForceFullyUserEmpty();
                      Get.find<LocationController>().saveAddressAndNavigate(address, fromSignUp, route, route != null, ResponsiveHelper.isDesktop(Get.context));
                    }
                  });
                } else {
                  Get.find<LocationController>().saveAddressAndNavigate(address, fromSignUp, route, route != null, ResponsiveHelper.isDesktop(Get.context));
                }
              }else {
                Get.back();
                Get.toNamed(RouteHelper.getPickMapRoute(route ?? RouteHelper.accessLocation, route != null));
                showCustomSnackBar('service_not_available_in_current_location'.tr);
              }
            });
          },
          icon: Icons.my_location,
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),

        CustomButtonWidget(
          width: double.infinity,
          buttonText: 'set_from_map'.tr,
          transparent: true,
          border: Border.all(width: 2, color: Theme.of(context).primaryColor),
          textColor: Theme.of(context).primaryColor,
          iconColor: Theme.of(context).primaryColor,
          icon: Icons.map,
          onPressed: () {
            if(ResponsiveHelper.isDesktop(Get.context)) {
              showGeneralDialog(context: context, pageBuilder: (_,__,___) {
                return SizedBox(
                  height: 300, width: 300,
                  child: PickMapDialog(
                    fromSignUp: fromSignUp, canRoute: route != null, fromAddAddress: false, route: route
                      ?? (fromSignUp ? RouteHelper.signUp : RouteHelper.accessLocation),
                  ),
                );
              });
            }else {
              Get.toNamed(RouteHelper.getPickMapRoute(
                route ?? (fromSignUp ? RouteHelper.signUp : RouteHelper.accessLocation), route != null,
              ));
            }
          },
        ),

      ]),
    );
  }

  void _checkPermission(Function onTap) async {
    await Geolocator.requestPermission();
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