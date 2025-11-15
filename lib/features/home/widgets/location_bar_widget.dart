import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/common/widgets/shared/buttons/rounded_icon_button_widget.dart';
import 'package:godelivery_user/features/cart/controllers/cart_controller.dart';
import 'package:godelivery_user/features/location/controllers/location_controller.dart';
import 'package:godelivery_user/features/location/widgets/location_selection_sheet.dart';
import 'package:godelivery_user/features/location/widgets/permission_dialog.dart';
import 'package:godelivery_user/features/notification/controllers/notification_controller.dart';
import 'package:godelivery_user/helper/business_logic/address_helper.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Compact location bar widget for home screen content
class LocationBarWidget extends StatelessWidget {
  const LocationBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Dimensions.paddingSizeDefault,
            Dimensions.paddingSizeDefault,
            Dimensions.paddingSizeDefault,
            Dimensions.paddingSizeDefault,
          ),
          child: _buildContent(context),
        ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Row(
      children: [
          // Location selector
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
                        size: 24,
                      ),
                      const SizedBox(width: Dimensions.paddingSizeSmall),
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Expanded(
                              child: _MarqueeText(
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
                );
              },
            ),
          ),

          const SizedBox(width: Dimensions.paddingSizeSmall),

          // Notification Button
          GetBuilder<NotificationController>(
            builder: (notificationController) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  RoundedIconButtonWidget(
                    icon: Icons.notifications_outlined,
                    onPressed: () => Get.toNamed(RouteHelper.getNotificationRoute()),
                    size: 40,
                    iconSize: 20,
                    backgroundColor: Theme.of(context).hintColor.withValues(alpha: 0.1),
                    pressedColor: Theme.of(context).hintColor.withValues(alpha: 0.25),
                    iconColor: Theme.of(context).textTheme.bodyLarge!.color,
                  ),
                  if (notificationController.hasNotification)
                    Positioned(
                      top: 0,
                      right: 0,
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
                    size: 40,
                    iconSize: 20,
                    backgroundColor: Theme.of(context).hintColor.withValues(alpha: 0.1),
                    pressedColor: Theme.of(context).hintColor.withValues(alpha: 0.25),
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
          ),
        ],
    );
  }

  void _showLocationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LocationSelectionSheet(
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
}

/// Simple marquee text widget with auto-scroll for long addresses
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

class _MarqueeTextState extends State<_MarqueeText> {
  late final ScrollController _scrollController;
  bool _shouldScroll = false;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void didUpdateWidget(_MarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      setState(() {
        _shouldScroll = false;
      });
      _resetScrolling();
    }
  }

  void _resetScrolling() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
    _isAnimating = false;
  }

  void _startScrolling() async {
    if (!mounted || !_shouldScroll || _isAnimating) return;
    _isAnimating = true;
    await Future.delayed(const Duration(milliseconds: 1000));

    while (mounted && _shouldScroll) {
      if (!_scrollController.hasClients) break;

      final duration = Duration(
        milliseconds: (widget.text.length * 60).clamp(3000, 8000),
      );

      await _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        curve: Curves.linear,
        duration: duration,
      );

      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted || !_shouldScroll) break;

      await _scrollController.animateTo(
        0,
        curve: Curves.linear,
        duration: duration,
      );

      await Future.delayed(const Duration(milliseconds: 800));
    }

    _isAnimating = false;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final direction = Directionality.of(context);
        final textPainter = TextPainter(
          text: TextSpan(text: widget.text, style: widget.style),
          maxLines: 1,
          textDirection: direction,
        )..layout(maxWidth: double.infinity);

        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        final needsScroll = textPainter.size.width > availableWidth;

        if (needsScroll != _shouldScroll) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            if (_shouldScroll == needsScroll) return;
            setState(() {
              _shouldScroll = needsScroll;
            });
            if (_shouldScroll) {
              _startScrolling();
            } else {
              _resetScrolling();
            }
          });
        }

        if (!_shouldScroll) {
          return Text(
            widget.text,
            style: widget.style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        }

        return ClipRect(
          child: ShaderMask(
            shaderCallback: (Rect bounds) {
              return const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.transparent,
                  Colors.black,
                  Colors.black,
                  Colors.transparent,
                ],
                stops: [0.0, 0.05, 0.95, 1.0],
              ).createShader(bounds);
            },
            blendMode: BlendMode.dstIn,
            child: SizedBox(
              width: availableWidth,
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
            ),
          ),
        );
      },
    );
  }
}
