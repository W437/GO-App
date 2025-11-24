import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/common/widgets/shared/text/auto_scroll_text.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:godelivery_user/common/widgets/shared/buttons/rounded_icon_button_widget.dart';
import 'package:godelivery_user/common/widgets/shared/sheets/custom_full_sheet.dart';
import 'package:godelivery_user/features/location/controllers/location_controller.dart';
import 'package:godelivery_user/features/location/screens/pick_map_screen.dart';
import 'package:godelivery_user/features/location/widgets/location_selection_sheet.dart';
import 'package:godelivery_user/features/location/widgets/permission_dialog.dart';
import 'package:godelivery_user/features/notification/controllers/notification_controller.dart';
import 'package:godelivery_user/features/notification/widgets/notification_content_widget.dart';
import 'package:godelivery_user/features/cart/controllers/cart_controller.dart';
import 'package:godelivery_user/helper/business_logic/address_helper.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';

/// Simple home header widget with location, notification, and cart
class NewHomeHeaderWidget extends StatelessWidget {
  const NewHomeHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeExtraLarge,
            vertical: Dimensions.paddingSizeExtraLarge,
          ),
          child: SizedBox(
            height: 56, // Fixed height for consistent header
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Location Picker on the left
                Expanded(
                  child: GetBuilder<LocationController>(
                    builder: (locationController) {
                      return InkWell(
                        onTap: () => _showLocationSheet(context),
                        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              color: Theme.of(context).primaryColor,
                              size: 24,
                            ),
                            const SizedBox(width: Dimensions.paddingSizeSmall),
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
                      );
                    },
                  ),
                ),

                const SizedBox(width: Dimensions.paddingSizeDefault),

                // Notification Button
                GetBuilder<NotificationController>(
                  builder: (notificationController) {
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        RoundedIconButtonWidget(
                          icon: Icons.notifications_outlined,
                          onPressed: () => CustomFullSheet.show(
                            context: context,
                            child: Scaffold(
                              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                              appBar: PreferredSize(
                                preferredSize: const Size.fromHeight(60),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: SafeArea(
                                    bottom: false,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: Dimensions.paddingSizeDefault,
                                        vertical: Dimensions.paddingSizeSmall,
                                      ),
                                      child: Row(
                                        children: [
                                          // Back Button
                                          RoundedIconButtonWidget(
                                            icon: Icons.arrow_back,
                                            onPressed: () => Get.back(),
                                            size: 36,
                                            iconSize: 20,
                                            backgroundColor: Theme.of(context).hintColor.withValues(alpha: 0.1),
                                            pressedColor: Theme.of(context).hintColor.withValues(alpha: 0.25),
                                            iconColor: Theme.of(context).textTheme.bodyLarge!.color,
                                          ),
                                          const SizedBox(width: Dimensions.paddingSizeDefault),
                                          // Title
                                          Expanded(
                                            child: Text(
                                              'notification'.tr,
                                              style: robotoBold.copyWith(
                                                fontSize: Dimensions.fontSizeLarge,
                                                color: Theme.of(context).textTheme.bodyLarge!.color,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          const SizedBox(width: 52), // Balance the back button width
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              body: const NotificationContentWidget(),
                            ),
                          ),
                          size: 48,
                          iconSize: 24,
                          backgroundColor: Theme.of(context).hintColor.withValues(alpha: 0.1),
                          pressedColor: Theme.of(context).hintColor.withValues(alpha: 0.25),
                          iconColor: Theme.of(context).textTheme.bodyLarge!.color,
                        ),
                        if (notificationController.hasNotification)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              height: 12,
                              width: 12,
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
                ),

                const SizedBox(width: Dimensions.paddingSizeSmall),

                // Cart Button
                GetBuilder<CartController>(
                  builder: (cartController) {
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        RoundedIconButtonWidget(
                          icon: Icons.shopping_bag_outlined,
                          onPressed: () => RouteHelper.showCartModal(context),
                          size: 48,
                          iconSize: 24,
                          backgroundColor: Theme.of(context).hintColor.withValues(alpha: 0.1),
                          pressedColor: Theme.of(context).hintColor.withValues(alpha: 0.25),
                          iconColor: Theme.of(context).textTheme.bodyLarge!.color,
                        ),
                        if (cartController.cartList.isNotEmpty)
                          Positioned(
                            top: -2,
                            right: -2,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 20,
                                minHeight: 20,
                              ),
                              child: Text(
                                '${cartController.cartList.length}',
                                style: robotoMedium.copyWith(
                                  fontSize: 11,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLocationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BounceWrapper(
        child: LocationSelectionSheet(
        onUseCurrentLocation: () {
          _checkPermission(context, () {
            Get.back();
            Get.find<LocationController>().getCurrentLocation(true);
          });
        },
        onLocationSelected: (address) {
          Get.back();
          AddressHelper.saveAddressInSharedPref(address);
          Get.find<LocationController>().updatePosition(
            CameraPosition(
              target: LatLng(
                double.parse(address.latitude ?? '0'),
                double.parse(address.longitude ?? '0'),
              ),
              zoom: 16,
            ),
            true,
          );
        },
        onAddNewLocation: () {
          Get.back();
          CustomFullSheet.show(
            context: context,
            child: const PickMapScreen(
              fromSignUp: false,
              fromSplash: false,
              fromAddAddress: false,
              canRoute: false,
              route: 'home',
            ),
          );
        },
      ),
      ),
    );
  }

  void _checkPermission(BuildContext context, Function onTap) async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      Get.snackbar('Permission Required', 'Location permission is required to use this feature');
    } else if (permission == LocationPermission.deniedForever) {
      Get.dialog(const PermissionDialog());
    } else {
      onTap();
    }
  }

  /// Wrapper widget that adds bounce animation to bottom sheet
  Widget _BounceWrapper({required Widget child}) {
    return _BounceWrapperWidget(child: child);
  }
}

class _BounceWrapperWidget extends StatefulWidget {
  final Widget child;

  const _BounceWrapperWidget({required this.child});

  @override
  State<_BounceWrapperWidget> createState() => _BounceWrapperWidgetState();
}

class _BounceWrapperWidgetState extends State<_BounceWrapperWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(_animation),
      child: widget.child,
    );
  }
}
