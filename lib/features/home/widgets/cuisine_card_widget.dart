import 'dart:math';

import 'package:godelivery_user/features/cuisine/widgets/cuisine_custom_shape_widget.dart';
import 'package:godelivery_user/features/home/widgets/blurhash_image_widget.dart';
import 'package:godelivery_user/features/splash/controllers/theme_controller.dart';
import 'package:godelivery_user/helper/ui/responsive_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CuisineCardWidget extends StatelessWidget {
  final String image;
  final String? blurhash;
  final String name;
  final bool fromCuisinesPage;
  final bool fromSearchPage;
  const CuisineCardWidget({super.key, required this.image, this.blurhash, required this.name, this.fromCuisinesPage = false, this.fromSearchPage = false});

  @override
  Widget build(BuildContext context) {
    return ResponsiveHelper.isDesktop(context) ? ClipRRect(
      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(Dimensions.radiusDefault), bottomRight: Radius.circular(Dimensions.radiusDefault)),
      child: Stack(
        children: [
          Positioned(bottom: ResponsiveHelper.isMobile(context) ? -75 : -55, left: 0, right: ResponsiveHelper.isMobile(context) ? -17 : 0,
            child: Transform.rotate(
              angle: 40,
              child: Container(
                height: ResponsiveHelper.isMobile(context) ? 132 : 120, width: ResponsiveHelper.isMobile(context) ? 150 : 120,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(decoration: BoxDecoration( color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(50)),
              child: BlurhashImageWidget(
                imageUrl: image,
                blurhash: blurhash,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(50),
              ),
            ),
          ),

          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              alignment: Alignment.center,
              height: 30, width: 120,
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [BoxShadow(color: Colors.grey[Get.find<ThemeController>().darkTheme ? 700 : 300]!, spreadRadius: 0.5, blurRadius: 0.5)],
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(Dimensions.radiusDefault), bottomRight: Radius.circular(Dimensions.radiusDefault)),
              ),
              child: Text( name, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
                maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
              ),
            ),
          )
        ],
      ),
    ) : LayoutBuilder(
      builder: (context, constraints) {
        final bool isLargeTile = fromSearchPage || fromCuisinesPage;
        final double targetSize = isLargeTile ? 120 : 84;
        final double maxWidth = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : targetSize;
        final double maxHeight = constraints.maxHeight.isFinite && constraints.maxHeight > 0
            ? constraints.maxHeight
            : double.infinity;
        const double textBudget = Dimensions.paddingSizeExtraSmall + 24;
        final double heightAllowance = maxHeight.isFinite ? max(0, maxHeight - textBudget) : double.infinity;
        final double avatarSize = min(targetSize, min(maxWidth, heightAllowance));
        final double textWidth = maxWidth > 0 ? maxWidth : avatarSize;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.2),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: BlurhashImageWidget(
                imageUrl: image,
                blurhash: blurhash,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(avatarSize / 2),
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeExtraSmall),
            SizedBox(
              width: textWidth,
              child: Text(
                name,
                style: robotoMedium.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        );
      },
    );
  }
}
