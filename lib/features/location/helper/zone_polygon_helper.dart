import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:godelivery_user/features/location/domain/models/zone_list_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ZonePolygonHelper {
  const ZonePolygonHelper._();

  static Set<Polygon> buildPolygons({
    required List<ZoneListModel> zones,
    required Color baseColor,
    double strokeOpacity = 0.9,
    double fillOpacity = 0.12,
    double hueStep = 18,
  }) {
    final polygons = <Polygon>{};

    for (int index = 0; index < zones.length; index++) {
      final zone = zones[index];
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

      final colorVariant = _colorForZone(baseColor, zone.id ?? index, hueStep: hueStep);

      polygons.add(Polygon(
        polygonId: PolygonId('zone_${zone.id ?? polygons.length}'),
        points: points,
        strokeWidth: 3,
        strokeColor: colorVariant.withOpacity(strokeOpacity.clamp(0.0, 1.0)),
        fillColor: colorVariant.withOpacity(fillOpacity.clamp(0.0, 1.0)),
        consumeTapEvents: false,
        geodesic: true,
      ));
    }

    return polygons;
  }

  static Color _colorForZone(Color baseColor, int seed, {double hueStep = 18}) {
    final hsl = HSLColor.fromColor(baseColor);
    final hueOffset = (seed * hueStep) % 360;
    final adjustedHue = (hsl.hue + hueOffset) % 360;
    final lightness = math.max(0.35, math.min(0.65, hsl.lightness + 0.05));
    return HSLColor.fromAHSL(hsl.alpha, adjustedHue, hsl.saturation * 0.9, lightness).toColor();
  }
}
