import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/features/explore/controllers/explore_controller.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';

class AdvancedFilterSheet extends StatefulWidget {
  const AdvancedFilterSheet({super.key});

  @override
  State<AdvancedFilterSheet> createState() => _AdvancedFilterSheetState();
}

class _AdvancedFilterSheetState extends State<AdvancedFilterSheet> {
  late double _minRating;
  late RangeValues _priceRange;
  late double _maxDeliveryFee;

  @override
  void initState() {
    super.initState();
    final controller = Get.find<ExploreController>();
    _minRating = controller.minRatingFilter;
    _priceRange = RangeValues(
      controller.minPriceFilter.toDouble(),
      controller.maxPriceFilter.toDouble(),
    );
    _maxDeliveryFee = controller.maxDeliveryFeeFilter;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(Dimensions.radiusExtraLarge),
          topRight: Radius.circular(Dimensions.radiusExtraLarge),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).disabledColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeLarge,
                vertical: Dimensions.paddingSizeSmall,
              ),
              child: Row(
                children: [
                  Text(
                    'sort_and_filter'.tr,
                    style: robotoBold.copyWith(
                      fontSize: Dimensions.fontSizeLarge,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _minRating = 0;
                        _priceRange = const RangeValues(1, 4);
                        _maxDeliveryFee = 20;
                      });
                      Get.find<ExploreController>().setSortOption(SortOption.distance);
                    },
                    child: Text(
                      'reset'.tr,
                      style: robotoMedium.copyWith(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sort By Section
                    _buildSectionTitle('sort_by'.tr),
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                    GetBuilder<ExploreController>(
                      builder: (controller) {
                        return Wrap(
                          spacing: Dimensions.paddingSizeSmall,
                          runSpacing: Dimensions.paddingSizeSmall,
                          children: SortOption.values.map((option) {
                            final isSelected = controller.currentSortOption == option;
                            return InkWell(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                controller.setSortOption(option);
                              },
                              borderRadius: BorderRadius.circular(100),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: Dimensions.paddingSizeDefault,
                                  vertical: Dimensions.paddingSizeSmall,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Theme.of(context).primaryColor
                                      : Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(
                                    color: isSelected
                                        ? Theme.of(context).primaryColor
                                        : Theme.of(context).disabledColor.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      option.icon,
                                      size: 16,
                                      color: isSelected
                                          ? Colors.white
                                          : Theme.of(context).textTheme.bodyMedium!.color,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      option.displayName,
                                      style: robotoMedium.copyWith(
                                        fontSize: Dimensions.fontSizeSmall,
                                        color: isSelected
                                            ? Colors.white
                                            : Theme.of(context).textTheme.bodyMedium!.color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),

                    const SizedBox(height: Dimensions.paddingSizeLarge),
                    const Divider(height: 1),
                    const SizedBox(height: Dimensions.paddingSizeLarge),

                    // Minimum Rating
                    _buildSectionTitle('minimum_rating'.tr),
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: _minRating,
                            min: 0,
                            max: 5,
                            divisions: 10,
                            label: _minRating == 0 ? 'any'.tr : _minRating.toStringAsFixed(1),
                            onChanged: (value) {
                              HapticFeedback.selectionClick();
                              setState(() => _minRating = value);
                            },
                            activeColor: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(width: Dimensions.paddingSizeSmall),
                        Container(
                          width: 60,
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star,
                                size: 16,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _minRating == 0 ? 'any'.tr : _minRating.toStringAsFixed(1),
                                style: robotoBold.copyWith(
                                  fontSize: Dimensions.fontSizeDefault,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: Dimensions.paddingSizeLarge),

                    // Price Range
                    _buildSectionTitle('price_range'.tr),
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                    Row(
                      children: [
                        Expanded(
                          child: RangeSlider(
                            values: _priceRange,
                            min: 1,
                            max: 4,
                            divisions: 3,
                            labels: RangeLabels(
                              _getPriceLabel(_priceRange.start.toInt()),
                              _getPriceLabel(_priceRange.end.toInt()),
                            ),
                            onChanged: (values) {
                              HapticFeedback.selectionClick();
                              setState(() => _priceRange = values);
                            },
                            activeColor: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(width: Dimensions.paddingSizeSmall),
                        Container(
                          width: 80,
                          alignment: Alignment.center,
                          child: Text(
                            '${_getPriceLabel(_priceRange.start.toInt())} - ${_getPriceLabel(_priceRange.end.toInt())}',
                            style: robotoBold.copyWith(
                              fontSize: Dimensions.fontSizeDefault,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: Dimensions.paddingSizeLarge),

                    // Maximum Delivery Fee
                    _buildSectionTitle('max_delivery_fee'.tr),
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: _maxDeliveryFee,
                            min: 0,
                            max: 20,
                            divisions: 20,
                            label: _maxDeliveryFee == 0
                                ? 'free_only'.tr
                                : '\$${_maxDeliveryFee.toStringAsFixed(0)}',
                            onChanged: (value) {
                              HapticFeedback.selectionClick();
                              setState(() => _maxDeliveryFee = value);
                            },
                            activeColor: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(width: Dimensions.paddingSizeSmall),
                        Container(
                          width: 60,
                          alignment: Alignment.center,
                          child: Text(
                            _maxDeliveryFee == 0
                                ? 'FREE'
                                : '\$${_maxDeliveryFee.toStringAsFixed(0)}',
                            style: robotoBold.copyWith(
                              fontSize: Dimensions.fontSizeDefault,
                              color: _maxDeliveryFee == 0
                                  ? Colors.green
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Apply Button
            Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    final controller = Get.find<ExploreController>();
                    controller.setAdvancedFilters(
                      minRating: _minRating,
                      minPrice: _priceRange.start.toInt(),
                      maxPrice: _priceRange.end.toInt(),
                      maxDeliveryFee: _maxDeliveryFee,
                    );
                    Get.back();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(
                      vertical: Dimensions.paddingSizeDefault,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    ),
                  ),
                  child: Text(
                    'apply_filters'.tr,
                    style: robotoBold.copyWith(
                      color: Colors.white,
                      fontSize: Dimensions.fontSizeDefault,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: robotoBold.copyWith(
        fontSize: Dimensions.fontSizeDefault,
        color: Theme.of(context).textTheme.bodyMedium!.color,
      ),
    );
  }

  String _getPriceLabel(int value) {
    return '\$' * value;
  }
}
