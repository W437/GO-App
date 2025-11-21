import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/common/models/restaurant_model.dart';
import 'package:godelivery_user/features/restaurant/controllers/restaurant_controller.dart';
import 'package:godelivery_user/helper/converters/price_converter.dart';
import 'package:godelivery_user/helper/ui/responsive_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/images.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:godelivery_user/features/home/widgets/blurhash_image_widget.dart';
import 'package:godelivery_user/features/checkout/controllers/checkout_controller.dart';
import 'package:godelivery_user/features/restaurant/widgets/order_details_bottom_sheet.dart';
import 'package:godelivery_user/features/auth/controllers/auth_controller.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';

class RestaurantDetailsSectionWidget extends StatelessWidget {
  final Restaurant restaurant;
  final RestaurantController restController;
  const RestaurantDetailsSectionWidget({
    super.key,
    required this.restaurant,
    required this.restController,
  });

  @override
  Widget build(BuildContext context) {
    bool isDesktop = ResponsiveHelper.isDesktop(context);

    return SliverToBoxAdapter(
      child: Transform.translate(
        offset: const Offset(0, -40), // Move up to overlay cover
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 24,
                  spreadRadius: 0,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            padding: const EdgeInsets.only(top: 75, left: Dimensions.paddingSizeDefault, right: Dimensions.paddingSizeDefault),
            child: Column(
                children: [
                  // Restaurant Name
                  Text(
                    restaurant.name ?? '',
                    style: robotoBold.copyWith(
                      fontSize: 24,
                      color: Theme.of(context).textTheme.bodyLarge!.color,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: Dimensions.paddingSizeSmall),

                  // Stats Row: Rating - Closing Time - Min Order
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sentiment_satisfied_alt, color: Theme.of(context).hintColor, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '${restaurant.avgRating?.toStringAsFixed(1) ?? '0.0'}',
                        style: robotoRegular.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeSmall),
                      ),
                      const SizedBox(width: 8),
                      Text('•', style: robotoRegular.copyWith(color: Theme.of(context).hintColor)),
                      const SizedBox(width: 8),
                      Text(
                        'Closes at ${restaurant.schedules != null && restaurant.schedules!.isNotEmpty ? restaurant.schedules![0].closingTime : 'N/A'}', // Simplified logic
                        style: robotoRegular.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeSmall),
                      ),
                      const SizedBox(width: 8),
                      Text('•', style: robotoRegular.copyWith(color: Theme.of(context).hintColor)),
                      const SizedBox(width: 8),
                      Text(
                        'Min. order ${PriceConverter.convertPrice(restaurant.minimumOrder)}',
                        style: robotoRegular.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeSmall),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Delivery Fee Row
                  if (restaurant.deliveryFee != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delivery_dining, color: Theme.of(context).hintColor, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          PriceConverter.convertPrice(restaurant.deliveryFee),
                          style: robotoRegular.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeSmall),
                        ),
                      ],
                    ),
                  const SizedBox(height: Dimensions.paddingSizeExtraLarge),
                  // Action Buttons
                  Row(
                    children: [
                      // Delivery Time Button
                      Expanded(
                        flex: 2,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                          onTap: () async {
                            final authController = Get.find<AuthController>();
                            // If no session, redirect to sign-in before showing scheduling UI
                            if (!authController.isLoggedIn() && !authController.isGuestLoggedIn()) {
                              Get.toNamed(RouteHelper.getSignInRoute('restaurant'));
                              return;
                            }

                            // Reset any previous schedule preference before opening
                            Get.find<CheckoutController>().setPreselectedScheduleAt(null, notify: false);
                            if (context.mounted) {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => OrderDetailsBottomSheet(restaurant: restaurant),
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.pedal_bike, color: Theme.of(context).primaryColor, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Delivery ${restaurant.deliveryTime ?? '30-40'} min',
                                  style: robotoMedium.copyWith(color: Theme.of(context).primaryColor),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.keyboard_arrow_down, color: Theme.of(context).primaryColor, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: Dimensions.paddingSizeSmall),
                      
                      // Group Order Button
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                        ),
                        child: Icon(Icons.group_add_outlined, color: Theme.of(context).primaryColor, size: 24),
                      ),
                      const SizedBox(width: Dimensions.paddingSizeSmall),

                      // Details Button
                      InkWell(
                        onTap: () {
                          Get.toNamed(RouteHelper.getRestaurantDetailsRoute(restaurant));
                        },
                        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                          ),
                          child: Icon(Icons.info_outline, color: Theme.of(context).primaryColor, size: 24),
                        ),
                      ),
                      const SizedBox(width: Dimensions.paddingSizeSmall),

                      // Share Button
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                        ),
                        child: Icon(Icons.ios_share, color: Theme.of(context).primaryColor, size: 24),
                      ),
                    ],
                  ),
                  const SizedBox(height: Dimensions.paddingSizeLarge),
          ],
        ),
          ),
        ),
      ),
    );

  }
}
