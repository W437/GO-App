import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/features/developer/controllers/developer_catalog_controller.dart';
import 'package:godelivery_user/features/developer/widgets/catalog_item_card.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:godelivery_user/common/widgets/adaptive/navigation/custom_app_bar_widget.dart';
import 'package:godelivery_user/common/widgets/shared/feedback/custom_toast_widget.dart';

class DeveloperCatalogScreen extends StatefulWidget {
  const DeveloperCatalogScreen({super.key});

  @override
  State<DeveloperCatalogScreen> createState() => _DeveloperCatalogScreenState();
}

class _DeveloperCatalogScreenState extends State<DeveloperCatalogScreen> {
  final TextEditingController searchController = TextEditingController();
  late DeveloperCatalogController controller;

  @override
  void initState() {
    super.initState();
    Get.put(DeveloperCatalogController());
    controller = Get.find<DeveloperCatalogController>();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).cardColor,
      appBar: CustomAppBarWidget(
        title: 'Developer Catalog',
        isBackButtonExist: true,
        onBackPressed: () => Get.back(),
      ),
      body: Column(
        children: [
          // Developer Mode Banner with Test Buttons
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
            color: Colors.orange,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Expanded(
                  child: Text(
                    'DEVELOPER MODE - 71 Screens Available',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                // Toast test buttons
                IconButton(
                  icon: const Icon(Icons.notifications, color: Colors.white, size: 20),
                  onPressed: () {
                    debugPrint('Test button pressed - showing success toast');
                    showCustomSnackBar('Test success toast!', isError: false);
                  },
                  tooltip: 'Test Success Toast',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.error, color: Colors.white, size: 20),
                  onPressed: () {
                    debugPrint('Test button pressed - showing error toast');
                    showCustomSnackBar('Test error toast!', isError: true);
                  },
                  tooltip: 'Test Error Toast',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Search Bar
          Container(
            color: Theme.of(context).cardColor,
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            child: TextField(
              controller: searchController,
              onChanged: controller.updateSearchQuery,
              decoration: InputDecoration(
                hintText: 'Search screens by name or file path...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          controller.updateSearchQuery('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                ),
              ),
            ),
          ),

          // Module Filter Chips
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: controller.getModules().length,
              itemBuilder: (context, index) {
                final module = controller.getModules()[index];
                return Padding(
                  padding: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
                  child: Obx(() {
                    final isSelected = controller.selectedModule.value == module;
                    return FilterChip(
                      label: Text(module),
                      selected: isSelected,
                      onSelected: (_) => controller.selectModule(module),
                      backgroundColor: Theme.of(context).cardColor,
                      selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                      labelStyle: TextStyle(
                        color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).textTheme.bodyLarge?.color,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                        side: BorderSide(
                          color: isSelected ? Theme.of(context).primaryColor : Colors.grey.withValues(alpha: 0.3),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),

          // Filter Options Row
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeDefault,
              vertical: Dimensions.paddingSizeSmall,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Obx(() => IconButton(
                      icon: Icon(
                        controller.isGridView.value ? Icons.view_list : Icons.grid_view,
                      ),
                      onPressed: controller.toggleGridView,
                      tooltip: controller.isGridView.value ? 'List View' : 'Grid View',
                    )),

                    Obx(() => Row(
                      children: [
                        Checkbox(
                          value: controller.showAuthRequired.value,
                          onChanged: (_) => controller.toggleAuthFilter(),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        Text('Auth', style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall)),
                        const SizedBox(width: Dimensions.paddingSizeSmall),
                        Checkbox(
                          value: controller.showDataRequired.value,
                          onChanged: (_) => controller.toggleDataFilter(),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        Text('Data', style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall)),
                      ],
                    )),
                  ],
                ),

                Obx(() => Text(
                  '${controller.displayedScreens.length} screens',
                  style: robotoRegular.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    color: Theme.of(context).disabledColor,
                  ),
                )),
              ],
            ),
          ),

          const Divider(height: 1),

          // Screen List/Grid
          Expanded(
            child: Obx(() {
              if (controller.displayedScreens.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: Theme.of(context).disabledColor,
                      ),
                      const SizedBox(height: Dimensions.paddingSizeDefault),
                      Text(
                        'No screens found',
                        style: robotoMedium.copyWith(
                          fontSize: Dimensions.fontSizeLarge,
                          color: Theme.of(context).disabledColor,
                        ),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeSmall),
                      Text(
                        'Try adjusting your search or filters',
                        style: robotoRegular.copyWith(
                          color: Theme.of(context).disabledColor,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return controller.isGridView.value
                  ? GridView.builder(
                      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.2,
                        crossAxisSpacing: Dimensions.paddingSizeDefault,
                        mainAxisSpacing: Dimensions.paddingSizeDefault,
                      ),
                      itemCount: controller.displayedScreens.length,
                      itemBuilder: (context, index) {
                        return CatalogItemCard(
                          item: controller.displayedScreens[index],
                          isGridView: true,
                          onTap: () => controller.navigateToScreen(controller.displayedScreens[index]),
                          onCopyPath: () => _copyToClipboard(controller.displayedScreens[index].filePath),
                        );
                      },
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                      itemCount: controller.displayedScreens.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                          child: CatalogItemCard(
                            item: controller.displayedScreens[index],
                            isGridView: false,
                            onTap: () => controller.navigateToScreen(controller.displayedScreens[index]),
                            onCopyPath: () => _copyToClipboard(controller.displayedScreens[index].filePath),
                          ),
                        );
                      },
                    );
            }),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied: $text'),
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.green,
      ),
    );
  }
}