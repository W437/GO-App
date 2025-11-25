import 'dart:ui';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:godelivery_user/common/models/restaurant_model.dart';
import 'package:godelivery_user/common/widgets/shared/buttons/custom_ink_well_widget.dart';
import 'package:godelivery_user/common/widgets/shared/images/custom_image_widget.dart';
import 'package:godelivery_user/features/home/controllers/advertisement_controller.dart';
import 'package:godelivery_user/features/home/domain/models/advertisement_model.dart';
import 'package:godelivery_user/features/home/widgets/blurhash_image_widget.dart';
import 'package:godelivery_user/features/home/widgets/rest_sponsored_card.dart';
import 'package:godelivery_user/features/language/controllers/localization_controller.dart';
import 'package:godelivery_user/features/restaurant/screens/restaurant_screen.dart';
import 'package:godelivery_user/features/restaurant/controllers/restaurant_controller.dart';
import 'package:godelivery_user/helper/ui/responsive_helper.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:video_player/video_player.dart';
import 'package:animated_emoji/animated_emoji.dart';
import 'package:godelivery_user/util/app_colors.dart';
import 'package:godelivery_user/features/home/domain/models/home_feed_model.dart';

class SponsoredRestaurantsViewWidget extends StatefulWidget {
  const SponsoredRestaurantsViewWidget({super.key});

  @override
  State<SponsoredRestaurantsViewWidget> createState() => _SponsoredRestaurantsViewWidgetState();
}

class _SponsoredRestaurantsViewWidgetState extends State<SponsoredRestaurantsViewWidget> {

