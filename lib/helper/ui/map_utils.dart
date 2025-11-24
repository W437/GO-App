import 'package:google_maps_flutter/google_maps_flutter.dart' as google;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;

/// Utility class for map coordinate conversions between Google Maps and Mapbox
class MapUtils {
  MapUtils._();

  /// Convert Google Maps LatLng to Mapbox Position
  static mapbox.Position toMapboxPosition(google.LatLng latLng) {
    return mapbox.Position(latLng.longitude, latLng.latitude);
  }

  /// Convert Mapbox Position to Google Maps LatLng
  static google.LatLng toGoogleLatLng(mapbox.Position position) {
    return google.LatLng(position.lat.toDouble(), position.lng.toDouble());
  }

  /// Convert Google Maps LatLng to Mapbox Point
  static mapbox.Point toMapboxPoint(google.LatLng latLng) {
    return mapbox.Point(
      coordinates: mapbox.Position(latLng.longitude, latLng.latitude),
    );
  }

  /// Convert Mapbox Point to Google Maps LatLng
  static google.LatLng pointToGoogleLatLng(mapbox.Point point) {
    return google.LatLng(
      point.coordinates.lat.toDouble(),
      point.coordinates.lng.toDouble(),
    );
  }

  /// Convert a list of Google Maps LatLng to Mapbox Positions
  static List<mapbox.Position> toMapboxPositions(List<google.LatLng> latLngs) {
    return latLngs.map(toMapboxPosition).toList();
  }

  /// Convert a list of Mapbox Positions to Google Maps LatLngs
  static List<google.LatLng> toGoogleLatLngs(List<mapbox.Position> positions) {
    return positions.map(toGoogleLatLng).toList();
  }

  /// Convert Google Maps CameraPosition to Mapbox CameraOptions
  static mapbox.CameraOptions toMapboxCameraOptions(
    google.CameraPosition cameraPosition,
  ) {
    return mapbox.CameraOptions(
      center: toMapboxPoint(cameraPosition.target),
      zoom: cameraPosition.zoom,
      bearing: cameraPosition.bearing,
      pitch: cameraPosition.tilt,
    );
  }
}
