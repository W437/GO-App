import 'package:godelivery_user/api/api_client.dart';
import 'package:godelivery_user/features/location/domain/models/zone_response_model.dart';
import 'package:godelivery_user/features/address/domain/models/zone_model.dart';
import 'package:godelivery_user/features/location/domain/reposotories/location_repo_interface.dart';
import 'package:godelivery_user/util/app_constants.dart';
import 'package:godelivery_user/common/widgets/custom_snackbar_widget.dart';
import 'package:get/get.dart';
import 'package:get/get_connect/http/src/response/response.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationRepo implements LocationRepoInterface {
  final ApiClient apiClient;
  LocationRepo({required this.apiClient});

  @override
  Future<ZoneResponseModel> getZone(String? lat, String? lng) async {
    Response response = await apiClient.getData('${AppConstants.zoneUri}?lat=$lat&lng=$lng', handleError: false);
    if(response.statusCode == 200) {
      ZoneResponseModel responseModel;
      List<int>? zoneIds = ZoneModel.fromJson(response.body).zoneIds;
      List<ZoneData>? zoneData = ZoneModel.fromJson(response.body).zoneData;
      responseModel = ZoneResponseModel(true, '' , zoneIds ?? [], zoneData??[]);
      return responseModel;
    } else {
      return ZoneResponseModel(false, response.statusText, [], []);
    }
  }

  @override
  Future<String> getAddressFromGeocode(LatLng latLng) async {
    Response response = await apiClient.getData('${AppConstants.geocodeUri}?lat=${latLng.latitude}&lng=${latLng.longitude}');
    String address = 'Unknown Location Found';
    if(response.statusCode == 200 && response.body['status'] == 'OK') {
      address = response.body['results'][0]['formatted_address'].toString();
    }else {
      showCustomSnackBar(response.body['error_message'] ?? response.bodyString);
    }
    return address;
  }

  // @override
  // Future<dynamic> get({LatLng? latLng, bool isZone = false}) {
  //   if(isZone) {
  //     _getZone(latLng!.latitude.toString(), latLng.longitude.toString());
  //   } else {
  //     _getAddressFromGeocode(latLng!);
  //   }
  // }


  @override
  Future<Response> searchLocation(String text) async {
    return await apiClient.getData('${AppConstants.searchLocationUri}?search_text=$text');
  }

  Future<Response> getById(int id) async {
    Response response = await apiClient.getData('${AppConstants.placeDetailsUri}?placeid=$id');
    return response;
  }

  @override
  Future<Response> updateZone() async {
    return await apiClient.getData(AppConstants.updateZoneUri);
  }

  @override
  Future getList({int? offset}) {
    throw UnimplementedError();
  }

  @override
  Future add(value) {
    throw UnimplementedError();
  }

  @override
  Future delete(int? id) {
    throw UnimplementedError();
  }

  @override
  Future<Response> get(String? id) async {
    Response response = await apiClient.getData('${AppConstants.placeDetailsUri}?placeid=$id');
    return response;
  }

  @override
  Future update(Map<String, dynamic> body, int? id) {
    throw UnimplementedError();
  }

  @override
  Future<Response> getZoneList() async {
    try {
      print('Fetching zone list from: ${AppConstants.zoneListUri}');
      Response response = await apiClient.getData(AppConstants.zoneListUri);
      print('Zone list response received - status: ${response.statusCode}, body type: ${response.body.runtimeType}');
      print('Response statusText: ${response.statusText}');
      if (response.body != null) {
        print('Zone list body length: ${response.body is List ? (response.body as List).length : 'not a list'}');
        if (response.body is! List) {
          print('Zone list body content: ${response.body}');
        }
      } else {
        print('Zone list body is null!');
      }
      return response;
    } catch (e, stackTrace) {
      print('EXCEPTION in getZoneList: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

}
