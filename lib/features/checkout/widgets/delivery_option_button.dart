import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:godelivery_user/common/widgets/shared/buttons/custom_button_widget.dart';
import 'package:godelivery_user/common/widgets/shared/text/custom_tool_tip.dart';
import 'package:godelivery_user/features/checkout/controllers/checkout_controller.dart';
import 'package:godelivery_user/features/profile/controllers/profile_controller.dart';
import 'package:godelivery_user/helper/business_logic/auth_helper.dart';
import 'package:godelivery_user/helper/utilities/custom_validator.dart';
import 'package:godelivery_user/helper/converters/price_converter.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DeliveryOptionButton extends StatelessWidget {
  final String value;
  final String title;
  final double? charge;
  final bool? isFree;
  final double total;
  final String? chargeForView;
  final JustTheController? deliveryFeeTooltipController;
  final double badWeatherCharge;
  final double extraChargeForToolTip;
  final TextEditingController? guestNameTextEditingController;
  final TextEditingController? guestNumberTextEditingController;
  final TextEditingController? guestEmailController;
  const DeliveryOptionButton({super.key, required this.value, required this.title, required this.charge, required this.isFree, required this.total,
    this.chargeForView, this.deliveryFeeTooltipController, required this.badWeatherCharge, required this.extraChargeForToolTip,
    this.guestNameTextEditingController, this.guestNumberTextEditingController, this.guestEmailController});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CheckoutController>(
      builder: (checkoutController) {
        bool select = checkoutController.orderType == value;
        return SizedBox(
          width: double.infinity,
          child: CustomButtonWidget(
            expand: false,
            height: 82,
            radius: Dimensions.radiusLarge,
            color: select ? Theme.of(context).cardColor : const Color(0xFFF7F8FA),
            border: Border.all(
              color: select
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).disabledColor.withValues(alpha: 0.4),
              width: select ? 1.6 : 1.1,
            ),
            margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
            onPressed: () async {
            checkoutController.setOrderType(value);
            checkoutController.setInstruction(-1);

            if(checkoutController.orderType == 'take_away') {
              checkoutController.addTips(0);
              if(checkoutController.isPartialPay || checkoutController.paymentMethodIndex == 1) {
                double tips = 0;
                try{
                  tips = double.parse(checkoutController.tipController.text);
                } catch(_) {}
                checkoutController.checkBalanceStatus(total, discount: charge! + tips);
              }
            }else if(checkoutController.orderType == 'dine_in') {
              checkoutController.addTips(0);
              if(checkoutController.isPartialPay || checkoutController.paymentMethodIndex == 1) {
                double tips = 0;
                try{
                  tips = double.parse(checkoutController.tipController.text);
                } catch(_) {}
                checkoutController.checkBalanceStatus(total, discount: charge! + tips);
              }

              if(AuthHelper.isLoggedIn()) {
                String phone = await _splitPhoneNumber(Get.find<ProfileController>().userInfoModel?.userInfo?.phone ?? '');

                guestNameTextEditingController?.text = '${Get.find<ProfileController>().userInfoModel?.userInfo?.fName ?? ''} ${Get.find<ProfileController>().userInfoModel?.userInfo?.fName ?? ''}';
                guestNumberTextEditingController?.text = phone;
                guestEmailController?.text = Get.find<ProfileController>().userInfoModel?.userInfo?.email ?? '';
              }

            }else{
              checkoutController.updateTips(
                checkoutController.getDmTipIndex().isNotEmpty ? int.parse(checkoutController.getDmTipIndex()) : 0, notify: false,
              );

              if(checkoutController.isPartialPay){
                checkoutController.changePartialPayment();
              } else {
                checkoutController.setPaymentMethod(-1);
              }
            }
            },
            child: Row(
              children: [
                _buildIconBadge(context, select),
                const SizedBox(width: Dimensions.paddingSizeDefault),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: robotoBold.copyWith(
                          fontSize: Dimensions.fontSizeLarge,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              value == 'delivery'
                                  ? '${'charge'.tr}: ${chargeForView ?? ''}'
                                  : (isFree == true ? 'free'.tr : chargeForView ?? ''),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: robotoRegular.copyWith(
                                fontSize: Dimensions.fontSizeSmall,
                                color: Theme.of(context).hintColor.withValues(alpha: 0.9),
                              ),
                            ),
                          ),
                          const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                          value == 'delivery' && checkoutController.extraCharge != null && (chargeForView ?? '') != '0' && extraChargeForToolTip > 0 ? CustomToolTip(
                            message: '${'this_charge_include_extra_vehicle_charge'.tr} ${PriceConverter.convertPrice(extraChargeForToolTip)} ${badWeatherCharge > 0 ? '${'and_bad_weather_charge'.tr} ${PriceConverter.convertPrice(badWeatherCharge)}' : ''}',
                            tooltipController: deliveryFeeTooltipController,
                            preferredDirection: AxisDirection.right,
                            child: Icon(Icons.info_outline, color: Theme.of(context).primaryColor, size: 16),
                          ) : const SizedBox(),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                _buildSelectionIndicator(context, select),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIconBadge(BuildContext context, bool isSelected) {
    IconData icon = Icons.delivery_dining_rounded;
    if (value == 'take_away') {
      icon = Icons.shopping_bag_outlined;
    } else if (value == 'dine_in') {
      icon = Icons.restaurant_menu_outlined;
    }

    return Container(
      height: 46,
      width: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).primaryColor.withValues(alpha: isSelected ? 0.16 : 0.08),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: isSelected ? 0.8 : 0.4),
          width: 1.2,
        ),
      ),
      child: Icon(icon, color: Theme.of(context).primaryColor, size: 22),
    );
  }

  Widget _buildSelectionIndicator(BuildContext context, bool isSelected) {
    final Color borderColor = isSelected
        ? Theme.of(context).primaryColor
        : Theme.of(context).disabledColor.withValues(alpha: 0.6);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 22,
      width: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
        color: isSelected ? Theme.of(context).primaryColor.withValues(alpha: 0.18) : Colors.transparent,
      ),
      child: isSelected ? Center(
        child: Container(
          height: 10,
          width: 10,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            shape: BoxShape.circle,
          ),
        ),
      ) : const SizedBox(),
    );
  }

  Future<String> _splitPhoneNumber(String number) async {
    PhoneValid phoneNumber = await CustomValidator.isPhoneValid(number);
    Get.find<CheckoutController>().countryDialCode = '+${phoneNumber.countryCode}';
    return phoneNumber.phone.replaceFirst('+${phoneNumber.countryCode}', '');
  }
}
