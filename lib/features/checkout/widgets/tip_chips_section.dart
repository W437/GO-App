import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/features/checkout/controllers/checkout_controller.dart';
import 'package:godelivery_user/util/app_constants.dart';
import 'package:godelivery_user/util/styles.dart';

class TipChipsSection extends StatelessWidget {
  final CheckoutController checkoutController;

  const TipChipsSection({
    super.key,
    required this.checkoutController,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CheckoutController>(
      builder: (controller) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'add_courier_tip'.tr,
              style: robotoBold.copyWith(
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'the_entire_amount_will_go_to_your_courier'.tr,
              style: robotoRegular.copyWith(
                fontSize: 13,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 12),

            // Tip chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(
                AppConstants.tips.length,
                (index) {
                  final isSelected = controller.selectedTips == index + 1;
                  final tipAmount = AppConstants.tips[index];

                  return GestureDetector(
                    onTap: () {
                      controller.updateTips(index + 1);
                      controller.tipController.text = tipAmount;
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF00A8FF)
                            : const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF00A8FF)
                              : Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '\$$tipAmount',
                        style: robotoMedium.copyWith(
                          fontSize: 14,
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ),
                  );
                },
              )..add(
                  // Custom tip chip
                  GestureDetector(
                    onTap: () => _showCustomTipDialog(context, controller),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: controller.selectedTips == 0 && controller.tips > 0
                            ? const Color(0xFF00A8FF)
                            : const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: controller.selectedTips == 0 && controller.tips > 0
                              ? const Color(0xFF00A8FF)
                              : Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            controller.selectedTips == 0 && controller.tips > 0
                                ? '\$${controller.tips.toStringAsFixed(2)}'
                                : 'custom'.tr,
                            style: robotoMedium.copyWith(
                              fontSize: 14,
                              color: controller.selectedTips == 0 && controller.tips > 0
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.edit,
                            size: 16,
                            color: controller.selectedTips == 0 && controller.tips > 0
                                ? Colors.white
                                : Colors.white.withOpacity(0.7),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ),

            // No tip option
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                controller.updateTips(0);
                controller.tipController.text = '';
              },
              child: Text(
                'no_tip'.tr,
                style: robotoMedium.copyWith(
                  fontSize: 14,
                  color: controller.selectedTips == 0 && controller.tips == 0
                      ? const Color(0xFF00A8FF)
                      : Colors.white.withOpacity(0.5),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showCustomTipDialog(BuildContext context, CheckoutController controller) {
    final customTipController = TextEditingController(
      text: controller.selectedTips == 0 && controller.tips > 0
          ? controller.tips.toString()
          : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'custom_tip'.tr,
          style: robotoBold.copyWith(
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        content: TextField(
          controller: customTipController,
          keyboardType: TextInputType.number,
          style: robotoRegular.copyWith(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'enter_amount'.tr,
            hintStyle: robotoRegular.copyWith(
              color: Colors.white.withOpacity(0.5),
            ),
            prefixText: '\$ ',
            prefixStyle: robotoMedium.copyWith(color: Colors.white),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFF00A8FF),
                width: 2,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'cancel'.tr,
              style: robotoMedium.copyWith(
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              final amount = double.tryParse(customTipController.text) ?? 0;
              if (amount > 0) {
                controller.updateTips(0);
                controller.tipController.text = amount.toString();
                controller.addTips(amount);
              }
              Navigator.pop(ctx);
            },
            child: Text(
              'apply'.tr,
              style: robotoMedium.copyWith(
                color: const Color(0xFF00A8FF),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
