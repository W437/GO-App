import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/features/explore/controllers/explore_controller.dart';
import 'package:godelivery_user/features/explore/widgets/draggable_restaurant_sheet.dart';
import 'package:godelivery_user/features/explore/widgets/explore_map_view_widget.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  @override
  void initState() {
    super.initState();
    // Controller initialization will happen via GetX dependency injection
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: GetBuilder<ExploreController>(
          builder: (exploreController) {
            return Stack(
              children: [
                // Full Screen Map View
                ExploreMapViewWidget(
                  exploreController: exploreController,
                ),

                // Draggable Restaurant Sheet
                DraggableRestaurantSheet(
                  exploreController: exploreController,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
