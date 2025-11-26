import 'package:godelivery_user/common/models/restaurant_model.dart';

/// Response model for /api/v1/restaurants/map-explore endpoint
class MapExploreResponse {
  int? totalCount;
  List<int>? zoneIds;
  List<Restaurant>? restaurants;

  MapExploreResponse({
    this.totalCount,
    this.zoneIds,
    this.restaurants,
  });

  MapExploreResponse.fromJson(Map<String, dynamic> json) {
    totalCount = json['total_count'];
    if (json['zone_ids'] != null) {
      zoneIds = List<int>.from(json['zone_ids']);
    }
    if (json['restaurants'] != null) {
      restaurants = [];
      json['restaurants'].forEach((v) {
        restaurants!.add(Restaurant.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['total_count'] = totalCount;
    data['zone_ids'] = zoneIds;
    if (restaurants != null) {
      data['restaurants'] = restaurants!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}
