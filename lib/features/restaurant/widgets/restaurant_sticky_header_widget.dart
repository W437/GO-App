import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/common/widgets/adaptive/veg_filter_widget.dart';
import 'package:godelivery_user/features/restaurant/controllers/restaurant_controller.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:godelivery_user/helper/ui/responsive_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/images.dart';
import 'package:godelivery_user/util/styles.dart';

class RestaurantStickyHeaderWidget extends StatefulWidget {
  final RestaurantController restController;
  final TextEditingController searchController;
  
  const RestaurantStickyHeaderWidget({
    super.key, 
    required this.restController,
    required this.searchController,
  });

  @override
  State<RestaurantStickyHeaderWidget> createState() => _RestaurantStickyHeaderWidgetState();
}

class _RestaurantStickyHeaderWidgetState extends State<RestaurantStickyHeaderWidget> {
  bool _isSearchActive = false;

  @override
  Widget build(BuildContext context) {
    bool isDesktop = ResponsiveHelper.isDesktop(context);
    
    return Container(
      width: Dimensions.webMaxWidth,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: isDesktop ? [] : [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05), 
            spreadRadius: 1, 
            blurRadius: 5, 
            offset: const Offset(0, 1)
          )
        ],
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)))
      ),
      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          child: Row(children: [
          // Title
          if (!_isSearchActive || isDesktop)
            Expanded(
              child: Text(
                'all_food_items'.tr, 
                style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)
              ),
            ),

          // Search Icon (Hidden by default, uncomment if needed)
          // if (isDesktop) ...[
          //   _buildDesktopSearch(),
          // ] else ...[
          //   InkWell(
          //     onTap: () {
          //       if (_isSearchActive) {
          //          // ... existing search logic
          //       } else {
          //         setState(() => _isSearchActive = true);
          //       }
          //     },
          //     child: Padding(
          //       padding: const EdgeInsets.all(10),
          //       child: Icon(
          //         _isSearchActive ? Icons.search : CupertinoIcons.search,
          //         color: Theme.of(context).primaryColor,
          //         size: 20,
          //       ),
          //     ),
          //   ),
          // ],

          // Veg Filter
          if (!_isSearchActive) ...[
            const SizedBox(width: Dimensions.paddingSizeSmall),
            widget.restController.type.isNotEmpty ? VegFilterWidget(
              type: widget.restController.type,
              iconColor: Theme.of(context).primaryColor,
              onSelected: (String type) {
                widget.restController.getRestaurantProductList(widget.restController.restaurant!.id, 1, type, true);
              },
            ) : const SizedBox(),
          ]
        ]),
      ),
      const SizedBox(height: Dimensions.paddingSizeSmall),

      // Category Chips - Purple Style
      SizedBox(
        height: 36,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: widget.restController.categoryList!.length,
          padding: const EdgeInsets.only(left: Dimensions.paddingSizeDefault),
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, index) {
            bool isSelected = index == widget.restController.categoryIndex;
            return InkWell(
              onTap: () => widget.restController.setCategoryIndex(index),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeDefault,
                  vertical: Dimensions.paddingSizeSmall,
                ),
                margin: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: isSelected
                      ? Theme.of(context).primaryColor.withValues(alpha: 0.15)
                      : Theme.of(context).hintColor.withValues(alpha: 0.08),
                ),
                child: Center(
                  child: Text(
                    widget.restController.categoryList![index].name!,
                    style: robotoMedium.copyWith(
                      fontSize: Dimensions.fontSizeDefault,
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).hintColor,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      ]),
    );
  }

  Widget _buildDesktopSearch() {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
      height: 35, width: 320,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        color: Theme.of(context).cardColor,
        border: Border.all(color: Theme.of(context).primaryColor, width: 0.3),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: widget.searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                hintText: 'search_for_your_food'.tr,
                hintStyle: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(Dimensions.radiusSmall), borderSide: BorderSide.none),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                isDense: true,
                prefixIcon: InkWell(
                  onTap: () {
                    if (!widget.restController.isSearching) {
                      widget.restController.getRestaurantSearchProductList(
                        widget.searchController.text.trim(), Get.find<RestaurantController>().restaurant!.id.toString(), 1, widget.restController.type,
                      );
                    } else {
                      widget.searchController.text = '';
                      widget.restController.initSearchData();
                      widget.restController.changeSearchStatus();
                    }
                  },
                  child: Icon(widget.restController.isSearching ? Icons.clear : CupertinoIcons.search,
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.50)),
                ),
              ),
              onSubmitted: (String? value) {
                if (value!.isNotEmpty) {
                  widget.restController.getRestaurantSearchProductList(
                    widget.searchController.text.trim(), Get.find<RestaurantController>().restaurant!.id.toString(), 1, widget.restController.type,
                  );
                }
              },
              onChanged: (String? value) {},
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
        ],
      ),
    );
  }
}

