/// Web screen title widget for desktop layout page headers
/// Displays page titles in a styled container for better desktop navigation

import 'package:godelivery_user/helper/ui/responsive_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:flutter/material.dart';


class WebScreenTitleWidget extends StatelessWidget {
  final String title;
  const WebScreenTitleWidget({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return ResponsiveHelper.isDesktop(context) ? Container(
      height: 64,
      color: Theme.of(context).primaryColor.withValues(alpha: 0.10),
      child: Center(child: Text(title, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge, fontWeight: FontWeight.w600))),
    ) : const SizedBox();
  }
}
