import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:godelivery_user/common/widgets/shared/buttons/rounded_icon_button_widget.dart';
import 'package:godelivery_user/features/location/controllers/location_controller.dart';
import 'package:godelivery_user/features/location/widgets/location_selection_sheet.dart';
import 'package:godelivery_user/features/location/widgets/permission_dialog.dart';
import 'package:godelivery_user/features/notification/controllers/notification_controller.dart';
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
            vertical: Dimensions.paddingSizeDefault,
          ),
          child: Row(
            children: [
              // Location Picker on the left
              Expanded(
                child: GetBuilder<LocationController>(
                  builder: (locationController) {
                    return InkWell(
                      onTap: () => _showLocationSheet(context),
                      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            color: Theme.of(context).primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: Dimensions.paddingSizeSmall),
                          SizedBox(
                            width: 150,
                            child: _MarqueeText(
                              text: AddressHelper.getAddressFromSharedPref()!.address!,
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
                            size: 18,
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
                        onPressed: () => Get.toNamed(RouteHelper.getNotificationRoute()),
                        size: 36,
                        iconSize: 20,
                        backgroundColor: Theme.of(context).hintColor.withValues(alpha: 0.1),
                        pressedColor: Theme.of(context).hintColor.withValues(alpha: 0.25),
                        iconColor: Theme.of(context).textTheme.bodyLarge!.color,
                      ),
                      if (notificationController.hasNotification)
                        Positioned(
                          top: -4,
                          right: -4,
                          child: Container(
                            height: 10,
                            width: 10,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(
                                width: 1.5,
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
                        onPressed: () => Get.toNamed(RouteHelper.getCartRoute()),
                        size: 36,
                        iconSize: 20,
                        backgroundColor: Theme.of(context).hintColor.withValues(alpha: 0.1),
                        pressedColor: Theme.of(context).hintColor.withValues(alpha: 0.25),
                        iconColor: Theme.of(context).textTheme.bodyLarge!.color,
                      ),
                      if (cartController.cartList.isNotEmpty)
                        Positioned(
                          top: -6,
                          right: -6,
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
              ),
            ],
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
          Get.toNamed(RouteHelper.getPickMapRoute('home', false));
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

/// Marquee text widget that auto-scrolls when text is too long
class _MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const _MarqueeText({
    required this.text,
    required this.style,
  });

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText> with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _animationController;
  bool _needsScrolling = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIfNeedsScrolling();
    });
  }

  void _checkIfNeedsScrolling() {
    if (_scrollController.hasClients && _scrollController.position.maxScrollExtent > 0) {
      setState(() {
        _needsScrolling = true;
      });
      _startScrolling();
    }
  }

  void _startScrolling() async {
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    while (mounted && _needsScrolling) {
      await _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(seconds: 4),
        curve: Curves.linear,
      );
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      await _scrollController.animateTo(
        0,
        duration: const Duration(seconds: 4),
        curve: Curves.linear,
      );
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.transparent,
            Colors.black,
            Colors.black,
            Colors.transparent,
          ],
          stops: const [0.0, 0.05, 0.95, 1.0],
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: _scrollController,
        physics: const NeverScrollableScrollPhysics(),
        child: Text(
          widget.text,
          style: widget.style,
          maxLines: 1,
        ),
      ),
    );
  }
}
