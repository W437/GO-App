import 'dart:async';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:godelivery_user/features/home/controllers/home_controller.dart';
import 'package:godelivery_user/features/home/domain/models/banner_model.dart';
import 'package:godelivery_user/features/home/widgets/video_banner_item_widget.dart';
import 'package:godelivery_user/features/home/widgets/blurhash_image_widget.dart';
import 'package:godelivery_user/features/restaurant/screens/restaurant_screen.dart';
import 'package:godelivery_user/features/splash/controllers/splash_controller.dart';
import 'package:godelivery_user/features/product/domain/models/basic_campaign_model.dart';
import 'package:godelivery_user/common/models/product_model.dart';
import 'package:godelivery_user/common/models/restaurant_model.dart';
import 'package:godelivery_user/helper/ui/responsive_helper.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:godelivery_user/common/widgets/adaptive/product/restaurant_product_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class BannerViewWidget extends StatefulWidget {
  const BannerViewWidget({super.key});

  @override
  State<BannerViewWidget> createState() => _BannerViewWidgetState();
}

class _BannerViewWidgetState extends State<BannerViewWidget> {
  CarouselSliderController? _carouselController;
  Timer? _imageTimer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _carouselController = CarouselSliderController();
  }

  @override
  void dispose() {
    _imageTimer?.cancel();
    super.dispose();
  }

  bool _isVideoUrl(String? url) {
    if (url == null) return false;
    final videoExtensions = ['.mp4', '.mov', '.avi', '.mkv', '.webm', '.m4v'];
    final lowerUrl = url.toLowerCase();
    return videoExtensions.any((ext) => lowerUrl.contains(ext));
  }

  bool _shouldShowVideo(int index, HomeController homeController) {
    if (homeController.bannerObjectList == null ||
        index >= homeController.bannerObjectList!.length) {
      return false;
    }
    final banner = homeController.bannerObjectList![index];
    return banner.videoFullUrl != null && _isVideoUrl(banner.videoFullUrl);
  }

  void _handleVideoEnd() {
    // Move to next slide when video ends
    _carouselController?.nextPage(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _handlePageChanged(int index, HomeController homeController) {
    setState(() {
      _currentIndex = index;
    });
    homeController.setCurrentIndex(index, true);

    // Cancel any existing timer
    _imageTimer?.cancel();

    // If current banner is an image, set a timer to auto-advance
    if (!_shouldShowVideo(index, homeController)) {
      // Auto-advance after 7 seconds for image banners
      _imageTimer = Timer(const Duration(seconds: 7), () {
        if (mounted) {
          _carouselController?.nextPage(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    return GetBuilder<HomeController>(builder: (homeController) {
      // Start timer for first banner if it's an image
      if (homeController.bannerImageList != null &&
          homeController.bannerImageList!.isNotEmpty &&
          _imageTimer == null &&
          _currentIndex == 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _handlePageChanged(0, homeController);
          }
        });
      }

      return (homeController.bannerImageList != null && homeController.bannerImageList!.isEmpty) ? const SizedBox() : Container(
        width: MediaQuery.of(context).size.width,
        clipBehavior: Clip.none, // Allow shadow to overflow
        child: homeController.bannerImageList != null ? Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: GetPlatform.isDesktop ? 500 : 220,
                    child: CarouselSlider.builder(
                carouselController: _carouselController,
                options: CarouselOptions(
                  viewportFraction: 1.0,
                  enlargeFactor: 0.0,
                  autoPlay: false, // Disabled - videos and images control their own timing
                  enlargeCenterPage: false,
                  disableCenter: false,
                  padEnds: true,
                  clipBehavior: Clip.none,
                  onPageChanged: (index, reason) {
                    _handlePageChanged(index, homeController);
                  },
                ),
                itemCount: homeController.bannerImageList!.isEmpty ? 1 : homeController.bannerImageList!.length,
                itemBuilder: (context, index, _) {
                  final banner = homeController.bannerObjectList != null &&
                                 index < homeController.bannerObjectList!.length
                      ? homeController.bannerObjectList![index]
                      : null;
                  final isVideo = _shouldShowVideo(index, homeController);

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Shadow layer (behind content)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor, // Background for shadow
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color.fromRGBO(0, 0, 0, 0.1),
                                  blurRadius: 6,
                                  spreadRadius: -1,
                                  offset: Offset(0, 4),
                                ),
                                BoxShadow(
                                  color: Color.fromRGBO(0, 0, 0, 0.06),
                                  blurRadius: 4,
                                  spreadRadius: -1,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Content layer (clipped)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              splashColor: Colors.transparent, // No splash flicker
                              highlightColor: Colors.transparent, // No highlight flicker
                              onTap: () {
                                if(homeController.bannerDataList![index] is Product) {
                                  Product? product = homeController.bannerDataList![index];
                                  ResponsiveHelper.isMobile(context) ? showModalBottomSheet(
                                    context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
                                    builder: (con) => RestaurantProductSheet(product: product),
                                  ) : showDialog(context: context, builder: (con) => Dialog(
                                      child: RestaurantProductSheet(product: product)),
                                  );
                                }else if(homeController.bannerDataList![index] is Restaurant) {
                                  Restaurant restaurant = homeController.bannerDataList![index];
                                  Get.toNamed(
                                    RouteHelper.getRestaurantRoute(restaurant.id),
                                    arguments: RestaurantScreen(restaurant: restaurant),
                                  );
                                }else if(homeController.bannerDataList![index] is BasicCampaignModel) {
                                  BasicCampaignModel campaign = homeController.bannerDataList![index];
                                  Get.toNamed(RouteHelper.getBasicCampaignRoute(campaign));
                                }
                              },
                              child: isVideo && banner?.videoFullUrl != null
                                  ? VideoBannerItemWidget(
                                      videoUrl: banner!.videoFullUrl!,
                                      thumbnailUrl: banner.videoThumbnailUrl,
                                      thumbnailBlurhash: banner.videoThumbnailBlurhash,
                                      onVideoEnd: _handleVideoEnd,
                                      borderRadius: BorderRadius.circular(16),
                                      isActive: index == _currentIndex, // Only play if visible
                                    )
                                  : BlurhashImageWidget(
                                      imageUrl: banner?.imageFullUrl ?? '',
                                      blurhash: banner?.imageBlurhash, // Use actual API blurhash
                                      fit: BoxFit.cover,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
                  ),

                  const SizedBox(height: Dimensions.paddingSizeSmall),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: homeController.bannerImageList!.map((bnr) {
                      int index = homeController.bannerImageList!.indexOf(bnr);
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        height: 8,
                        width: 8,
                        decoration: BoxDecoration(
                          color: index == homeController.currentIndex
                              ? Theme.of(context).primaryColor
                              : Theme.of(context).disabledColor.withValues(alpha: 0.35),
                          shape: BoxShape.circle,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                ],
              ),
            ),
          ],
        ) : Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: GetPlatform.isDesktop ? 500 : 220,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.transparent,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Shimmer(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: Dimensions.paddingSizeSmall),
                  // Empty space for pagination dots (same structure as loaded state)
                  const SizedBox(height: 8),
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

}
