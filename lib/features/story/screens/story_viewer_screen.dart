import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/features/story/controllers/story_controller.dart';
import 'package:godelivery_user/features/story/domain/models/story_collection_model.dart';
import 'package:godelivery_user/features/story/domain/models/story_media_model.dart';
import 'package:godelivery_user/features/story/widgets/story_content_widget.dart';
import 'package:godelivery_user/features/story/widgets/story_progress_bar_widget.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';

class StoryViewerScreen extends StatefulWidget {
  final List<StoryCollectionModel> collections;
  final int initialIndex;

  const StoryViewerScreen({
    super.key,
    required this.collections,
    required this.initialIndex,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late PageController _restaurantPageController;
  late AnimationController _animationController;
  int _currentRestaurantIndex = 0;
  int _currentMediaIndex = 0;
  bool _isPaused = false;
  Timer? _progressTimer;
  GlobalKey<State<StoryContentWidget>> _contentKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _currentRestaurantIndex = widget.initialIndex;
    _restaurantPageController = PageController(initialPage: widget.initialIndex);

    _animationController = AnimationController(vsync: this);
    _animationController.addListener(() {
      setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMedia();
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _animationController.dispose();
    _restaurantPageController.dispose();
    super.dispose();
  }

  void _loadMedia() {
    final collection = widget.collections[_currentRestaurantIndex];
    if (collection.stories == null || collection.stories!.isEmpty) {
      _goToNextRestaurant();
      return;
    }

    final story = collection.stories![0];
    if (story.media == null || story.media!.isEmpty) {
      _goToNextRestaurant();
      return;
    }

    final media = story.media![_currentMediaIndex];

    if (media.isImage) {
      _startImageProgress(media.durationSeconds ?? 5);
    }
    // Video progress is handled by the content widget's callbacks

    Get.find<StoryController>()
        .setCurrentIndices(_currentRestaurantIndex, _currentMediaIndex);
  }

  void _startImageProgress(int durationSeconds) {
    _animationController.duration = Duration(seconds: durationSeconds);
    _animationController.forward(from: 0).then((_) {
      if (!_isPaused) {
        _goToNextMedia();
      }
    });
  }

  void _pauseProgress() {
    setState(() {
      _isPaused = true;
    });
    _animationController.stop();
  }

  void _resumeProgress() {
    setState(() {
      _isPaused = false;
    });
    _animationController.forward();
  }

  void _goToNextMedia() {
    final collection = widget.collections[_currentRestaurantIndex];
    final totalMedia = collection.stories?[0].media?.length ?? 0;

    if (_currentMediaIndex < totalMedia - 1) {
      setState(() {
        _currentMediaIndex++;
        _contentKey = GlobalKey();
      });
      _animationController.reset();
      _loadMedia();
    } else {
      _markRestaurantSeen();
      _goToNextRestaurant();
    }
  }

  void _goToPreviousMedia() {
    if (_currentMediaIndex > 0) {
      setState(() {
        _currentMediaIndex--;
        _contentKey = GlobalKey();
      });
      _animationController.reset();
      _loadMedia();
    } else {
      _goToPreviousRestaurant();
    }
  }

  void _goToNextRestaurant() {
    if (_currentRestaurantIndex < widget.collections.length - 1) {
      _restaurantPageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Get.back();
    }
  }

  void _goToPreviousRestaurant() {
    if (_currentRestaurantIndex > 0) {
      _restaurantPageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Get.back();
    }
  }

  void _markRestaurantSeen() {
    final collection = widget.collections[_currentRestaurantIndex];
    if (collection.restaurant?.id != null) {
      Get.find<StoryController>()
          .markRestaurantStorySeen(collection.restaurant!.id!);
    }

    // Mark story as viewed on backend
    if (collection.stories != null && collection.stories!.isNotEmpty) {
      final storyId = collection.stories![0].id;
      if (storyId != null) {
        Get.find<StoryController>().markStoryViewed(storyId, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.velocity.pixelsPerSecond.dy > 500) {
            Get.back();
          }
        },
        onLongPressStart: (_) => _pauseProgress(),
        onLongPressEnd: (_) => _resumeProgress(),
        onTapUp: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < screenWidth / 2) {
            _goToPreviousMedia();
          } else {
            _goToNextMedia();
          }
        },
        child: PageView.builder(
          controller: _restaurantPageController,
          onPageChanged: (index) {
            setState(() {
              _currentRestaurantIndex = index;
              _currentMediaIndex = 0;
              _contentKey = GlobalKey();
            });
            _animationController.reset();
            _loadMedia();
          },
          itemCount: widget.collections.length,
          itemBuilder: (context, restaurantIndex) {
            final collection = widget.collections[restaurantIndex];
            final restaurant = collection.restaurant;
            final story = collection.stories?[0];
            final mediaList = story?.media ?? [];

            if (mediaList.isEmpty) {
              return const Center(
                child: Text(
                  'No media available',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            final currentMedia = mediaList[_currentMediaIndex];

            return Stack(
              children: [
                // Media content
                Positioned.fill(
                  child: StoryContentWidget(
                    key: _contentKey,
                    media: currentMedia,
                    onVideoReady: () {
                      // Video will handle its own progress
                    },
                    onVideoComplete: () {
                      if (!_isPaused) {
                        _goToNextMedia();
                      }
                    },
                    onVideoPlaying: (isPlaying) {
                      // You can sync progress with video playback if needed
                    },
                  ),
                ),

                // Top gradient overlay
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.6),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top +
                          Dimensions.paddingSizeSmall,
                      left: Dimensions.paddingSizeDefault,
                      right: Dimensions.paddingSizeDefault,
                      bottom: Dimensions.paddingSizeLarge,
                    ),
                    child: Column(
                      children: [
                        // Progress bars
                        StoryProgressBarWidget(
                          itemCount: mediaList.length,
                          currentIndex: _currentMediaIndex,
                          progress: _animationController.value,
                        ),
                        const SizedBox(height: Dimensions.paddingSizeSmall),
                        // Restaurant info
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.grey[300],
                              child: const Icon(Icons.restaurant),
                            ),
                            const SizedBox(width: Dimensions.paddingSizeSmall),
                            Expanded(
                              child: Text(
                                restaurant?.name ?? '',
                                style: robotoMedium.copyWith(
                                  color: Colors.white,
                                  fontSize: Dimensions.fontSizeLarge,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              onPressed: () => Get.back(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom caption and CTA
                if (currentMedia.caption != null ||
                    currentMedia.ctaLabel != null)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.6),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).padding.bottom +
                            Dimensions.paddingSizeDefault,
                        left: Dimensions.paddingSizeDefault,
                        right: Dimensions.paddingSizeDefault,
                        top: Dimensions.paddingSizeLarge,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (currentMedia.caption != null)
                            Text(
                              currentMedia.caption!,
                              style: robotoRegular.copyWith(
                                color: Colors.white,
                                fontSize: Dimensions.fontSizeDefault,
                              ),
                            ),
                          if (currentMedia.ctaLabel != null)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: Dimensions.paddingSizeSmall,
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  if (currentMedia.ctaUrl != null) {
                                    // Navigate to restaurant or product
                                    if (restaurant?.id != null) {
                                      Get.back();
                                      Get.toNamed(RouteHelper.getRestaurantRoute(
                                          restaurant!.id));
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).primaryColor,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: Dimensions.paddingSizeLarge,
                                    vertical: Dimensions.paddingSizeSmall,
                                  ),
                                ),
                                child: Text(
                                  currentMedia.ctaLabel!,
                                  style: robotoBold.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}