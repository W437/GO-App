import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/features/explore/controllers/explore_controller.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';

class SearchBarWidget extends StatefulWidget {
  final ExploreController exploreController;

  const SearchBarWidget({
    super.key,
    required this.exploreController,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.exploreController.searchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // Start new timer with 500ms delay
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      widget.exploreController.searchRestaurants(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Search Icon
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeDefault,
            ),
            child: Icon(
              Icons.search,
              color: Theme.of(context).disabledColor,
              size: 20,
            ),
          ),

          // Search Input
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              onChanged: _onSearchChanged,
              style: robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeDefault,
              ),
              decoration: InputDecoration(
                hintText: 'search_restaurants_cuisines'.tr,
                hintStyle: robotoRegular.copyWith(
                  color: Theme.of(context).disabledColor,
                  fontSize: Dimensions.fontSizeDefault,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: Dimensions.paddingSizeDefault,
                ),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (value) {
                widget.exploreController.searchRestaurants(value);
              },
            ),
          ),

          // Clear Button
          GetBuilder<ExploreController>(
            builder: (controller) {
              if (controller.searchQuery.isEmpty) {
                return SizedBox(width: Dimensions.paddingSizeDefault);
              }
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () {
                      _searchController.clear();
                      controller.clearSearch();
                      _focusNode.unfocus();
                    },
                    icon: Icon(
                      Icons.clear,
                      color: Theme.of(context).disabledColor,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: Dimensions.paddingSizeSmall),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
