import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/features/checkout/controllers/checkout_controller.dart';
import 'package:godelivery_user/features/location/controllers/location_controller.dart';
import 'package:godelivery_user/helper/business_logic/address_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:godelivery_user/features/splash/controllers/splash_controller.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';

class CheckoutMapHeader extends StatelessWidget {
  final CheckoutController checkoutController;
  final LocationController locationController;

  const CheckoutMapHeader({
    super.key,
    required this.checkoutController,
    required this.locationController,
  });

  @override
  Widget build(BuildContext context) {
    final address = AddressHelper.getAddressFromSharedPref();
    final homeDeliveryAvailable = Get.find<SplashController>().configModel?.homeDelivery ?? false;
    final takeAwayAvailable = Get.find<SplashController>().configModel?.takeAway ?? false;
    final dineInAvailable = checkoutController.restaurant?.isDineInActive ?? false;

    return GetBuilder<CheckoutController>(
      builder: (controller) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Map placeholder with gradient overlay
              Stack(
                children: [
                  Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.location_on,
                        size: 48,
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                  ),
                  // Bottom gradient overlay
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 80,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            const Color(0xFF1A1A1A).withOpacity(0.9),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Order type tabs
              if (homeDeliveryAvailable || takeAwayAvailable || dineInAvailable)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: _buildOrderTypeTabs(controller, homeDeliveryAvailable, takeAwayAvailable, dineInAvailable),
                ),

              // Quick action rows
              _buildQuickActionRow(
                icon: Icons.location_on_outlined,
                title: address?.addressType ?? 'choose_delivery_address'.tr,
                subtitle: address?.address ?? '',
                showChevron: true,
                onTap: () {
                  Get.toNamed(RouteHelper.getAddAddressRoute(
                    true,
                    false,
                    checkoutController.restaurant?.zoneId ?? 0,
                  ));
                },
              ),

              _buildDivider(),

              _buildQuickActionRow(
                icon: Icons.door_front_door_outlined,
                title: 'leave_order_at_the_door'.tr,
                subtitle: '',
                hasToggle: true,
                toggleValue: controller.selectedInstruction == 0,
                onToggle: (value) {
                  controller.setInstruction(value ? 0 : -1);
                },
              ),

              _buildDivider(),

              _buildQuickActionRow(
                icon: Icons.card_giftcard_outlined,
                title: 'send_as_a_gift'.tr,
                subtitle: '',
                showChevron: true,
                onTap: () {
                  // Handle gift action
                },
              ),

              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrderTypeTabs(
    CheckoutController controller,
    bool homeDeliveryAvailable,
    bool takeAwayAvailable,
    bool dineInAvailable,
  ) {
    List<String> orderTypes = [];
    if (homeDeliveryAvailable) orderTypes.add('delivery');
    if (takeAwayAvailable) orderTypes.add('take_away');
    if (dineInAvailable) orderTypes.add('dine_in');

    if (orderTypes.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: orderTypes.map((type) {
          final isSelected = controller.orderType == type;
          return Expanded(
            child: GestureDetector(
              onTap: () => controller.setOrderType(type, notify: true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF2A2A2A) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getOrderTypeLabel(type),
                  textAlign: TextAlign.center,
                  style: robotoMedium.copyWith(
                    fontSize: 14,
                    color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getOrderTypeLabel(String type) {
    switch (type) {
      case 'delivery':
        return 'delivery'.tr;
      case 'take_away':
        return 'pickup'.tr;
      case 'dine_in':
        return 'dine_in'.tr;
      default:
        return type;
    }
  }

  Widget _buildQuickActionRow({
    required IconData icon,
    required String title,
    required String subtitle,
    bool showChevron = false,
    bool hasToggle = false,
    bool toggleValue = false,
    VoidCallback? onTap,
    ValueChanged<bool>? onToggle,
  }) {
    return InkWell(
      onTap: hasToggle ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: Colors.white.withOpacity(0.7),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: robotoMedium.copyWith(
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: robotoRegular.copyWith(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.5),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (showChevron)
              Icon(
                Icons.chevron_right,
                size: 20,
                color: Colors.white.withOpacity(0.3),
              ),
            if (hasToggle)
              Switch(
                value: toggleValue,
                onChanged: onToggle,
                activeColor: const Color(0xFF00A8FF),
                inactiveThumbColor: Colors.white.withOpacity(0.3),
                inactiveTrackColor: Colors.white.withOpacity(0.1),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 52),
      child: Container(
        height: 1,
        color: Colors.white.withOpacity(0.08),
      ),
    );
  }
}
