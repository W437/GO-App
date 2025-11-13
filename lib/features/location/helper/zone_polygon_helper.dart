import 'package:flutter/material.dart';
import 'package:godelivery_user/features/location/domain/models/zone_list_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ZonePolygonHelper {
  const ZonePolygonHelper._();

  static Set<Polygon> buildPolygons({
    required List<ZoneListModel> zones,
    required Color strokeColor,
    required Color fillColor,
  }) {
    final polygons = <Polygon>{};

    for (final zone in zones) {
      if (zone.formattedCoordinates == null || zone.formattedCoordinates!.isEmpty) {
        continue;
      }

      final points = <LatLng>[];
      for (final coord in zone.formattedCoordinates!) {
        if (coord.lat == null || coord.lng == null) {
          continue;
        }
        points.add(LatLng(coord.lat!, coord.lng!));
      }

      if (points.length < 3) {
        continue;
      }

      polygons.add(Polygon(
        polygonId: PolygonId('zone_${zone.id ?? polygons.length}'),
        points: points,
        strokeWidth: 2,
        strokeColor: strokeColor,
        fillColor: fillColor,
      ));
    }

    return polygons;
  }
}
