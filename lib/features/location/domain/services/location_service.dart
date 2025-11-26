import 'package:godelivery_user/features/location/domain/models/prediction_model.dart';
import 'package:godelivery_user/features/location/domain/models/zone_response_model.dart';
import 'package:godelivery_user/features/location/domain/models/zone_list_model.dart';
import 'package:godelivery_user/features/address/domain/models/address_model.dart';
import 'package:godelivery_user/features/location/domain/reposotories/location_repo_interface.dart';
import 'package:godelivery_user/features/location/domain/services/location_service_interface.dart';
import 'package:godelivery_user/features/location/widgets/permission_dialog.dart';
import 'package:godelivery_user/features/splash/controllers/splash_controller.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:godelivery_user/common/widgets/shared/feedback/custom_snackbar_widget.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:godelivery_user/util/app_constants.dart';

class LocationService implements LocationServiceInterface{
  final LocationRepoInterface locationRepoInterface;
  LocationService({required this.locationRepoInterface});

  @override
  Future<Position> getPosition(LatLng? defaultLatLng, LatLng configLatLng) async {
    Position myPosition;
    try {
      print('📍 [LOCATION] Requesting permission...');
      await Geolocator.requestPermission();

      print('📍 [LOCATION] Getting current position...');
      final stopwatch = Stopwatch()..start();

      // Try to get last known position first (instant)
      Position? lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        final age = DateTime.now().difference(lastKnown.timestamp);
        print('📍 [LOCATION] Last known position (age: ${age.inSeconds}s): ${lastKnown.latitude}, ${lastKnown.longitude}');

        // If last known position is less than 2 minutes old, use it immediately
        if (age.inMinutes < 2) {
          print('📍 [LOCATION] Using recent last known position (${stopwatch.elapsedMilliseconds}ms)');
          return lastKnown;
        }
      }

      // Get fresh position with high accuracy
      Position newLocalData = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15), // Timeout after 15 seconds
        ),
      );

      print('📍 [LOCATION] Got current position in ${stopwatch.elapsedMilliseconds}ms');
      print('📍 [LOCATION] Current: ${newLocalData.latitude}, ${newLocalData.longitude}');
      stopwatch.stop();

      myPosition = newLocalData;
    } catch(e) {
      print('📍 [LOCATION] Error getting position: $e');
      myPosition = Position(
        latitude: defaultLatLng != null ? defaultLatLng.latitude : configLatLng.latitude,
        longitude: defaultLatLng != null ? defaultLatLng.longitude : configLatLng.longitude,
        timestamp: DateTime.now(), accuracy: 1, altitude: 1, heading: 1, speed: 1, speedAccuracy: 1, altitudeAccuracy: 1, headingAccuracy: 1,
      );
    }
    return myPosition;
  }

  @override
  Future<ZoneResponseModel> getZone(String? lat, String? lng) async {
    return await locationRepoInterface.getZone(lat, lng);
  }

  @override
  void handleTopicSubscription(AddressModel? savedAddress, AddressModel? address) {
    if(!GetPlatform.isWeb) {
      if (savedAddress != null) {
        if(savedAddress.zoneIds != null) {
          for(int zoneID in savedAddress.zoneIds!) {
            FirebaseMessaging.instance.unsubscribeFromTopic('zone_${zoneID}_customer');
          }
        }else {
          FirebaseMessaging.instance.unsubscribeFromTopic('zone_${savedAddress.zoneId}_customer');
        }
      } else {
        FirebaseMessaging.instance.subscribeToTopic('zone_${address!.zoneId}_customer');
      }
      if(address!.zoneIds != null) {
        for(int zoneID in address.zoneIds!) {
          FirebaseMessaging.instance.subscribeToTopic('zone_${zoneID}_customer');
        }
      }else {
        FirebaseMessaging.instance.subscribeToTopic('zone_${address.zoneId}_customer');
      }
    }
  }

  @override
  Future<LatLng> getLatLng(String id) async {
    LatLng latLng = const LatLng(0, 0);
    Response? response = await locationRepoInterface.get(id);
    if(response?.statusCode == 200) {
      /*PlaceDetailsModel placeDetails = PlaceDetailsModel.fromJson(response?.body);
      if(placeDetails.status == 'OK') {
        latLng = LatLng(placeDetails.result!.geometry!.location!.lat!, placeDetails.result!.geometry!.location!.lng!);
      }*/
      final data = response?.body;
      final location = data['location'];
      final double lat = location['latitude'];
      final double lng = location['longitude'];
      latLng = LatLng(lat, lng);
    }
    return latLng;
  }

  @override
  Future<String> getAddressFromGeocode(LatLng latLng) async {
    return await locationRepoInterface.getAddressFromGeocode(latLng);
  }

  @override
  Future<List<PredictionModel>> searchLocation(String text) async {
    List<PredictionModel> predictionList = [];
    Response response = await locationRepoInterface.searchLocation(text);
    if (response.statusCode == 200 /*&& response.body['status'] == 'OK'*/) {
      predictionList = [];
      response.body['suggestions'].forEach((prediction) => predictionList.add(PredictionModel.fromJson(prediction)));
    } else {
      showCustomSnackBar(response.body['error_message'] ?? response.bodyString);
    }
    return predictionList;
  }

  @override
  void checkLocationPermission(Function onTap) async {
    LocationPermission permission = await Geolocator.checkPermission();
    if(permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if(permission == LocationPermission.denied) {
      showCustomSnackBar('you_have_to_allow'.tr);
    }else if(permission == LocationPermission.deniedForever) {
      Get.dialog(const PermissionDialog());
    }else {
      onTap();
    }
  }

  @override
  void handleRoute(bool fromSignUp, String? route, bool canRoute) {
    if(fromSignUp) {
      Get.offAllNamed(RouteHelper.getInterestRoute());
    }else {
      if(route != null && canRoute) {
        Get.offAllNamed(route);
      } else {
        Get.offAllNamed(RouteHelper.getInitialRoute());
      }
    }
  }

  @override
  void handleMapAnimation(GoogleMapController? mapController, Position myPosition) {
    if (mapController != null) {
      mapController.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(myPosition.latitude, myPosition.longitude), zoom: 16),
      ));
    }
  }

  @override
  Future<void> updateZone() async {
     await locationRepoInterface.updateZone();
  }

  @override
  Future<List<ZoneListModel>> getZoneList() async {
    List<ZoneListModel> zoneList = [];
    try {
      Response response = await locationRepoInterface.getZoneList();
      print('Zone list API response status: ${response.statusCode}');
      print('Zone list API response body type: ${response.body.runtimeType}');

      if (response.statusCode == 200) {
        if (response.body is List) {
          response.body.forEach((zone) {
            zoneList.add(ZoneListModel.fromJson(zone));
          });
        } else {
          print('Unexpected response body type: ${response.body}');
        }
      } else {
        print('Zone list API error: ${response.statusText}');
      }
    } catch (e, stackTrace) {
      print('Error fetching zone list: $e');
      print('Stack trace: $stackTrace');
    }
    return zoneList;
  }

}