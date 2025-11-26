import 'package:flutter/material.dart';
import 'package:godelivery_user/config/environment.dart';
import 'package:godelivery_user/features/explore/controllers/explore_controller.dart';
import 'package:godelivery_user/features/explore/widgets/explore_map_view_widget.dart';
import 'package:godelivery_user/features/explore/widgets/mapbox_explore_map_widget.dart';

/// Factory widget that selects between Google Maps and Mapbox based on environment config
class ExploreMapFactory extends StatelessWidget {
  final ExploreController exploreController;
  final VoidCallback? onFullscreenToggle;
  final Animation<Offset>? topButtonsAnimation;
  final Animation<double>? topButtonsFadeAnimation;

  const ExploreMapFactory({
    super.key,
    required this.exploreController,
    this.onFullscreenToggle,
    this.topButtonsAnimation,
    this.topButtonsFadeAnimation,
  });

  @override
  Widget build(BuildContext context) {
    if (Environment.useMapbox) {
      return MapboxExploreMapWidget(
        exploreController: exploreController,
        onFullscreenToggle: onFullscreenToggle,
        topButtonsAnimation: topButtonsAnimation,
        topButtonsFadeAnimation: topButtonsFadeAnimation,
      );
    }

    return ExploreMapViewWidget(
      exploreController: exploreController,
      onFullscreenToggle: onFullscreenToggle,
      topButtonsAnimation: topButtonsAnimation,
      topButtonsFadeAnimation: topButtonsFadeAnimation,
    );
  }
}
