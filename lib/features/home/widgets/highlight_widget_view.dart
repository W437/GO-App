import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:godelivery_user/common/models/restaurant_model.dart';
import 'package:godelivery_user/common/widgets/shared/images/custom_image_widget.dart';
import 'package:godelivery_user/features/home/controllers/advertisement_controller.dart';
import 'package:godelivery_user/features/home/domain/models/advertisement_model.dart';
import 'package:godelivery_user/features/home/widgets/restaurants_view_widget.dart';
import 'package:godelivery_user/features/language/controllers/localization_controller.dart';
import 'package:godelivery_user/features/restaurant/screens/restaurant_screen.dart';
import 'package:godelivery_user/features/restaurant/controllers/restaurant_controller.dart';
import 'package:godelivery_user/helper/ui/responsive_helper.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:video_player/video_player.dart';

class HighlightWidgetView extends StatefulWidget {
  const HighlightWidgetView({super.key});

  @override
  State<HighlightWidgetView> createState() => _HighlightWidgetViewState();
}

class _HighlightWidgetViewState extends State<HighlightWidgetView> {

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AdvertisementController>(builder: (advertisementController) {
      return advertisementController.advertisementList != null && advertisementController.advertisementList!.isNotEmpty ? Container(
        margin: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Modern Section Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).primaryColor,
                              Theme.of(context).primaryColor.withValues(alpha: 0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded, color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'SPONSORED',
                              style: robotoMedium.copyWith(
                                fontSize: Dimensions.fontSizeSmall,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                  Text(
                    'highlights_for_you'.tr,
                    style: robotoBold.copyWith(
                      fontSize: Dimensions.fontSizeOverLarge,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'see_our_most_popular_restaurant_and_foods'.tr,
                    style: robotoRegular.copyWith(
                      color: Theme.of(context).hintColor,
                      fontSize: Dimensions.fontSizeDefault,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),

            // Restaurant Cards - Horizontal List
            GetBuilder<RestaurantController>(
              builder: (restaurantController) {
                // Get restaurants from advertisements
                List<Restaurant> restaurants = advertisementController.advertisementList!
                    .where((ad) => ad.restaurant != null && ad.addType != 'video_promotion')
                    .map((ad) => ad.restaurant!)
                    .toList();

                return restaurants.isNotEmpty
                  ? SizedBox(
                      height: 305,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                        itemCount: restaurants.length,
                        itemBuilder: (context, index) {
                          return Container(
                            width: ResponsiveHelper.isMobile(context)
                                ? MediaQuery.of(context).size.width - (Dimensions.paddingSizeDefault * 2)
                                : 400,
                            margin: EdgeInsets.only(
                              right: index < restaurants.length - 1 ? Dimensions.paddingSizeLarge : 0,
                            ),
                            child: RestaurantView(restaurant: restaurants[index]),
                          );
                        },
                      ),
                    )
                  : const SizedBox();
              },
            ),
          ],
        ),
      ) : advertisementController.advertisementList == null ? const AdvertisementShimmer() : const SizedBox();
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
    return Shimmer(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.05),
        ),
        margin:  EdgeInsets.only(
          top: ResponsiveHelper.isDesktop(context) ? Dimensions.paddingSizeLarge * 3.5 : 0 ,
          right: Get.find<LocalizationController>().isLtr && ResponsiveHelper.isDesktop(context) ? Dimensions.paddingSizeLarge : 0,
          left: !Get.find<LocalizationController>().isLtr && ResponsiveHelper.isDesktop(context) ? Dimensions.paddingSizeLarge : 0,
        ),
        child: Padding( padding : const EdgeInsets.symmetric(vertical : Dimensions.paddingSizeDefault),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const SizedBox(height: Dimensions.paddingSizeLarge,),

              Container(height: 20, width: 200,
                margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Theme.of(context).shadowColor
                ),),

              const SizedBox(height: Dimensions.paddingSizeSmall,),

              Container(height: 15, width: 250,
                margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Theme.of(context).shadowColor,
                ),),

              const SizedBox(height: Dimensions.paddingSizeDefault * 2,),

              SizedBox(
                height: 250,
                child: ListView.builder(
                  itemCount: ResponsiveHelper.isDesktop(context) ? 3 : 1,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    return SizedBox(
                      width: ResponsiveHelper.isDesktop(context) ? (Dimensions.webMaxWidth - 20) / 3 : MediaQuery.of(context).size.width,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Padding(padding: const EdgeInsets.only(bottom: 0, left: 10, right: 10),
                            child: Container(
                              height: 250,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                                color: Theme.of(context).shadowColor,
                                border: Border.all(color: Theme.of(context).hintColor.withValues(alpha: 0.2),),
                              ),
                              padding: const EdgeInsets.only(bottom: 25),
                              child: const Center(child: Icon(Icons.play_circle, color: Colors.white,size: 45,),),
                            ),
                          ),

                          Positioned( bottom: 0, left: 0,right: 0, child: Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                                color: Theme.of(context).cardColor,
                                border: Border.all(color: Theme.of(context).shadowColor)
                            ),
                            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                            margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                            child: Column(children: [
                              Row( children: [

                                Expanded(
                                  child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Container(
                                      height: 17, width: double.infinity,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                                        color: Theme.of(context).shadowColor,
                                      ),
                                    ),

                                    const SizedBox(height: Dimensions.paddingSizeSmall,),
                                    Container(
                                      height: 17, width: 150,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                                        color: Theme.of(context).shadowColor,
                                      ),
                                    ),

                                    const SizedBox(height: Dimensions.paddingSizeExtraSmall,),

                                    Container(
                                      height: 17, width: double.infinity,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                                        color: Theme.of(context).shadowColor,
                                      ),
                                    )
                                  ]),
                                ),

                                const SizedBox(width: Dimensions.paddingSizeLarge,),

                                InkWell(
                                  onTap: () => Get.back(),
                                  child: Container(
                                    margin: const EdgeInsets.only(top: Dimensions.paddingSizeExtraSmall),
                                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall + 5, vertical: Dimensions.paddingSizeSmall),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                      color: Theme.of(context).shadowColor,
                                    ),
                                    child:  Icon(Icons.arrow_forward_rounded, size: 20, color: Colors.white.withValues(alpha: 0.8),),
                                  ),
                                )
                              ],)
                            ],),
                          ))
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: Dimensions.paddingSizeLarge * 2,),

              Align(
                alignment: Alignment.center,
                child: AnimatedSmoothIndicator(
                  activeIndex: 0,
                  count: 3,
                  effect: ExpandingDotsEffect(
                    dotHeight: 7,
                    dotWidth: 7,
                    spacing: 5,
                    activeDotColor: Theme.of(context).disabledColor,
                    dotColor: Theme.of(context).hintColor.withValues(alpha: 0.6),
                  ),
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeExtraSmall,),
            ],
          ),
        ),
      ),
    );
  }
}