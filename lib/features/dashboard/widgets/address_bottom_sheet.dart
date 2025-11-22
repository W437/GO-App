import 'package:godelivery_user/common/widgets/shared/buttons/custom_button_widget.dart';
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

class AddressBottomSheet extends StatelessWidget {
  const AddressBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AddressController>(
      builder: (addressController) {
        AddressModel? selectedAddress = AddressHelper.getAddressFromSharedPref();
        bool hasNoAddresses = addressController.addressList != null && addressController.addressList!.isEmpty;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              '${'hey_welcome_back'.tr}\n${'which_location_do_you_want_to_select'.tr}',
              style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault),
            ),
            const SizedBox(height: Dimensions.paddingSizeLarge),

            // Empty state
            if (hasNoAddresses) ...[
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.location_on_rounded,
                    size: 60,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeLarge),
              Text(
                'you_dont_have_any_saved_address_yet'.tr,
                textAlign: TextAlign.center,
                style: robotoRegular.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: Theme.of(context).hintColor,
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeLarge),
            ],

            // Current location button
            if (hasNoAddresses)
              CustomButtonWidget(
                buttonText: 'use_current_location'.tr,
                icon: Icons.my_location,
                onPressed: () => _onCurrentLocationButtonPressed(context),
              )
            else
              CustomButtonWidget(
                buttonText: 'use_current_location'.tr,
                icon: Icons.my_location,
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                textColor: Theme.of(context).primaryColor,
                onPressed: () => _onCurrentLocationButtonPressed(context),
              ),
            const SizedBox(height: Dimensions.paddingSizeSmall),

            // Saved addresses list
            if (addressController.addressList != null && addressController.addressList!.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeSmall,
                  vertical: Dimensions.paddingSizeSmall,
                ),
                child: ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: addressController.addressList!.length > 5
                      ? 5
                      : addressController.addressList!.length,
                  itemBuilder: (context, index) {
                    bool selected = selectedAddress!.id == addressController.addressList![index].id;
                    return Center(
                      child: SizedBox(
                        width: 700,
                        child: AddressCardWidget(
                          address: addressController.addressList![index],
                          fromAddress: false,
                          isSelected: selected,
                          fromDashBoard: true,
                          onTap: () {
                            Get.dialog(const CustomLoaderWidget(), barrierDismissible: false);
                            AddressModel address = addressController.addressList![index];
                            Get.find<LocationController>().saveAddressAndNavigate(
                              address,
                              false,
                              null,
                              false,
                              ResponsiveHelper.isDesktop(context),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),

            if (addressController.addressList != null && addressController.addressList!.isNotEmpty)
              const SizedBox(height: Dimensions.paddingSizeSmall),

            // Add new address button
            if (addressController.addressList != null && addressController.addressList!.isNotEmpty)
              CustomButtonWidget(
                buttonText: 'add_new_address'.tr,
                icon: Icons.add_circle_outline_sharp,
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                textColor: Theme.of(context).primaryColor,
                onPressed: () => Get.toNamed(RouteHelper.getAddAddressRoute(false, 0)),
              ),

            if (addressController.addressList == null)
              const Center(child: CircularProgressIndicator()),
          ],
        );
      },
    );
  }

  void _onCurrentLocationButtonPressed(BuildContext context) {
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
