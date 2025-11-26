import 'package:flutter/material.dart';
import 'package:godelivery_user/features/address/domain/models/address_model.dart';
import 'package:godelivery_user/common/widgets/shared/buttons/custom_button_widget.dart';
import 'package:godelivery_user/common/widgets/shared/feedback/custom_snackbar_widget.dart';
import 'package:godelivery_user/helper/business_logic/address_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:get/get.dart';

/// Floating address badge widget that displays saved addresses in a swipeable carousel
/// Similar to ZoneFloatingBadge but for addresses
class AddressFloatingBadge extends StatefulWidget {
  final AddressModel? selectedAddress;
  final List<AddressModel> addresses;
  final Function(AddressModel?) onAddressChanged;
  final Future<void> Function(AddressModel) onAddressSelected; // Called when user confirms selection
  final VoidCallback onAddNewAddress;

  const AddressFloatingBadge({
    super.key,
    required this.selectedAddress,
    required this.addresses,
    required this.onAddressChanged,
    required this.onAddressSelected,
    required this.onAddNewAddress,
  });

  @override
  State<AddressFloatingBadge> createState() => _AddressFloatingBadgeState();
}

class _AddressFloatingBadgeState extends State<AddressFloatingBadge>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  int _currentPage = 0;

  @override
  void initState() {
    super.initState();

    // Find initial page based on selected address
    int initialPage = 0;
    if (widget.selectedAddress != null) {
      initialPage = widget.addresses.indexWhere((a) => a.id == widget.selectedAddress!.id);
      if (initialPage == -1) initialPage = 0;
    }
    _currentPage = initialPage;

    _pageController = PageController(initialPage: initialPage);

    // Slide + scale animation for appearance
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _slideController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  IconData _getAddressIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'home':
        return Icons.home_rounded;
      case 'work':
      case 'office':
        return Icons.work_rounded;
      default:
        return Icons.location_on_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Total items = addresses + "Add New Address" card
    final totalItems = widget.addresses.length + 1;
    final showMultipleDots = totalItems > 1;
    final isAddNewPage = _currentPage >= widget.addresses.length;
    final currentAddress = isAddNewPage ? null : widget.addresses[_currentPage];
    final isCurrentAddress = currentAddress != null && widget.selectedAddress?.id == currentAddress.id;

    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // PageView with addresses
              SizedBox(
                height: 90,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (page) {
                    setState(() {
                      _currentPage = page;
                    });

                    // Notify parent about address change (null for "Add New" page)
                    if (page < widget.addresses.length) {
                      widget.onAddressChanged(widget.addresses[page]);
                    } else {
                      widget.onAddressChanged(null);
                    }
                  },
                  itemCount: totalItems,
                  itemBuilder: (context, index) {
                    // Last item is "Add New Address"
                    if (index == widget.addresses.length) {
                      return _buildAddNewAddressCard(context);
                    }

                    final address = widget.addresses[index];
                    return _buildAddressCard(address, context);
                  },
                ),
              ),

              // Pagination dots
              if (showMultipleDots) ...[
                const SizedBox(height: Dimensions.paddingSizeSmall),
                _buildPaginationDots(totalItems),
              ],

              // Action button below badge
              const SizedBox(height: Dimensions.paddingSizeSmall),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                child: CustomButtonWidget(
                  height: 46,
                  buttonText: isAddNewPage
                      ? 'add_new_address'.tr
                      : (isCurrentAddress ? 'current_address'.tr : 'select_address'.tr),
                  fontSize: Dimensions.fontSizeDefault,
                  onPressed: isAddNewPage
                      ? widget.onAddNewAddress
                      : (isCurrentAddress
                          ? null
                          : () async {
                              await widget.onAddressSelected(currentAddress!);
                              showCustomSnackBar(currentAddress.address ?? 'address_selected'.tr, isError: false);
                            }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaginationDots(int count) {
    const maxDots = 10;
    final dotsToShow = count > maxDots ? maxDots : count;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(dotsToShow, (index) {
        final isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 8 : 6,
          height: isActive ? 8 : 6,
          decoration: BoxDecoration(
            color: isActive
                ? Colors.white
                : Colors.white.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }

  Widget _buildAddressCard(AddressModel address, BuildContext context) {
    final isCurrentAddress = widget.selectedAddress?.id == address.id;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: Colors.grey[800]!.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
        border: Border.all(
          color: isCurrentAddress
              ? Theme.of(context).primaryColor
              : Colors.white.withValues(alpha: 0.1),
          width: isCurrentAddress ? 3 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Address type with icon
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getAddressIcon(address.addressType),
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: Dimensions.paddingSizeExtraSmall),
              Expanded(
                child: Text(
                  address.addressType?.tr ?? 'address'.tr,
                  style: robotoBold.copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: Dimensions.paddingSizeExtraSmall),

          // Full address
          Expanded(
            child: Text(
              address.address ?? '',
              style: robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: Colors.white.withValues(alpha: 0.8),
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddNewAddressCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Colors.grey[800]!.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add_location_alt_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(
            child: Text(
              'Pin a location on the map to add your first address!',
              style: robotoMedium.copyWith(
                fontSize: Dimensions.fontSizeDefault,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
