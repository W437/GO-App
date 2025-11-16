import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/common/widgets/shared/buttons/rounded_icon_button_widget.dart';
import 'package:godelivery_user/common/widgets/shared/text/auto_scroll_text.dart';
import 'package:godelivery_user/features/cart/controllers/cart_controller.dart';
import 'package:godelivery_user/features/location/controllers/location_controller.dart';
import 'package:godelivery_user/features/location/helpers/location_sheet_helper.dart';
import 'package:godelivery_user/features/notification/controllers/notification_controller.dart';
import 'package:godelivery_user/helper/business_logic/address_helper.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';

/// Sticky home header that bundles location, quick actions, and search/filter controls.
class LocationBarWidget extends StatelessWidget {
  final double collapseFactor;

  const LocationBarWidget({
    super.key,
    this.collapseFactor = 0,
  });

  @override
  Widget build(BuildContext context) {
    final clamp = collapseFactor.clamp(0, 1).toDouble();
    final verticalPadding = lerpDouble(
      Dimensions.paddingSizeSmall,
      Dimensions.paddingSizeExtraSmall,
      clamp,
    )!;
    final spacing = (Dimensions.paddingSizeSmall * (1 - clamp))
        .clamp(0.0, Dimensions.paddingSizeSmall);
    final searchVisibility = (1 - clamp).clamp(0, 1).toDouble();
    final searchOpacity = Curves.easeOut.transform(searchVisibility);

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeDefault,
          vertical: verticalPadding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeadlineRow(context, clamp),
            SizedBox(height: spacing),
            ClipRect(
              child: Align(
                heightFactor: searchVisibility,
                alignment: Alignment.topCenter,
                child: Opacity(
                  opacity: searchOpacity,
                  child: _buildSearchRow(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeadlineRow(BuildContext context, double collapse) {
    final labelSpacing = lerpDouble(6, 3, collapse)!.clamp(0.0, 6.0);
    final iconSize = lerpDouble(20, 18, collapse)!;
    final horizontalGap = lerpDouble(
      Dimensions.paddingSizeSmall,
      Dimensions.paddingSizeExtraSmall,
      collapse,
    )!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: GetBuilder<LocationController>(
            builder: (_) {
              return InkWell(
                onTap: () => LocationSheetHelper.showSelectionSheet(context),
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'deliver_to'.tr,
                      style: robotoRegular.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                    SizedBox(height: labelSpacing),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          color: Theme.of(context).primaryColor,
                          size: iconSize,
                        ),
                        SizedBox(width: horizontalGap),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: AutoScrollText(
                                  text: AddressHelper.getAddressFromSharedPref()?.address ?? 'select_location'.tr,
                                  style: robotoBold.copyWith(
                                    fontSize: Dimensions.fontSizeDefault,
                                    color: Theme.of(context).textTheme.bodyLarge!.color,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Theme.of(context).textTheme.bodyLarge!.color,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        Row(
          children: [
            _NotificationButton(),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            _CartButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchRow(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      onTap: () => Get.toNamed(RouteHelper.getSearchRoute()),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeDefault,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search,
              size: 20,
              color: Theme.of(context).hintColor,
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Text(
              'search_food_or_restaurant'.tr,
              style: robotoMedium.copyWith(
                color: Theme.of(context).hintColor,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeExtraSmall,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'now'.tr,
                style: robotoMedium.copyWith(
                  fontSize: Dimensions.fontSizeExtraSmall,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetBuilder<NotificationController>(
      builder: (notificationController) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            RoundedIconButtonWidget(
              icon: Icons.notifications_outlined,
              onPressed: () => Get.toNamed(RouteHelper.getNotificationRoute()),
              size: 44,
              iconSize: 22,
              backgroundColor: Theme.of(context).hintColor.withValues(alpha: 0.08),
              pressedColor: Theme.of(context).hintColor.withValues(alpha: 0.2),
              iconColor: Theme.of(context).textTheme.bodyLarge!.color,
            ),
            if (notificationController.hasNotification)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  height: 10,
                  width: 10,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(
                      width: 2,
                      color: Theme.of(context).cardColor,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CartButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetBuilder<CartController>(
      builder: (cartController) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            RoundedIconButtonWidget(
              icon: Icons.shopping_bag_outlined,
              onPressed: () => Get.toNamed(RouteHelper.getCartRoute()),
              size: 44,
              iconSize: 22,
              backgroundColor: Theme.of(context).hintColor.withValues(alpha: 0.08),
              pressedColor: Theme.of(context).hintColor.withValues(alpha: 0.2),
              iconColor: Theme.of(context).textTheme.bodyLarge!.color,
            ),
            if (cartController.cartList.isNotEmpty)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    '${cartController.cartList.length}',
                    style: robotoMedium.copyWith(
                      fontSize: 10,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
