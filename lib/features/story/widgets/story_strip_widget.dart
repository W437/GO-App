import 'package:godelivery_user/features/home/widgets/blurhash_image_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/features/story/controllers/story_controller.dart';
import 'package:godelivery_user/features/story/screens/story_viewer_screen.dart';
import 'package:godelivery_user/features/story/widgets/circular_reveal_route.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class StoryStripWidget extends StatelessWidget {
  const StoryStripWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<StoryController>(
      builder: (storyController) {
        if (storyController.isLoading) {
          return _buildShimmer();
        }

        if (!storyController.hasStories) {
          return _buildEmptyState(context);
        }

        return Container(
          height: 110,
          padding: const EdgeInsets.only(
            bottom: Dimensions.paddingSizeExtraSmall,
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeDefault,
            ),
            itemCount: storyController.storyList!.length,
            itemBuilder: (context, index) {
              final collection = storyController.storyList![index];
              final restaurant = collection.restaurant;

              if (restaurant == null) return const SizedBox.shrink();

              return Builder(
                builder: (itemContext) {
                  return GestureDetector(
                    onTap: () {
                      // Get the position of the tapped story circle
                      final RenderBox? box = itemContext.findRenderObject() as RenderBox?;
                      if (box != null) {
                        final position = box.localToGlobal(Offset.zero);
                        final center = Offset(
                          position.dx + (box.size.width / 2),
                          position.dy + (box.size.height / 2),
                        );

                        // Navigate with circular reveal animation
                        Navigator.of(context).push(
                          CircularRevealRoute(
                            clickPosition: center,
                            initialRadius: 35.0, // Story circle radius
                            child: StoryViewerScreen(
                              collections: storyController.storyList!,
                              initialIndex: index,
                              clickPosition: center,
                            ),
                          ),
                        );
                      }
                    },
                    child: Container(
                  width: 75,
                  margin: const EdgeInsets.only(
                    right: Dimensions.paddingSizeSmall,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: collection.hasUnseen == true
                              ? LinearGradient(
                                  colors: [
                                    Theme.of(context).primaryColor,
                                    Theme.of(context).primaryColor.withValues(alpha: 0.7),
                                  ],
                                  begin: Alignment.topRight,
                                  end: Alignment.bottomLeft,
                                )
                              : null,
                          border: collection.hasUnseen == false
                              ? Border.all(
                                  color: Colors.grey.withValues(alpha: 0.3),
                                  width: 2,
                                )
                              : null,
                        ),
                        padding: const EdgeInsets.all(3),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).cardColor,
                              width: 3,
                            ),
                          ),
                          child: ClipOval(
                            child: Builder(
                              builder: (context) {
                                // Debug logging to check what URLs we're getting
                                if (index == 0) { // Only log for first item to avoid spam
                                  print('🖼️ [STORY STRIP] Restaurant: ${restaurant.name}');
                                  print('🖼️ [STORY STRIP] Logo URL: ${restaurant.logoFullUrl}');
                                  print('🖼️ [STORY STRIP] Cover Photo URL: ${restaurant.coverPhotoFullUrl}');
                                }

                                // Try logo first, then cover photo as fallback
                                final imageUrl = (restaurant.logoFullUrl?.isNotEmpty == true)
                                    ? restaurant.logoFullUrl!
                                    : (restaurant.coverPhotoFullUrl?.isNotEmpty == true)
                                        ? restaurant.coverPhotoFullUrl!
                                        : null;

                                final blurhash = (restaurant.logoFullUrl?.isNotEmpty == true)
                                    ? restaurant.logoBlurhash
                                    : (restaurant.coverPhotoFullUrl?.isNotEmpty == true)
                                        ? restaurant.coverPhotoBlurhash
                                        : null;

                                return imageUrl != null
                                  ? BlurhashImageWidget(
                                      imageUrl: imageUrl,
                                      blurhash: blurhash,
                                      fit: BoxFit.cover,
                                      borderRadius: BorderRadius.circular(100),
                                    )
                                  : Container(
                                      color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
                                      child: Icon(Icons.restaurant, color: Theme.of(context).disabledColor),
                                    );
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                      Text(
                        restaurant.name ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildShimmer() {
    return Container(
      height: 110,
      padding: const EdgeInsets.only(
        bottom: Dimensions.paddingSizeExtraSmall,
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeDefault,
        ),
        itemCount: 8,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          return Container(
            width: 75,
            margin: const EdgeInsets.only(
              right: Dimensions.paddingSizeSmall,
            ),
            child: Column(
              children: [
                Shimmer(
                  duration: const Duration(seconds: 2),
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                Shimmer(
                  duration: const Duration(seconds: 2),
                  child: Container(
                    width: 50,
                    height: 10,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      height: 110,
      padding: const EdgeInsets.only(
        bottom: Dimensions.paddingSizeExtraSmall,
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeDefault,
        ),
        itemCount: 5,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          return Container(
            width: 75,
            margin: const EdgeInsets.only(
              right: Dimensions.paddingSizeSmall,
            ),
            child: Column(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                Container(
                  width: 50,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.grey.withOpacity(0.15),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
