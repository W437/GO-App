import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:godelivery_user/common/models/restaurant_model.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:url_launcher/url_launcher.dart';

class RestaurantLocationMapWidget extends StatefulWidget {
  final Restaurant restaurant;

  const RestaurantLocationMapWidget({
    super.key,
    required this.restaurant,
  });

  @override
  State<RestaurantLocationMapWidget> createState() => _RestaurantLocationMapWidgetState();
}

class _RestaurantLocationMapWidgetState extends State<RestaurantLocationMapWidget> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  LatLng? _restaurantPosition;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  void _initializeMap() {
    if (widget.restaurant.latitude != null && widget.restaurant.longitude != null) {
      _restaurantPosition = LatLng(
        double.parse(widget.restaurant.latitude!),
        double.parse(widget.restaurant.longitude!),
      );
      _createMarker();
    }
  }

  Future<void> _createMarker() async {
    if (_restaurantPosition == null) return;

    try {
      // Use default marker with cyan/blue hue (matches primary color)
      final restaurantMarkerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan);

      setState(() {
        _markers.add(
          Marker(
            markerId: MarkerId('restaurant_${widget.restaurant.id}'),
            position: _restaurantPosition!,
            icon: restaurantMarkerIcon,
            infoWindow: InfoWindow(
              title: widget.restaurant.name,
              snippet: widget.restaurant.address,
            ),
          ),
        );
      });
    } catch (e) {
      debugPrint('Error creating marker: $e');
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _openInMaps() async {
    if (_restaurantPosition == null) return;

    final String googleMapsUrl =
        'https://www.google.com/maps/search/?api=1&query=${_restaurantPosition!.latitude},${_restaurantPosition!.longitude}';

    final Uri uri = Uri.parse(googleMapsUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_restaurantPosition == null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_off,
                size: 48,
                color: Theme.of(context).hintColor,
              ),
              const SizedBox(height: 8),
              Text(
                'Location not available',
                style: TextStyle(color: Theme.of(context).hintColor),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _restaurantPosition!,
            zoom: 15.0,
          ),
          markers: _markers,
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
          },
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: false,
          liteModeEnabled: false,
          mapType: MapType.normal,
          onTap: (_) => _openInMaps(),
        ),
      ),
    );
  }
}
