import 'package:godelivery_user/common/models/restaurant_model.dart';

/// Model for the home feed API response
/// GET /api/v1/restaurants/home-feed
class HomeFeedModel {
  final HomeFeedSection? advertised;
  final HomeFeedSection? newRestaurants;
  final HomeFeedSection? popular;
  final List<HomeFeedCategorySection>? categories;

  HomeFeedModel({
    this.advertised,
    this.newRestaurants,
    this.popular,
    this.categories,
  });

  factory HomeFeedModel.fromJson(Map<String, dynamic> json) {
    return HomeFeedModel(
      advertised: json['advertised'] != null
          ? HomeFeedSection.fromJson(json['advertised'])
          : null,
      newRestaurants: json['new_restaurants'] != null
          ? HomeFeedSection.fromJson(json['new_restaurants'])
          : null,
      popular: json['popular'] != null
          ? HomeFeedSection.fromJson(json['popular'])
          : null,
      categories: json['categories'] != null
          ? (json['categories'] as List)
              .map((e) => HomeFeedCategorySection.fromJson(e))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'advertised': advertised?.toJson(),
      'new_restaurants': newRestaurants?.toJson(),
      'popular': popular?.toJson(),
      'categories': categories?.map((e) => e.toJson()).toList(),
    };
  }
}

/// Generic section model for home feed sections
class HomeFeedSection {
  final String? title;
  final List<Restaurant>? restaurants;
  final int? total;
  final int? limit;
  final int? offset;
  final bool? hasMore;

  HomeFeedSection({
    this.title,
    this.restaurants,
    this.total,
    this.limit,
    this.offset,
    this.hasMore,
  });

  factory HomeFeedSection.fromJson(Map<String, dynamic> json) {
    return HomeFeedSection(
      title: json['title'],
      restaurants: json['restaurants'] != null
          ? (json['restaurants'] as List)
              .map((e) => Restaurant.fromJson(e))
              .toList()
          : null,
      total: json['total'],
      limit: json['limit'],
      offset: json['offset'],
      hasMore: json['has_more'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'restaurants': restaurants?.map((e) => e.toJson()).toList(),
      'total': total,
      'limit': limit,
      'offset': offset,
      'has_more': hasMore,
    };
  }
}

/// Category section model with category ID
class HomeFeedCategorySection extends HomeFeedSection {
  final int? id;
  final String? name;

  HomeFeedCategorySection({
    this.id,
    this.name,
    super.title,
    super.restaurants,
    super.total,
    super.limit,
    super.offset,
    super.hasMore,
  });

  factory HomeFeedCategorySection.fromJson(Map<String, dynamic> json) {
    return HomeFeedCategorySection(
      id: json['id'],
      name: json['name'],
      title: json['title'] ?? json['name'],
      restaurants: json['restaurants'] != null
          ? (json['restaurants'] as List)
              .map((e) => Restaurant.fromJson(e))
              .toList()
          : null,
      total: json['total'],
      limit: json['limit'],
      offset: json['offset'],
      hasMore: json['has_more'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      ...super.toJson(),
    };
  }
}

/// Model for paginated section response
/// GET /api/v1/restaurants/home-feed/section/{section}/{category_id?}
class HomeFeedSectionResponse {
  final String? section;
  final List<Restaurant>? restaurants;
  final int? total;
  final int? limit;
  final int? offset;
  final bool? hasMore;

  HomeFeedSectionResponse({
    this.section,
    this.restaurants,
    this.total,
    this.limit,
    this.offset,
    this.hasMore,
  });

  factory HomeFeedSectionResponse.fromJson(Map<String, dynamic> json) {
    return HomeFeedSectionResponse(
      section: json['section'],
      restaurants: json['restaurants'] != null
          ? (json['restaurants'] as List)
              .map((e) => Restaurant.fromJson(e))
              .toList()
          : null,
      total: json['total'],
      limit: json['limit'],
      offset: json['offset'],
      hasMore: json['has_more'],
    );
  }
}
