import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:godelivery_user/common/widgets/shared/images/custom_asset_image_widget.dart';
import 'package:godelivery_user/util/images.dart';

class BlurhashBannerImageWidget extends StatelessWidget {
  final String imageUrl;
  final String? blurhash;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const BlurhashBannerImageWidget({
    super.key,
    required this.imageUrl,
    this.blurhash,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return _buildPlaceholder();
    }

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: fit,
        placeholder: (context, url) {
          // Show blurhash if available, otherwise show default placeholder
          if (blurhash != null && blurhash!.isNotEmpty) {
            return BlurHash(
              hash: blurhash!,
              imageFit: fit,
            );
          }
          return _buildPlaceholder();
        },
        errorWidget: (context, url, error) => _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return CustomAssetImageWidget(
      Images.placeholder,
      fit: fit,
    );
  }
}
