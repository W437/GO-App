import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/features/checkout/controllers/checkout_controller.dart';
import 'package:godelivery_user/features/checkout/widgets/time_slot_bottom_sheet.dart';
import 'package:godelivery_user/util/styles.dart';

class WhenSection extends StatelessWidget {
  final CheckoutController checkoutController;
  final bool todayClosed;
  final bool tomorrowClosed;

  const WhenSection({
    super.key,
    required this.checkoutController,
    required this.todayClosed,
    required this.tomorrowClosed,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CheckoutController>(
      builder: (controller) {
        final isScheduled = controller.selectedDateSlot != 0 || controller.selectedTimeSlot != 0;
        final preferenceTime = controller.preferableTime;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'when'.tr,
                style: robotoBold.copyWith(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),

              // Standard option
              _buildWhenOption(
                isSelected: !isScheduled,
                title: 'standard'.tr,
                subtitle: _getStandardETA(controller),
                onTap: () {
                  controller.updateDateSlotIndex(0);
                  controller.updateTimeSlot(0, false);
                },
              ),

              const SizedBox(height: 10),

              // Schedule option
              _buildWhenOption(
                isSelected: isScheduled,
                title: 'schedule'.tr,
                subtitle: isScheduled && preferenceTime.isNotEmpty
                    ? preferenceTime
                    : 'choose_a_delivery_time'.tr,
                onTap: () {
                  _showTimeSlotSheet(context, controller);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWhenOption({
    required bool isSelected,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF00A8FF)
                : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF00A8FF)
                      : Colors.white.withOpacity(0.3),
                  width: 2,
                ),
                color: isSelected
                    ? const Color(0xFF00A8FF)
                    : Colors.transparent,
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(
                        Icons.check,
                        size: 12,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
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
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: robotoRegular.copyWith(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStandardETA(CheckoutController controller) {
    // Calculate ETA based on delivery time or use a default
    final deliveryTime = controller.restaurant?.deliveryTime;
    if (deliveryTime != null && deliveryTime.isNotEmpty) {
      return '$deliveryTime ${'min'.tr}';
    }
    return '30–40 ${'min'.tr}';
  }

  void _showTimeSlotSheet(BuildContext context, CheckoutController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TimeSlotBottomSheet(
        tomorrowClosed: tomorrowClosed,
        todayClosed: todayClosed,
        restaurant: controller.restaurant!,
      ),
    );
  }
}
