import 'dart:ui';

import 'package:godelivery_user/features/address/domain/models/address_model.dart';
import 'package:godelivery_user/features/checkout/controllers/checkout_controller.dart';
import 'package:godelivery_user/features/dashboard/domain/services/dashboard_service_interface.dart';
import 'package:godelivery_user/features/location/controllers/location_controller.dart';
import 'package:godelivery_user/helper/business_logic/address_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

typedef DashboardNavigationCallback = void Function(int pageIndex, Offset? tapPosition);

class DashboardController extends GetxController implements GetxService {
  final DashboardServiceInterface dashboardServiceInterface;
  DashboardController({required this.dashboardServiceInterface});

  DashboardNavigationCallback? _navigationCallback;

  bool _showLocationSuggestion = true;
  bool get showLocationSuggestion => _showLocationSuggestion;

  void hideSuggestedLocation(){
    _showLocationSuggestion = !_showLocationSuggestion;
  }

  Future<bool> checkLocationActive() async {
    bool isActiveLocation = await Geolocator.isLocationServiceEnabled();
    if(isActiveLocation) {
      AddressModel currentAddress = await Get.find<LocationController>().getCurrentLocation(true);
      AddressModel? selectedAddress = AddressHelper.getAddressFromSharedPref();

      double? distance = await Get.find<CheckoutController>().getDistanceInKM(
        LatLng(double.parse(currentAddress.latitude!), double.parse(currentAddress.longitude!)),
        LatLng(double.parse(selectedAddress!.latitude!), double.parse(selectedAddress.longitude!)),
        fromDashboard: true,
      );
      if (kDebugMode) {
        print('======== distance is : $distance');
      }
      return dashboardServiceInterface.checkDistanceForAddressPopup(distance);
    }else{
      return false;
    }
  }

  Future<bool> saveRegistrationSuccessfulSharedPref(bool status) async {
    return await dashboardServiceInterface.saveRegistrationSuccessful(status);
  }

  Future<bool> saveIsRestaurantRegistrationSharedPref(bool status) async {
    return await dashboardServiceInterface.saveIsRestaurantRegistration(status);
  }

  bool getRegistrationSuccessfulSharedPref() {
    return dashboardServiceInterface.getRegistrationSuccessful();
  }

  bool getIsRestaurantRegistrationSharedPref() {
    return dashboardServiceInterface.getIsRestaurantRegistration();
  }

  void registerNavigationCallback(DashboardNavigationCallback callback) {
    _navigationCallback = callback;
  }

  void unregisterNavigationCallback(DashboardNavigationCallback callback) {
    if (_navigationCallback == callback) {
      _navigationCallback = null;
    }
  }

  bool navigateToPage(int pageIndex, {Offset? tapPosition}) {
    final callback = _navigationCallback;
    if (callback != null) {
      callback(pageIndex, tapPosition);
      return true;
    }
    return false;
  }
}
