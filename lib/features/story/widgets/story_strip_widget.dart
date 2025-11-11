import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/features/story/controllers/story_controller.dart';
import 'package:godelivery_user/helper/route_helper.dart';
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
          padding: const EdgeInsets.symmetric(
            vertical: Dimensions.paddingSizeSmall,
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

              return GestureDetector(
                onTap: () {
                  Get.toNamed(
                    RouteHelper.getStoryViewerRoute(index),
                    arguments: {
                      'collections': storyController.storyList,
                      'initialIndex': index,
                    },
                  );
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
                            child: (restaurant.logoFullUrl?.isNotEmpty == true)
                              ? CachedNetworkImage(
                                  imageUrl: restaurant.logoFullUrl!,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
                                    child: Icon(Icons.restaurant, color: Theme.of(context).disabledColor),
                                  ),
                                )
                              : Container(
                                  color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
                                  child: Icon(Icons.restaurant, color: Theme.of(context).disabledColor),
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
          ),
        );
      },
    );
  }

  Widget _buildShimmer() {
    return Container(
      height: 110,
      padding: const EdgeInsets.symmetric(
        vertical: Dimensions.paddingSizeSmall,
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
      height: 115,
      padding: const EdgeInsets.symmetric(
        vertical: Dimensions.paddingSizeSmall,
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeDefault,
        ),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            width: 75,
            margin: const EdgeInsets.only(
              right: Dimensions.paddingSizeSmall,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.withValues(alpha: 0.1),
                      border: Border.all(
                        color: Theme.of(context).cardColor,
                        width: 3,
                      ),
                    ),
                    child: Icon(
                      Icons.restaurant,
                      color: Theme.of(context).disabledColor,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'No stories',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).disabledColor,
                        fontSize: 11,
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