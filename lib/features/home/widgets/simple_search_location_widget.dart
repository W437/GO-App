import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/features/auth/controllers/auth_controller.dart';
import 'package:godelivery_user/features/location/controllers/location_controller.dart';
import 'package:godelivery_user/helper/business_logic/address_helper.dart';
import 'package:godelivery_user/helper/business_logic/auth_helper.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/images.dart';
import 'package:godelivery_user/util/styles.dart';

class SimpleSearchLocationWidget extends StatelessWidget {
  const SimpleSearchLocationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // Search Bar
          InkWell(
            onTap: () => Get.toNamed(RouteHelper.getSearchRoute()),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    size: 22,
                    color: Theme.of(context).hintColor,
                  ),
                  const SizedBox(width: Dimensions.paddingSizeSmall),
                  Expanded(
                    child: Text(
                      'are_you_hungry'.tr,
                      style: robotoRegular.copyWith(
                        fontSize: Dimensions.fontSizeDefault,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: Dimensions.paddingSizeSmall),

          // Location Selector
          GetBuilder<LocationController>(
            builder: (locationController) {
              return InkWell(
                onTap: () => Get.toNamed(RouteHelper.getAccessLocationRoute('home')),
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        AuthHelper.isLoggedIn()
                            ? (AddressHelper.getAddressFromSharedPref()!.addressType == 'home'
                                ? Icons.home_filled
                                : AddressHelper.getAddressFromSharedPref()!.addressType == 'office'
                                    ? Icons.work
                                    : Icons.location_on)
                            : Icons.location_on,
                        size: 20,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: Dimensions.paddingSizeSmall),
                      Expanded(
                        child: Text(
                          AddressHelper.getAddressFromSharedPref()!.address!,
                          style: robotoRegular.copyWith(
                            color: Theme.of(context).textTheme.bodyMedium!.color,
                            fontSize: Dimensions.fontSizeDefault,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        size: 24,
                        color: Theme.of(context).primaryColor,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
