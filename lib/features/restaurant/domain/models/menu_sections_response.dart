/// Response model for /api/v1/restaurants/{restaurant_id}/menu-sections endpoint
/// Contains lightweight section metadata without full product data
class MenuSectionsResponse {
  int? restaurantId;
  int? totalSections;
  List<MenuSectionMeta>? sections;

  MenuSectionsResponse({
    this.restaurantId,
    this.totalSections,
    this.sections,
  });

  MenuSectionsResponse.fromJson(Map<String, dynamic> json) {
    restaurantId = json['restaurant_id'];
    totalSections = json['total_sections'];
    if (json['sections'] != null) {
      sections = [];
      json['sections'].forEach((v) {
        sections!.add(MenuSectionMeta.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['restaurant_id'] = restaurantId;
    data['total_sections'] = totalSections;
    if (sections != null) {
      data['sections'] = sections!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

/// Lightweight menu section metadata (without products)
class MenuSectionMeta {
  int? id;
  String? name;
  String? slug;
  int? position;
  int? productCount;

  MenuSectionMeta({
    this.id,
    this.name,
    this.slug,
    this.position,
    this.productCount,
  });

  MenuSectionMeta.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    slug = json['slug'];
    position = json['position'];
    productCount = json['product_count'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['slug'] = slug;
    data['position'] = position;
    data['product_count'] = productCount;
    return data;
  }
}
