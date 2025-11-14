
import 'package:country_code_picker/country_code_picker.dart';
import 'package:godelivery_user/common/widgets/shared/text/validate_check.dart';
import 'package:godelivery_user/features/auth/controllers/auth_controller.dart';
import 'package:godelivery_user/features/language/controllers/localization_controller.dart';
import 'package:godelivery_user/features/order/controllers/order_controller.dart';
import 'package:godelivery_user/features/splash/controllers/splash_controller.dart';
import 'package:godelivery_user/helper/utilities/custom_validator.dart';
import 'package:godelivery_user/helper/ui/responsive_helper.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:godelivery_user/common/widgets/shared/buttons/custom_button_widget.dart';
import 'package:godelivery_user/common/widgets/shared/feedback/custom_snackbar_widget.dart';
import 'package:godelivery_user/common/widgets/shared/forms/modern_input_field_widget.dart';
import 'package:godelivery_user/common/widgets/adaptive/navigation/footer_view_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

class GuestTrackOrderInputViewWidget extends StatefulWidget {
  const GuestTrackOrderInputViewWidget({super.key});

  @override
  State<GuestTrackOrderInputViewWidget> createState() => _GuestTrackOrderInputViewWidgetState();
}

class _GuestTrackOrderInputViewWidgetState extends State<GuestTrackOrderInputViewWidget> {
  final TextEditingController _orderIdController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final FocusNode _orderFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  String? _countryDialCode;
  GlobalKey<FormState>? _formKeyOrder;

  @override
  void initState() {
    super.initState();

    _formKeyOrder = GlobalKey<FormState>();
    _countryDialCode = Get.find<AuthController>().getUserCountryCode().isNotEmpty
        ? Get.find<AuthController>().getUserCountryCode()
        : CountryCode.fromCountryCode(Get.find<SplashController>().configModel!.country!).dialCode;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: SingleChildScrollView(
            padding: ResponsiveHelper.isDesktop(context) ? EdgeInsets.zero : const EdgeInsets.fromLTRB(
              Dimensions.radiusExtraLarge,
              Dimensions.paddingSizeLarge,
              Dimensions.radiusExtraLarge,
              100, // Bottom padding for fixed button
            ),
            child: FooterViewWidget(
              child: SizedBox(
                width: Dimensions.webMaxWidth,
                child: Form(
                  key: _formKeyOrder,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [

                  SizedBox(height: ResponsiveHelper.isDesktop(context) ? 100 : MediaQuery.of(context).size.height * 0.10),

                  // Lottie Animation
                  Lottie.asset(
                    'assets/animations/food_changing_orders_lottie.json',
                    width: ResponsiveHelper.isDesktop(context) ? 200 : 150,
                    height: ResponsiveHelper.isDesktop(context) ? 200 : 150,
                    repeat: true,
                  ),
                  const SizedBox(height: Dimensions.paddingSizeDefault),

                  Text(
                    'track_your_order'.tr,
                    style: robotoBold.copyWith(
                      fontSize: Dimensions.fontSizeOverLarge,
                      color: Theme.of(context).textTheme.bodyLarge!.color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: Dimensions.paddingSizeSmall),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
                    child: Text(
                      'guest_track_order_description'.tr,
                      style: robotoRegular.copyWith(
                        fontSize: Dimensions.fontSizeDefault,
                        color: Theme.of(context).disabledColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeExtraLarge),

                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: ResponsiveHelper.isDesktop(context) ? 500 : double.infinity),
                    child: ModernInputFieldWidget(
                    hintText: '',
                    controller: _orderIdController,
                    focusNode: _orderFocus,
                    nextFocus: _phoneFocus,
                    inputType: TextInputType.number,
                    isNumber: true,
                    labelText: 'order_id'.tr,
                    required: true,
                    validator: (value) => ValidateCheck.validateEmptyText(value, null),
                    ),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeDefault),

                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: ResponsiveHelper.isDesktop(context) ? 500 : double.infinity),
                    child: ModernInputFieldWidget(
                    hintText: '',
                    controller: _phoneNumberController,
                    focusNode: _phoneFocus,
                    inputType: TextInputType.phone,
                    inputAction: TextInputAction.done,
                    isPhone: true,
                    onCountryChanged: (CountryCode countryCode) {
                      _countryDialCode = countryCode.dialCode;
                    },
                    countryDialCode: _countryDialCode ?? Get.find<LocalizationController>().locale.countryCode,
                    labelText: 'phone'.tr,
                    required: true,
                    validator: (value) => ValidateCheck.validateEmptyText(value, "phone_number_field_is_required".tr),
                    ),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeExtraLarge),

                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Fixed Track Order Button
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(
              Dimensions.paddingSizeLarge,
              Dimensions.paddingSizeDefault,
              Dimensions.paddingSizeLarge,
              MediaQuery.of(context).padding.bottom + Dimensions.paddingSizeDefault,
            ),
            child: GetBuilder<OrderController>(
              builder: (orderController) {
                return CustomButtonWidget(
                  buttonText: 'track_order'.tr,
                  isLoading: orderController.isLoading,
                  onPressed: () async {
                    String phone = _phoneNumberController.text.trim();
                    String orderId = _orderIdController.text.trim();
                    String numberWithCountryCode = _countryDialCode! + phone;
                    PhoneValid phoneValid = await CustomValidator.isPhoneValid(numberWithCountryCode);
                    numberWithCountryCode = phoneValid.phone;

                    if(_formKeyOrder!.currentState!.validate()) {
                      if (orderId.isEmpty) {
                        showCustomSnackBar('please_enter_order_id'.tr);
                      } else if (phone.isEmpty) {
                        showCustomSnackBar('enter_phone_number'.tr);
                      } else if (!phoneValid.isValid) {
                        showCustomSnackBar('invalid_phone_number'.tr);
                      } else {
                        orderController.trackOrder(
                            orderId, null, false, contactNumber: numberWithCountryCode, fromGuestInput: true)
                            .then((response) {
                          if (response.isSuccess) {
                            Get.toNamed(RouteHelper.getGuestTrackOrderScreen(orderId, numberWithCountryCode));
                          }
                        });
                      }
                    }
                  },
                );
              }
            ),
          ),
        ),
      ],
    );
  }
}
