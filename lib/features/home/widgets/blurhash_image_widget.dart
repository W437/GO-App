import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:godelivery_user/common/widgets/shared/images/custom_asset_image_widget.dart';
import 'package:godelivery_user/util/images.dart';

class BlurhashImageWidget extends StatelessWidget {
  final String imageUrl;
  final String? blurhash;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final bool testMode; // For testing - shows only blurhash

  const BlurhashImageWidget({
    super.key,
    required this.imageUrl,
    this.blurhash,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.testMode = false, // PRODUCTION: Shows blurhash then loads image
  });

  @override
  Widget build(BuildContext context) {
    // TEST MODE: Show only blurhash (no image loading)
    if (testMode && blurhash != null && blurhash!.isNotEmpty) {
      return ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: BlurHash(
          hash: blurhash!,
          imageFit: fit,
        ),
      );
    }

    // PRODUCTION MODE: Show blurhash then load image
    if (imageUrl.isEmpty) {
      return _buildPlaceholder();
    }

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Layer 1: Blurhash (appears instantly, stays visible)
          if (blurhash != null && blurhash!.isNotEmpty)
            BlurHash(
              hash: blurhash!,
              imageFit: fit,
            )
          else
            _buildPlaceholder(),

          // Layer 2: Image (fades in on top, revealing underneath)
          CachedNetworkImage(
            imageUrl: imageUrl,
            fit: fit,
            fadeInDuration: const Duration(milliseconds: 400), // Image fades in smoothly
            fadeOutDuration: Duration.zero, // No fade out needed
            placeholder: (context, url) => const SizedBox(), // Transparent while loading
            errorWidget: (context, url, error) => const SizedBox(), // Show blurhash on error
          ),
        ],
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
