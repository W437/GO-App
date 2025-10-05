import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/features/explore/controllers/explore_controller.dart';
import 'package:godelivery_user/features/explore/widgets/category_filter_chips_widget.dart';
import 'package:godelivery_user/features/explore/widgets/explore_map_view_widget.dart';
import 'package:godelivery_user/features/explore/widgets/restaurant_list_view_widget.dart';
import 'package:godelivery_user/util/dimensions.dart';

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
            return Column(
              children: [
                // Top 50% - Map View
                Expanded(
                  flex: 1,
                  child: ExploreMapViewWidget(
                    exploreController: exploreController,
                  ),
                ),

                // Bottom 50% - Category Filter + Restaurant List
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Category Filter Chips
                        CategoryFilterChipsWidget(
                          exploreController: exploreController,
                        ),

                        const Divider(height: 1),

                        // Restaurant List
                        Expanded(
                          child: RestaurantListViewWidget(
                            exploreController: exploreController,
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
