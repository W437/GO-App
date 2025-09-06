/// Web page title widget for desktop screen headers
/// Displays page titles with consistent styling across desktop views

import 'package:godelivery_user/helper/responsive_helper.dart';
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
      child: Center(child: Text(title, style: robotoMedium)),
    ) : const SizedBox();
  }
}
