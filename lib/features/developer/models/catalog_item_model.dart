enum ItemCategory { screen, widget, dialog }

class CatalogItemModel {
  final String itemName;
  final String filePath;
  final ItemCategory category;
  final String module;
  final bool requiresAuth;
  final bool requiresData;
  final bool isWebOnly;
  final Map<String, dynamic>? mockData;

  CatalogItemModel({
    required this.itemName,
    required this.filePath,
    required this.category,
    required this.module,
    this.requiresAuth = false,
    this.requiresData = false,
    this.isWebOnly = false,
    this.mockData,
  });
}