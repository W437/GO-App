import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';

enum EmptyStateType {
  noResults,
  noRestaurantsNearby,
  networkError,
}

class EmptyStateWidget extends StatelessWidget {
  final EmptyStateType type;
  final VoidCallback? onRetry;
  final VoidCallback? onClearFilters;

  const EmptyStateWidget({
    super.key,
    required this.type,
    this.onRetry,
    this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeOverLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildIllustration(context),
              const SizedBox(height: Dimensions.paddingSizeLarge),
              Text(
                _getTitle(),
                style: robotoBold.copyWith(
                  fontSize: Dimensions.fontSizeExtraLarge,
                  color: Theme.of(context).textTheme.bodyMedium!.color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              Text(
                _getDescription(),
                style: robotoRegular.copyWith(
                  fontSize: Dimensions.fontSizeDefault,
                  color: Theme.of(context).disabledColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Dimensions.paddingSizeLarge),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIllustration(BuildContext context) {
    IconData icon;
    Color color;

    switch (type) {
      case EmptyStateType.noResults:
        icon = Icons.search_off;
        color = Theme.of(context).primaryColor;
        break;
      case EmptyStateType.noRestaurantsNearby:
        icon = Icons.location_off;
        color = Colors.orange;
        break;
      case EmptyStateType.networkError:
        icon = Icons.wifi_off;
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeOverLarge),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 80,
        color: color,
      ),
    );
  }

  String _getTitle() {
    switch (type) {
      case EmptyStateType.noResults:
        return 'no_results_found'.tr;
      case EmptyStateType.noRestaurantsNearby:
        return 'no_restaurants_nearby'.tr;
      case EmptyStateType.networkError:
        return 'network_error'.tr;
    }
  }

  String _getDescription() {
    switch (type) {
      case EmptyStateType.noResults:
        return 'try_adjusting_filters_or_search'.tr;
      case EmptyStateType.noRestaurantsNearby:
        return 'try_adjusting_your_location'.tr;
      case EmptyStateType.networkError:
        return 'check_internet_connection'.tr;
    }
  }

  Widget _buildActionButtons(BuildContext context) {
    List<Widget> buttons = [];

    if (type == EmptyStateType.noResults && onClearFilters != null) {
      buttons.add(
        ElevatedButton.icon(
          onPressed: onClearFilters,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeLarge,
              vertical: Dimensions.paddingSizeDefault,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            ),
          ),
          icon: const Icon(Icons.clear_all, color: Colors.white),
          label: Text(
            'clear_all_filters'.tr,
            style: robotoMedium.copyWith(
              color: Colors.white,
              fontSize: Dimensions.fontSizeDefault,
            ),
          ),
        ),
      );
    }

    if (type == EmptyStateType.networkError && onRetry != null) {
      buttons.add(
        ElevatedButton.icon(
          onPressed: onRetry,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeLarge,
              vertical: Dimensions.paddingSizeDefault,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            ),
          ),
          icon: const Icon(Icons.refresh, color: Colors.white),
          label: Text(
            'retry'.tr,
            style: robotoMedium.copyWith(
              color: Colors.white,
              fontSize: Dimensions.fontSizeDefault,
            ),
          ),
        ),
      );
    }

    if (type == EmptyStateType.noRestaurantsNearby) {
      buttons.add(
        OutlinedButton.icon(
          onPressed: () {
            // Navigate to location picker
            Get.toNamed('/pick-location');
          },
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Theme.of(context).primaryColor),
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeLarge,
              vertical: Dimensions.paddingSizeDefault,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            ),
          ),
          icon: Icon(Icons.edit_location, color: Theme.of(context).primaryColor),
          label: Text(
            'change_location'.tr,
            style: robotoMedium.copyWith(
              color: Theme.of(context).primaryColor,
              fontSize: Dimensions.fontSizeDefault,
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: buttons,
    );
  }
}
