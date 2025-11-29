import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/features/explore/controllers/explore_controller.dart';
import 'package:godelivery_user/features/explore/widgets/explore_map_factory.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  @override
  void initState() {
    super.initState();

    // Force controller initialization and reload restaurants for current zone
    // Schedule after build to avoid setState during build error
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<ExploreController>().getNearbyRestaurants(reload: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<ExploreController>(
        builder: (exploreController) {
          return ExploreMapFactory(
            exploreController: exploreController,
          );
        },
      ),
    );
  }
}
