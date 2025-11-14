import 'package:godelivery_user/features/auth/controllers/restaurant_registration_controller.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/common/widgets/shared/forms/modern_input_field_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/util/styles.dart';

class ZoneSelectionWidget extends StatelessWidget {
  final RestaurantRegistrationController restaurantRegController;
  final Function() callBack;
  const ZoneSelectionWidget({super.key, required this.restaurantRegController, required this.callBack});

  @override
  Widget build(BuildContext context) {
    return restaurantRegController.zoneIds != null ? ModernInputFieldWidget<int>(
      inputFieldType: ModernInputType.dropdown,
      labelText: 'select_zone'.tr,
      hintText: 'select_zone'.tr,
      required: true,
      selectedValue: restaurantRegController.selectedZoneIndex,
      dropdownItems: restaurantRegController.zoneList!.asMap().entries.map((entry) {
        return DropdownItem<int>(
          value: entry.key,
          label: entry.value.name!.tr,
        );
      }).toList(),
      onDropdownChanged: (value) {
        restaurantRegController.setZoneIndex(value);
        callBack();
      },
    ) : Center(child: Text('service_not_available_in_this_area'.tr));
  }
}