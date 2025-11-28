/// Custom asset image widget for displaying local app assets and SVG files
/// Provides consistent handling of asset images with SVG support

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomAssetImageWidget extends StatelessWidget {
  final String image;
  final double? height;
  final double? width;
  final BoxFit? fit;
  final Color? color;

  const CustomAssetImageWidget(this.image, {super.key, this.height, this.width, this.fit = BoxFit.cover, this.color});

  @override
  Widget build(BuildContext context) {
    final isSvg = image.contains('.svg', image.length - '.svg'.length);
    return isSvg ? SvgPicture.asset(
      image,
      width: width, height: height,
      colorFilter: color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null,
      fit: fit!,
    ) : Image.asset(image, fit: fit, width: width, height: height, color: color, filterQuality: FilterQuality.high);
  }
}
