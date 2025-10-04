import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/features/search/screens/search_screen.dart';
import 'package:godelivery_user/helper/route_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/images.dart';
import 'package:godelivery_user/util/styles.dart';

class HeaderContentBelowSticky extends StatelessWidget {
  const HeaderContentBelowSticky({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Large heading
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Dimensions.paddingSizeLarge,
                  Dimensions.paddingSizeDefault,
                  Dimensions.paddingSizeLarge,
                  Dimensions.paddingSizeDefault,
                ),
                child: Text(
                  'what_you_like_to_eat'.tr,
                  style: robotoBold.copyWith(
                    fontSize: 28,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
              ),

              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Dimensions.paddingSizeDefault,
                  0,
                  Dimensions.paddingSizeDefault,
                  Dimensions.paddingSizeLarge,
                ),
                child: InkWell(
                  onTap: () {
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
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeDefault,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
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
                          child: Text(
                            'search_menu_restaurant_craving'.tr,
                            style: robotoRegular.copyWith(
                              fontSize: Dimensions.fontSizeDefault,
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
