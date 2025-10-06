import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/common/widgets/custom_button_widget.dart';
import 'package:godelivery_user/features/search/screens/search_screen.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/images.dart';
import 'package:godelivery_user/util/styles.dart';

class HeaderContentBelowSticky extends StatefulWidget {
  const HeaderContentBelowSticky({super.key});

  @override
  State<HeaderContentBelowSticky> createState() => _HeaderContentBelowStickyState();
}

class _HeaderContentBelowStickyState extends State<HeaderContentBelowSticky> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _openSearchSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: Container(
            color: Theme.of(context).colorScheme.surface,
            child: Navigator(
              onGenerateRoute: (settings) => MaterialPageRoute(
                builder: (context) => const SearchScreen(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor,
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Stack(
        children: [
          // Background logo
          Positioned(
            right: -40,
            top: -40,
            child: Opacity(
              opacity: 0.15,
              child: Image.asset(
                Images.logo,
                width: 180,
                height: 180,
                color: Colors.white,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Main content with Column
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Dimensions.paddingSizeLarge,
              Dimensions.paddingSizeDefault,
              Dimensions.paddingSizeLarge,
              Dimensions.paddingSizeDefault,
            ),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                // Title and search button row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Large heading
                    Expanded(
                      child: Text(
                        'what_you_like_to_eat'.tr,
                        style: robotoBold.copyWith(
                          fontSize: 28,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                    ),
                    // Circular search button (only shows when not expanded)
                    if (!_isExpanded)
                      CustomButtonWidget(
                        onPressed: _toggleExpansion,
                        isCircular: true,
                        icon: Icons.search,
                        width: 48,
                        height: 48,
                        iconSize: 24,
                        color: Colors.white,
                        iconColor: Theme.of(context).primaryColor,
                      ),
                  ],
                ),

                // Expanded search bar (only shows when expanded)
                if (_isExpanded) ...[
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: Dimensions.paddingSizeDefault,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.search,
                              color: Theme.of(context).hintColor,
                              size: 22,
                            ),
                            const SizedBox(width: Dimensions.paddingSizeSmall),
                            Expanded(
                              child: InkWell(
                                onTap: () => _openSearchSheet(context),
                                child: Text(
                                  'search_menu_restaurant_craving'.tr,
                                  style: robotoRegular.copyWith(
                                    fontSize: Dimensions.fontSizeDefault,
                                    color: Theme.of(context).hintColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            const SizedBox(width: Dimensions.paddingSizeSmall),
                            InkWell(
                              onTap: _toggleExpansion,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.close,
                                  color: Theme.of(context).hintColor,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
