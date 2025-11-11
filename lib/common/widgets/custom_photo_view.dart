/// Custom photo view widget for full-screen image viewing with zoom
/// Provides zoomable image display with navigation controls

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';
import 'package:godelivery_user/util/dimensions.dart';
class CustomPhotoView extends StatelessWidget {
  final String imageUrl;
  const CustomPhotoView({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [

      ClipRRect(
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        child: imageUrl.isNotEmpty
          ? PhotoView(
              tightMode: true,
              imageProvider: NetworkImage(imageUrl),
              heroAttributes: PhotoViewHeroAttributes(tag: imageUrl),
            )
          : Container(
              color: Colors.black,
              child: const Center(
                child: Icon(Icons.broken_image, color: Colors.white, size: 48),
              ),
            ),
      ),

      Positioned(top: 0, right: 0, child: IconButton(
        splashRadius: 5,
        onPressed: () => Get.back(),
        icon: const Icon(Icons.cancel, color: Colors.red),
      )),

    ]);
  }
}