  @override
  Widget build(BuildContext context) {
    return GetBuilder<RestaurantController>(builder: (restaurantController) {
      final advertised = restaurantController.homeFeedModel?.advertised;

      // Show shimmer while loading
      if (restaurantController.homeFeedModel == null) {
        return const AdvertisementShimmer();
      }

      // Always show the section with header
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.05),
              blurRadius: 24,
              spreadRadius: 0,
              offset: Offset(0, 6),
            ),
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.08),
              blurRadius: 0,
              spreadRadius: 1,
              offset: Offset(0, 0),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Blurred background image
              Positioned.fill(
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                  child: Image.asset(
                    Get.isDarkMode
                        ? 'assets/image/sponsored/bg_pattern_dark.png'
                        : 'assets/image/sponsored/bg_pattern_light.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Overlay (white in light mode, black in dark mode)
              Positioned.fill(
                child: Container(
                  color: Get.isDarkMode
                      ? Colors.black.withValues(alpha: 0.7)
                      : Colors.white.withValues(alpha: 0.7),
                ),
              ),
              // Fade gradient at top
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Get.isDarkMode
                            ? Theme.of(context).scaffoldBackgroundColor
                            : Colors.white,
                        Get.isDarkMode
                            ? Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0)
                            : Colors.white.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.only(top: Dimensions.paddingSizeLarge, bottom: Dimensions.paddingSizeSmall),
                child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'highlights_for_you'.tr,
                          style: robotoBold.copyWith(
                            fontSize: Dimensions.fontSizeOverLarge,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        AnimatedEmoji(
                          AnimatedEmojis.fire,
                          size: 28,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Featured partner restaurants near you',
                      style: robotoRegular.copyWith(
                        color: Theme.of(context).hintColor,
                        fontSize: Dimensions.fontSizeDefault,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeDefault),

              // Restaurant Cards - Horizontal List or Empty State
              Builder(
                builder: (context) {
                  List<Restaurant> restaurants = advertised?.restaurants ?? [];

                  // Show empty state when no highlights
                  if (restaurants.isEmpty) {
                    return Container(
                      height: 180,
                      margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                      decoration: BoxDecoration(
                        color: Theme.of(context).hintColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Theme.of(context).hintColor.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).hintColor.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.auto_awesome_rounded,
                                size: 32,
                                color: Theme.of(context).hintColor.withValues(alpha: 0.5),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'no_highlights_available'.tr,
                              style: robotoMedium.copyWith(
                                fontSize: Dimensions.fontSizeDefault,
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'check_back_later'.tr,
                              style: robotoRegular.copyWith(
                                fontSize: Dimensions.fontSizeSmall,
                                color: Theme.of(context).hintColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return SizedBox(
                    height: 240, // Extra height for bottom shadow
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(
                        left: Dimensions.paddingSizeDefault,
                        right: Dimensions.paddingSizeDefault,
                        bottom: 20, // Padding for shadow
                      ),
                      itemCount: restaurants.length,
                      itemBuilder: (context, index) {
                        return Container(
                          width: 160,
                          margin: EdgeInsets.only(
                            right: index < restaurants.length - 1 ? Dimensions.paddingSizeDefault : 0,
                          ),
                          child: RestSponsoredCard(restaurant: restaurants[index]),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class HighlightVideoWidget extends StatefulWidget {
  final AdvertisementModel advertisement;
  const HighlightVideoWidget({super.key, required this.advertisement});

  @override
  State<HighlightVideoWidget> createState() => _HighlightVideoWidgetState();
}

class _HighlightVideoWidgetState extends State<HighlightVideoWidget> {

  late VideoPlayerController videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    initializePlayer();

    videoPlayerController.addListener(() {
      if(videoPlayerController.value.duration == videoPlayerController.value.position){
        if(GetPlatform.isWeb){
          Future.delayed(const Duration(seconds: 4), () {
            Get.find<AdvertisementController>().updateAutoPlayStatus(status: true, shouldUpdate: true);
          });
        }else{
          Get.find<AdvertisementController>().updateAutoPlayStatus(status: true, shouldUpdate: true);
        }
      }
    });
  }

  Future<void> initializePlayer() async {
    videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(
      widget.advertisement.videoAttachmentFullUrl ?? "",
    ));

    await Future.wait([
      videoPlayerController.initialize(),
    ]);

    _createChewieController();
    setState(() {});
  }

  void _createChewieController() {
    _chewieController = ChewieController(
      videoPlayerController: videoPlayerController,
      autoPlay: true,
      aspectRatio: videoPlayerController.value.aspectRatio,
    );
    _chewieController?.setVolume(0);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AdvertisementController>(builder: (advertisementController) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
        height: 320,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Get.isDarkMode
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.12),
              blurRadius: 24,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Video Section
            Expanded(
              flex: 6,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_chewieController != null && _chewieController!.videoPlayerController.value.isInitialized)
                      Chewie(controller: _chewieController!)
                    else
                      Center(
                        child: CircularProgressIndicator(
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Bottom Content Section
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Title and Description
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.advertisement.title ?? '',
                            style: robotoBold.copyWith(
                              fontSize: Dimensions.fontSizeLarge,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.advertisement.description ?? '',
                            style: robotoRegular.copyWith(
                              fontSize: Dimensions.fontSizeDefault,
                              color: Theme.of(context).hintColor,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: Dimensions.paddingSizeDefault),

                    // Action Button
                    InkWell(
                      onTap: () {
                        Get.toNamed(
                          RouteHelper.getRestaurantRoute(widget.advertisement.restaurantId),
                          arguments: RestaurantScreen(restaurant: Restaurant(id: widget.advertisement.restaurantId)),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).primaryColor,
                              Theme.of(context).primaryColor.withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class AdvertisementIndicator extends StatelessWidget {
  const AdvertisementIndicator({super.key});

  @override
  Widget build(BuildContext context) {

    return GetBuilder<AdvertisementController>(builder: (advertisementController) {
      return advertisementController.advertisementList != null && advertisementController.advertisementList!.length > 2 ?
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(height: 7, width: 7,
          decoration:  BoxDecoration(color: Theme.of(context).primaryColor,
            shape: BoxShape.circle,
          ),
        ),
        Row(mainAxisAlignment: MainAxisAlignment.center,
          children: advertisementController.advertisementList!.map((advertisement) {
            int index = advertisementController.advertisementList!.indexOf(advertisement);
            return index == advertisementController.currentIndex ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 3),
              margin: const EdgeInsets.symmetric(horizontal: 6.0),
              decoration: BoxDecoration(
                  color:  Theme.of(context).primaryColor ,
                  borderRadius: BorderRadius.circular(50)),
              child:  Text("${index+1}/ ${advertisementController.advertisementList!.length}",
                style: const TextStyle(color: Colors.white,fontSize: 12),),
            ):const SizedBox();
          }).toList(),
        ),
        Container(
          height: 7, width: 7,
          decoration:  BoxDecoration(
            color: Theme.of(context).primaryColor,
            shape: BoxShape.circle,
          ),
        ),
      ]): advertisementController.advertisementList != null && advertisementController.advertisementList!.length == 2 ?
      Align(
        alignment: Alignment.center,
        child: AnimatedSmoothIndicator(
          activeIndex: advertisementController.currentIndex,
          count: advertisementController.advertisementList!.length,
          effect: ExpandingDotsEffect(
            dotHeight: 7,
            dotWidth: 7,
            spacing: 5,
            activeDotColor: Theme.of(context).colorScheme.primary,
            dotColor: Theme.of(context).hintColor.withValues(alpha: 0.6),
          ),
        ),
      ): const SizedBox();
    });
  }
}

class AdvertisementShimmer extends StatelessWidget {
  const AdvertisementShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final shimmerBase = Theme.of(context).hintColor.withValues(alpha: 0.1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header shimmer
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Shimmer(
                  duration: const Duration(seconds: 2),
                  child: Container(
                    height: 22,
                    width: 180,
                    color: shimmerBase,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Shimmer(
                  duration: const Duration(seconds: 2),
                  child: Container(
                    height: 14,
                    width: 220,
                    color: shimmerBase,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeDefault),

        // Cards shimmer - matches SponsoredRestaurantCard size
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.only(
              left: Dimensions.paddingSizeDefault,
              right: Dimensions.paddingSizeDefault,
              bottom: 20,
            ),
            itemCount: 4,
            itemBuilder: (context, index) {
              return Container(
                width: 160,
                margin: EdgeInsets.only(
                  right: index < 3 ? Dimensions.paddingSizeDefault : 0,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Get.isDarkMode
                          ? Colors.black.withValues(alpha: 0.3)
                          : Colors.grey.withValues(alpha: 0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Top - Image placeholder
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        child: Shimmer(
                          duration: const Duration(seconds: 2),
                          child: Container(
                            width: double.infinity,
                            color: shimmerBase,
                          ),
                        ),
                      ),
                    ),

                    // Bottom - Content placeholder
                    Container(
                      padding: const EdgeInsets.fromLTRB(8, 32, 8, 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                      ),
                      child: Column(
                        children: [
                          // Name
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Shimmer(
                              duration: const Duration(seconds: 2),
                              child: Container(
                                height: 14,
                                width: 100,
                                color: shimmerBase,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Status badge
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Shimmer(
                              duration: const Duration(seconds: 2),
                              child: Container(
                                height: 16,
                                width: 80,
                                color: shimmerBase,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Rating badge
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Shimmer(
                              duration: const Duration(seconds: 2),
                              child: Container(
                                height: 16,
                                width: 50,
                                color: shimmerBase,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}