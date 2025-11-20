import 'package:godelivery_user/common/widgets/adaptive/custom_favourite_widget.dart';
import 'package:godelivery_user/common/widgets/shared/buttons/circular_back_button_widget.dart';
import 'package:godelivery_user/features/coupon/controllers/coupon_controller.dart';
import 'package:godelivery_user/features/favourite/controllers/favourite_controller.dart';
import 'package:godelivery_user/features/language/controllers/localization_controller.dart';
import 'package:godelivery_user/features/restaurant/controllers/restaurant_controller.dart';
import 'package:godelivery_user/common/widgets/shared/layout/customizable_space_bar_widget.dart';
import 'package:godelivery_user/common/models/restaurant_model.dart';
import 'package:godelivery_user/helper/converters/date_converter.dart';
import 'package:godelivery_user/helper/converters/price_converter.dart';
import 'package:godelivery_user/helper/ui/responsive_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/images.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:godelivery_user/features/home/widgets/blurhash_image_widget.dart';
import 'package:godelivery_user/features/restaurant/widgets/restaurant_app_bar_widget.dart';
import 'package:godelivery_user/common/widgets/shared/images/custom_image_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:marquee/marquee.dart';

class RestaurantInfoSectionWidget extends StatelessWidget {
  final Restaurant restaurant;
  final RestaurantController restController;
  final bool hasCoupon;
  const RestaurantInfoSectionWidget({
    super.key,
    required this.restaurant,
    required this.restController,
    required this.hasCoupon,
  });


  @override
  Widget build(BuildContext context) {
    bool isDesktop = ResponsiveHelper.isDesktop(context);

    return SliverAppBar(
      expandedHeight: 250,
      toolbarHeight: 50,
      pinned: true,
      floating: false,
      elevation: 0,
      backgroundColor: Theme.of(context).cardColor,
      leading: const SizedBox(),
      leadingWidth: 0,
      title: RestaurantAppBarWidget(restController: restController),
      centerTitle: true,
      automaticallyImplyLeading: false,
      clipBehavior: Clip.none,
      
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.zero,
        centerTitle: true,
        expandedTitleScale: 1.1,
        collapseMode: CollapseMode.none,
        background: OverflowBox(
          minHeight: 280,
          maxHeight: 280,
          alignment: Alignment.topCenter,
          child: Stack(
            fit: StackFit.expand,
            children: [
              BlurhashImageWidget(
                imageUrl: '${restaurant.coverPhotoFullUrl}',
                blurhash: restaurant.coverPhotoBlurhash,
                fit: BoxFit.cover,
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.6),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.6],
                  ),
                ),
              ),
              // Logo removed - will be rendered at screen level for top z-index
            ],
          ),
        ),
      ),
    );
  }
}
