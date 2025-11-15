import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/common/widgets/shared/buttons/custom_button_widget.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:lottie/lottie.dart';

class LocationPermissionOverlay extends StatelessWidget {
  final VoidCallback onEnableLocation;
  final VoidCallback? onSkip;
  final bool showSkip;

  const LocationPermissionOverlay({
    super.key,
    required this.onEnableLocation,
    this.onSkip,
    this.showSkip = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Theme.of(context).cardColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeExtraLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Lottie animation
              Lottie.asset(
                'assets/animations/location_permission_lottie.json',
                height: 200,
                width: 200,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback to icon if animation not found
                  return Container(
                    height: 200,
                    width: 200,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.location_on_outlined,
                      size: 100,
                      color: Theme.of(context).primaryColor,
                    ),
                  );
                },
              ),

              const SizedBox(height: Dimensions.paddingSizeExtraLarge),

              // Title
              Text(
                'enable_location_access'.tr,
                style: robotoBold.copyWith(
                  fontSize: 28,
                  color: Theme.of(context).primaryColor,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: Dimensions.paddingSizeDefault),

              // Description
              Text(
                'location_permission_description'.tr,
                style: robotoRegular.copyWith(
                  fontSize: Dimensions.fontSizeDefault,
                  color: Theme.of(context).hintColor,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: Dimensions.paddingSizeSmall),

              // Benefits list
              _buildBenefitItem(
                context,
                Icons.restaurant_outlined,
                'find_nearby_restaurants'.tr,
              ),
              const SizedBox(height: Dimensions.paddingSizeExtraSmall),
              _buildBenefitItem(
                context,
                Icons.directions_bike_outlined,
                'track_delivery_realtime'.tr,
              ),
              const SizedBox(height: Dimensions.paddingSizeExtraSmall),
              _buildBenefitItem(
                context,
                Icons.location_on_outlined,
                'save_delivery_addresses'.tr,
              ),

              const Spacer(),

              // Enable Location button
              CustomButtonWidget(
                buttonText: 'enable_location'.tr,
                icon: Icons.location_on,
                onPressed: onEnableLocation,
              ),

              if (showSkip) ...[
                const SizedBox(height: Dimensions.paddingSizeSmall),
                TextButton(
                  onPressed: onSkip,
                  child: Text(
                    'skip_for_now'.tr,
                    style: robotoMedium.copyWith(
                      fontSize: Dimensions.fontSizeDefault,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitItem(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        Expanded(
          child: Text(
            text,
            style: robotoRegular.copyWith(
              fontSize: Dimensions.fontSizeDefault,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ),
      ],
    );
  }
}
