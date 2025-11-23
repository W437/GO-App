import 'package:godelivery_user/features/checkout/controllers/checkout_controller.dart';
import 'package:godelivery_user/features/checkout/widgets/checkout_section_card.dart';
import 'package:godelivery_user/features/checkout/widgets/time_slot_bottom_sheet.dart';
import 'package:godelivery_user/features/splash/controllers/splash_controller.dart';
import 'package:godelivery_user/features/auth/controllers/auth_controller.dart';
import 'package:godelivery_user/common/widgets/shared/buttons/custom_button_widget.dart';
import 'package:godelivery_user/helper/ui/responsive_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
class TimeSlotSection extends StatelessWidget {
  final bool fromCart;
  final CheckoutController checkoutController;
  final bool tomorrowClosed;
  final bool todayClosed;
  final JustTheController tooltipController2;
  const TimeSlotSection({super.key, required this.fromCart, required this.checkoutController, required this.tomorrowClosed, required this.todayClosed, required this.tooltipController2, });

  @override
  Widget build(BuildContext context) {
    bool isDesktop = ResponsiveHelper.isDesktop(context);
    bool isGuestLoggedIn = Get.find<AuthController>().isGuestLoggedIn();
    bool isDineIn = checkoutController.orderType == 'dine_in';

    bool showTimeSection = (!isGuestLoggedIn && fromCart && !checkoutController.subscriptionOrder && checkoutController.restaurant!.scheduleOrder! && !isDineIn);
    final bool isClosed = (checkoutController.selectedDateSlot == 0 && todayClosed)
        || (checkoutController.selectedDateSlot == 1 && tomorrowClosed)
        || (checkoutController.selectedDateSlot == 2 && checkoutController.customDateRestaurantClose);

    String timeLabel = '';
    if(isClosed) {
      timeLabel = 'restaurant_is_closed'.tr;
    }else if(checkoutController.preferableTime.isNotEmpty) {
      timeLabel = checkoutController.preferableTime;
    }else if(Get.find<SplashController>().configModel!.instantOrder! && checkoutController.restaurant!.instantOrder!) {
      timeLabel = 'now'.tr;
    }else{
      timeLabel = 'select_preference_time'.tr;
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      showTimeSection ? (isDesktop ? _buildDesktopTimePicker(context, timeLabel, isClosed) : CheckoutSectionCard(
        title: 'preference_time'.tr,
        trailing: _infoIcon(),
        child: InkWell(
          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
          onTap: () => _openTimePicker(context),
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
              border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.12)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(child: Text(
                  timeLabel,
                  style: robotoMedium.copyWith(
                    color: isClosed ? Theme.of(context).colorScheme.error : Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                )),
                CustomButtonWidget(
                  isCircular: true,
                  height: 42,
                  width: 42,
                  expand: false,
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.14),
                  border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.5)),
                  icon: Icons.access_time,
                  iconColor: Theme.of(context).primaryColor,
                  iconSize: 20,
                  onPressed: () => _openTimePicker(context),
                ),
              ],
            ),
          ),
        ),
      )) : const SizedBox(),

      SizedBox(height: showTimeSection ? Dimensions.paddingSizeSmall : 0),

    ]);
  }

  Widget tobView({required BuildContext context, required String title, required bool isSelected, required Function() onTap}){
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Text(title, style: isSelected ? robotoBold.copyWith(color: Theme.of(context).primaryColor) : robotoMedium),
          Divider(color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).disabledColor, thickness: isSelected ? 2 : 1),
        ],
      ),
    );
  }

  Widget _buildDesktopTimePicker(BuildContext context, String timeLabel, bool isClosed) {
    bool isDesktop = ResponsiveHelper.isDesktop(context);
    return CheckoutSectionCard(
      title: 'preference_time'.tr,
      trailing: _infoIcon(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        InkWell(
          onTap: () => _openTimePicker(context),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).disabledColor, width: 0.3),
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              color: Theme.of(context).cardColor,
            ),
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
            child: Row(children: [
              Expanded(child: Text(
                timeLabel,
                style: robotoRegular.copyWith(
                  color: isClosed ? Theme.of(context).colorScheme.error : Theme.of(context).textTheme.bodyMedium!.color,
                ),
              )),
              CustomButtonWidget(
                isCircular: true,
                height: 40,
                width: 40,
                expand: false,
                color: Theme.of(context).primaryColor.withValues(alpha: 0.14),
                border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.5)),
                icon: Icons.access_time_filled_outlined,
                iconColor: Theme.of(context).primaryColor,
                iconSize: 18,
                onPressed: () => _openTimePicker(context),
              ),
            ]),
          ),
        ),
        isDesktop && checkoutController.canShowTimeSlot ? Padding(
          padding: const EdgeInsets.only(top: Dimensions.paddingSizeLarge),
          child: TimeSlotBottomSheet(tomorrowClosed: tomorrowClosed, todayClosed: todayClosed, restaurant: checkoutController.restaurant!),
        ) : const SizedBox(),
      ]),
    );
  }

  Widget _infoIcon() {
    return JustTheTooltip(
      backgroundColor: Colors.black87,
      controller: tooltipController2,
      preferredDirection: AxisDirection.right,
      tailLength: 14,
      tailBaseWidth: 20,
      content: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text('schedule_time_tool_tip'.tr,style: robotoRegular.copyWith(color: Colors.white)),
      ),
      child: InkWell(
        onTap: () => tooltipController2.showTooltip(),
        child: const Icon(Icons.info_outline),
      ),
    );
  }

  void _openTimePicker(BuildContext context) {
    if(ResponsiveHelper.isDesktop(context)){
      checkoutController.showHideTimeSlot();
    }else{
      showModalBottomSheet(
        context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
        builder: (con) => TimeSlotBottomSheet(
          tomorrowClosed: tomorrowClosed,
          todayClosed: todayClosed,
          restaurant: checkoutController.restaurant!,
        ),
      );
    }
  }
}
