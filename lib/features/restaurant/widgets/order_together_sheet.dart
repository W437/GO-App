import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/common/models/restaurant_model.dart';
import 'package:godelivery_user/common/widgets/shared/sheets/custom_sheet.dart';
import 'package:godelivery_user/common/widgets/shared/buttons/custom_button_widget.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';

/// Order Together feature sheet - Coming Soon
/// Shows a preview of group ordering functionality
class OrderTogetherSheet extends StatefulWidget {
  final Restaurant restaurant;

  const OrderTogetherSheet({
    super.key,
    required this.restaurant,
  });

  @override
  State<OrderTogetherSheet> createState() => _OrderTogetherSheetState();
}

class _OrderTogetherSheetState extends State<OrderTogetherSheet> {
  final TextEditingController _groupNameController = TextEditingController(text: 'My Group');
  bool _isDelivery = true;
  String _selectedEmoji = '🍔';

  final List<String> _foodEmojis = ['🍔', '🍗', '🍕', '🍣', '🥪', '🥗'];

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(Dimensions.radiusExtraLarge),
        ),
      ),
      child: Stack(
        children: [
          // Main Content
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              Dimensions.paddingSizeLarge,
              Dimensions.paddingSizeSmall, // Less top padding since handle is above
              Dimensions.paddingSizeLarge,
              Dimensions.paddingSizeLarge,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Close Button (top left)
                Align(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    onTap: () => Get.back(),
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                      ),
                      child: Icon(
                        Icons.close,
                        size: 24,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeDefault),

                // Coming Soon Badge
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeDefault,
                      vertical: Dimensions.paddingSizeExtraSmall,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star_outline,
                          size: 16,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'COMING SOON',
                          style: robotoMedium.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            color: Theme.of(context).primaryColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeDefault),

                // Restaurant Name
                Text(
                  widget.restaurant.name?.toUpperCase() ?? '',
                  style: robotoMedium.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    color: Theme.of(context).hintColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                // Title
                Text(
                  'Order together',
                  style: robotoBold.copyWith(
                    fontSize: 32,
                    color: Theme.of(context).textTheme.bodyLarge!.color,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeLarge),

                // Group Name Section
                Container(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                  decoration: BoxDecoration(
                    color: Theme.of(context).disabledColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    border: Border.all(
                      color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Emoji Selector
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                            ),
                            child: Center(
                              child: Text(
                                _selectedEmoji,
                                style: const TextStyle(fontSize: 28),
                              ),
                            ),
                          ),
                          const SizedBox(width: Dimensions.paddingSizeDefault),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Group name',
                                  style: robotoRegular.copyWith(
                                    fontSize: Dimensions.fontSizeSmall,
                                    color: Theme.of(context).hintColor,
                                  ),
                                ),
                                TextField(
                                  controller: _groupNameController,
                                  style: robotoBold.copyWith(
                                    fontSize: Dimensions.fontSizeLarge,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Dimensions.paddingSizeDefault),

                      // Emoji Picker Row
                      SizedBox(
                        height: 56,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _foodEmojis.length,
                          separatorBuilder: (_, __) => const SizedBox(width: Dimensions.paddingSizeSmall),
                          itemBuilder: (context, index) {
                            final emoji = _foodEmojis[index];
                            final isSelected = emoji == _selectedEmoji;
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedEmoji = emoji;
                                });
                              },
                              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: isSelected
                                    ? Theme.of(context).primaryColor.withValues(alpha: 0.15)
                                    : Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                  border: Border.all(
                                    color: isSelected
                                      ? Theme.of(context).primaryColor
                                      : Theme.of(context).disabledColor.withValues(alpha: 0.2),
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    emoji,
                                    style: const TextStyle(fontSize: 28),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeLarge),

                // Delivery/Pickup Toggle
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: Theme.of(context).disabledColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _isDelivery = true;
                            });
                          },
                          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _isDelivery
                                ? Theme.of(context).cardColor
                                : Colors.transparent,
                              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                              boxShadow: _isDelivery ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ] : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.delivery_dining,
                                  color: _isDelivery
                                    ? Theme.of(context).primaryColor
                                    : Theme.of(context).hintColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Delivery',
                                  style: robotoMedium.copyWith(
                                    color: _isDelivery
                                      ? Theme.of(context).textTheme.bodyLarge!.color
                                      : Theme.of(context).hintColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _isDelivery = false;
                            });
                          },
                          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                          child: Container(
                            decoration: BoxDecoration(
                              color: !_isDelivery
                                ? Theme.of(context).cardColor
                                : Colors.transparent,
                              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                              boxShadow: !_isDelivery ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ] : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.shopping_bag_outlined,
                                  color: !_isDelivery
                                    ? Theme.of(context).primaryColor
                                    : Theme.of(context).hintColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Pickup',
                                  style: robotoMedium.copyWith(
                                    color: !_isDelivery
                                      ? Theme.of(context).textTheme.bodyLarge!.color
                                      : Theme.of(context).hintColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeLarge),

                // Where Section
                Text(
                  'Where?',
                  style: robotoBold.copyWith(
                    fontSize: Dimensions.fontSizeExtraLarge,
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeDefault),

                // Address Options (Static for now)
                _buildAddressOption(
                  context,
                  icon: Icons.location_on,
                  title: 'Current Location',
                  subtitle: 'Detecting...',
                  isSelected: true,
                ),
                const SizedBox(height: Dimensions.paddingSizeSmall),
                _buildAddressOption(
                  context,
                  icon: Icons.home_outlined,
                  title: 'Home',
                  subtitle: 'Set your home address',
                  isSelected: false,
                ),
                const SizedBox(height: Dimensions.paddingSizeSmall),
                _buildAddressOption(
                  context,
                  icon: Icons.work_outline,
                  title: 'Work',
                  subtitle: 'Set your work address',
                  isSelected: false,
                ),

                const SizedBox(height: Dimensions.paddingSizeLarge),

                // When Section
                Text(
                  'When?',
                  style: robotoBold.copyWith(
                    fontSize: Dimensions.fontSizeExtraLarge,
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeDefault),

                Container(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                  decoration: BoxDecoration(
                    color: Theme.of(context).disabledColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    border: Border.all(
                      color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: Theme.of(context).primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: Dimensions.paddingSizeDefault),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Schedule for later',
                              style: robotoMedium.copyWith(
                                fontSize: Dimensions.fontSizeDefault,
                              ),
                            ),
                            Text(
                              'Choose delivery time',
                              style: robotoRegular.copyWith(
                                fontSize: Dimensions.fontSizeSmall,
                                color: Theme.of(context).hintColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down,
                        color: Theme.of(context).hintColor,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 120), // Space for bottom button
              ],
            ),
          ),

          // Bottom Button with gradient fade
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.0),
                    Colors.white.withValues(alpha: 0.8),
                    Colors.white,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
              child: SafeArea(
                child: CustomButtonWidget(
                  buttonText: 'Order together',
                  onPressed: null, // Disabled - coming soon
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
  }) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: isSelected
          ? Theme.of(context).primaryColor.withValues(alpha: 0.05)
          : Theme.of(context).disabledColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        border: Border.all(
          color: isSelected
            ? Theme.of(context).primaryColor
            : Theme.of(context).disabledColor.withValues(alpha: 0.1),
          width: isSelected ? 2 : 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                ? Theme.of(context).primaryColor.withValues(alpha: 0.15)
                : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            ),
            child: Icon(
              icon,
              color: isSelected
                ? Theme.of(context).primaryColor
                : Theme.of(context).hintColor,
              size: 24,
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeDefault),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: robotoMedium.copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                    color: isSelected
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).textTheme.bodyLarge!.color,
                  ),
                ),
                Text(
                  subtitle,
                  style: robotoRegular.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ],
            ),
          ),
          if (isSelected)
            Icon(
              Icons.check_circle,
              color: Theme.of(context).primaryColor,
              size: 24,
            ),
        ],
      ),
    );
  }
}
