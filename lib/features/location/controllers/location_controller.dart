import 'package:godelivery_user/api/api_client.dart';
import 'package:godelivery_user/features/cart/controllers/cart_controller.dart';
import 'package:godelivery_user/features/checkout/controllers/checkout_controller.dart';
import 'package:godelivery_user/features/home/screens/home_screen.dart';
import 'package:godelivery_user/features/location/domain/models/prediction_model.dart';
import 'package:godelivery_user/features/location/domain/models/zone_list_model.dart';
import 'package:godelivery_user/features/splash/controllers/splash_controller.dart';
import 'package:godelivery_user/features/favourite/controllers/favourite_controller.dart';
import 'package:godelivery_user/features/location/domain/models/zone_response_model.dart';
import 'package:godelivery_user/features/address/domain/models/address_model.dart';
import 'package:godelivery_user/features/location/domain/services/location_service_interface.dart';
import 'package:godelivery_user/features/location/helper/zone_polygon_helper.dart';
import 'package:godelivery_user/helper/business_logic/address_helper.dart';
import 'package:godelivery_user/helper/business_logic/auth_helper.dart';
import 'package:godelivery_user/common/widgets/shared/feedback/custom_snackbar_widget.dart';
import 'package:godelivery_user/util/app_constants.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationController extends GetxController implements GetxService {
  final LocationServiceInterface locationServiceInterface;

  LocationController({required this.locationServiceInterface});

  Position _position = Position(longitude: 0, latitude: 0, timestamp: DateTime.now(), accuracy: 1, altitude: 1, heading: 1, speed: 1, speedAccuracy: 1, altitudeAccuracy: 1, headingAccuracy: 1);
  Position get position => _position;

  Position _pickPosition = Position(longitude: 0, latitude: 0, timestamp: DateTime.now(), accuracy: 1, altitude: 1, heading: 1, speed: 1, speedAccuracy: 1, altitudeAccuracy: 1, headingAccuracy: 1);
  Position get pickPosition => _pickPosition;

  bool _loading = false;
  bool get loading => _loading;

  String? _address = '';
  String? get address => _address;

  String? _pickAddress = '';
  String? get pickAddress => _pickAddress;

  int _addressTypeIndex = 0;
  int get addressTypeIndex => _addressTypeIndex;

  final List<String?> _addressTypeList = ['home', 'office', 'others'];
  List<String?> get addressTypeList => _addressTypeList;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _inZone = false;
  bool get inZone => _inZone;

  int _zoneID = 0;
  int get zoneID => _zoneID;

  bool _buttonDisabled = true;
  bool get buttonDisabled => _buttonDisabled;

  GoogleMapController? _mapController;
  GoogleMapController? get mapController => _mapController;

  List<PredictionModel> _predictionList = [];
  List<PredictionModel> get predictionList => _predictionList;

  List<ZoneListModel> _zoneList = [];
  List<ZoneListModel> get zoneList => _zoneList;

  bool _loadingZoneList = false;
  bool get loadingZoneList => _loadingZoneList;

  /// The currently active zone for browsing/filtering content.
  /// This is separate from the user's delivery address.
  /// Reactive variable - automatically updates UI when changed.
  final Rx<ZoneListModel?> _activeZone = Rx<ZoneListModel?>(null);
  ZoneListModel? get activeZone => _activeZone.value;

  /// Last current location result for display in location sheet
  String? _lastCurrentLocationResult;
  String? get lastCurrentLocationResult => _lastCurrentLocationResult;

  bool _lastCurrentLocationInZone = false;
  bool get lastCurrentLocationInZone => _lastCurrentLocationInZone;

  void setCurrentLocationResult(String? address, bool inZone) {
    _lastCurrentLocationResult = address;
    _lastCurrentLocationInZone = inZone;
    update();
  }

  void clearCurrentLocationResult() {
    _lastCurrentLocationResult = null;
    _lastCurrentLocationInZone = false;
    update();
  }

  bool _updateAddressData = true;
  bool _changeAddress = true;

  Future<AddressModel> getCurrentLocation(bool fromAddress, {GoogleMapController? mapController, LatLng? defaultLatLng, bool notify = true, bool showSnackBar = false}) async {
    _loading = true;
    if(notify) {
      update();
    }
    AddressModel addressModel;
    Position myPosition = await locationServiceInterface.getPosition(
      defaultLatLng,
      LatLng(
        double.parse(Get.find<SplashController>().configModel!.defaultLocation!.lat ?? '32.997473'),
        double.parse(Get.find<SplashController>().configModel!.defaultLocation!.lng ?? '35.144028'),
      ),
    );
    fromAddress ? _position = myPosition : _pickPosition = myPosition;

    locationServiceInterface.handleMapAnimation(mapController, myPosition);

    // Get address from geocode API
    String addressFromGeocode = await getAddressFromGeocode(LatLng(myPosition.latitude, myPosition.longitude));
    fromAddress ? _address = addressFromGeocode : _pickAddress = addressFromGeocode;

    // Check zone locally using polygon helper (no API call needed)
    final latLng = LatLng(myPosition.latitude, myPosition.longitude);
    final zoneId = ZonePolygonHelper.getZoneIdForPoint(latLng, _zoneList);
    final isInZone = zoneId != null;

    print('📍 [ZONE_CHECK] Local zone check: lat=${myPosition.latitude}, lng=${myPosition.longitude}');
    print('📍 [ZONE_CHECK] Zone ID: $zoneId, In Zone: $isInZone');

    // Get zone data if in zone
    ZoneData? zoneData;
    if (isInZone) {
      final zone = _zoneList.firstWhereOrNull((z) => z.id == zoneId);
      if (zone != null) {
        zoneData = ZoneData(
          id: zone.id,
          status: zone.status,
          minimumShippingCharge: zone.minimumShippingCharge,
          perKmShippingCharge: zone.perKmShippingCharge,
          maximumShippingCharge: zone.maximumShippingCharge,
          maxCodOrderAmount: zone.maxCodOrderAmount,
        );
      }
    }

    _inZone = isInZone;
    _zoneID = zoneId ?? 0;
    _buttonDisabled = !isInZone;

    addressModel = AddressModel(
      latitude: myPosition.latitude.toString(),
      longitude: myPosition.longitude.toString(),
      addressType: 'others',
      zoneId: zoneId ?? 0,
      zoneIds: zoneId != null ? [zoneId] : [],
      address: addressFromGeocode,
      zoneData: zoneData != null ? [zoneData] : [],
    );
    _loading = false;
    update();
    return addressModel;
  }

  Future<ZoneResponseModel> getZone(String? lat, String? long, bool markerLoad, {bool updateInAddress = false, bool showSnackBar = false}) async {
    // Guard against invalid coordinates (0,0 or null)
    if (lat == null || long == null || (lat == '0.0' && long == '0.0') || (double.tryParse(lat) == 0.0 && double.tryParse(long) == 0.0)) {
      print('⚠️ [LOCATION] Skipping zone check for invalid coordinates: lat=$lat, lng=$long');
      return ZoneResponseModel(false, 'Invalid coordinates', [], []);
    }

    if(markerLoad) {
      _loading = true;
    }else {
      _isLoading = true;
    }
    if(!updateInAddress){
      Future.delayed(Duration(seconds: 10), () {
        update();
      });

    }
    ZoneResponseModel responseModel = await locationServiceInterface.getZone(lat, long);
    _inZone = responseModel.isSuccess;
    _zoneID = responseModel.zoneIds.isNotEmpty ? responseModel.zoneIds[0] : 0;
    if(updateInAddress && responseModel.isSuccess) {
      AddressModel address = AddressHelper.getAddressFromSharedPref()!;
      address.zoneData = responseModel.zoneData;
      AddressHelper.saveAddressInSharedPref(address);
    }

    if(markerLoad) {
      _loading = false;
    }else {
      _isLoading = false;
    }
    update();
    return responseModel;
  }

  void makeLoadingOff() {
    _isLoading = false;
  }

  void updatePosition(CameraPosition? position, bool fromAddress) async {
    if(_updateAddressData) {
      _loading = true;
      update();
      if (fromAddress) {
        _position = Position(
          latitude: position!.target.latitude, longitude: position.target.longitude, timestamp: DateTime.now(),
          heading: 1, accuracy: 1, altitude: 1, speedAccuracy: 1, speed: 1, altitudeAccuracy: 1, headingAccuracy: 1,
        );
      } else {
        _pickPosition = Position(
          latitude: position!.target.latitude, longitude: position.target.longitude, timestamp: DateTime.now(),
          heading: 1, accuracy: 1, altitude: 1, speedAccuracy: 1, speed: 1, altitudeAccuracy: 1, headingAccuracy: 1,
        );
      }

      // Use local zone checking instead of API call for better performance
      final zoneId = ZonePolygonHelper.getZoneIdForPoint(
        LatLng(position.target.latitude, position.target.longitude),
        _zoneList,
      );
      _buttonDisabled = zoneId == null;
      _inZone = zoneId != null;

      if (_changeAddress) {
        String addressFromGeocode = await getAddressFromGeocode(LatLng(position.target.latitude, position.target.longitude));
        fromAddress ? _address = addressFromGeocode : _pickAddress = addressFromGeocode;
      } else {
        _changeAddress = true;
      }
      _loading = false;
      update();
    }else {
      _updateAddressData = true;
    }
  }

  void setAddressTypeIndex(int index, {bool notify = true}) {
    _addressTypeIndex = index;
    if(notify) {
      update();
    }
  }

  void saveAddressAndNavigate(AddressModel address, bool fromSignUp, String? route, bool canRoute, bool isDesktop, {ZoneResponseModel? zoneResponse}) {
    _prepareZoneData(address, fromSignUp, route, canRoute, isDesktop, zoneResponse: zoneResponse);
  }

  void _prepareZoneData(AddressModel address, bool fromSignUp, String? route, bool canRoute, bool isDesktop, {ZoneResponseModel? zoneResponse}) {
    // If zone response already provided, use it directly (avoid duplicate API call)
    if (zoneResponse != null && zoneResponse.isSuccess) {
      Get.find<CartController>().getCartDataOnline();
      address.zoneId = zoneResponse.zoneIds[0];
      address.zoneIds = [];
      address.zoneIds!.addAll(zoneResponse.zoneIds);
      address.zoneData = [];
      address.zoneData!.addAll(zoneResponse.zoneData);
      autoNavigate(address, fromSignUp, route, canRoute, isDesktop);
      return;
    }

    // Otherwise fetch zone data
    getZone(address.latitude, address.longitude, false).then((response) async {
      if (response.isSuccess) {
        Get.find<CartController>().getCartDataOnline();
        address.zoneId = response.zoneIds[0];
        address.zoneIds = [];
        address.zoneIds!.addAll(response.zoneIds);
        address.zoneData = [];
        address.zoneData!.addAll(response.zoneData);
        autoNavigate(address, fromSignUp, route, canRoute, isDesktop);
      } else {
        Get.back();
        showCustomSnackBar(response.message);
        if(route == 'splash') {
          Get.toNamed(RouteHelper.getPickMapRoute(route, false));
        }
      }
    });
  }

  void autoNavigate(AddressModel? address, bool fromSignUp, String? route, bool canRoute, bool isDesktop) async {
    locationServiceInterface.handleTopicSubscription(AddressHelper.getAddressFromSharedPref(), address);
    await AddressHelper.saveAddressInSharedPref(address!);
    if(AuthHelper.isLoggedIn() && !AuthHelper.isGuestLoggedIn() ) {
      // Fire and forget - already called in app_navigator, just refresh in background
      Get.find<FavouriteController>().getFavouriteList();
      updateZone();
    }
    if(route == 'splash' && Get.isDialogOpen!) {
      Get.back();
    }
    HomeScreen.loadData(true);
    Get.find<CheckoutController>().clearPrevData();
    locationServiceInterface.handleRoute(fromSignUp, route, canRoute);
  }

  Future<Position> setLocation(String placeID, String? address, GoogleMapController? mapController) async {
    _loading = true;
    update();

    LatLng latLng = await locationServiceInterface.getLatLng(placeID);

    _pickPosition = Position(
      latitude: latLng.latitude, longitude: latLng.longitude,
      timestamp: DateTime.now(), accuracy: 1, altitude: 1, heading: 1, speed: 1, speedAccuracy: 1, altitudeAccuracy: 1, headingAccuracy: 1,
    );
    _pickAddress = address;
    _changeAddress = false;

    if(mapController != null) {
      mapController.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: latLng, zoom: 16)));
    }
    _loading = false;
    update();
    return _pickPosition;
  }

  void disableButton() {
    _buttonDisabled = true;
    _inZone = true;
    update();
  }

  void addAddressData() {
    _position = _pickPosition;
    _address = _pickAddress;
    _updateAddressData = false;
    update();
  }

  void updateAddress(AddressModel address){
    _position = Position(
      latitude: double.parse(address.latitude!), longitude: double.parse(address.longitude!), timestamp: DateTime.now(),
      altitude: 1, heading: 1, speed: 1, speedAccuracy: 1, floor: 1, accuracy: 1, altitudeAccuracy: 1, headingAccuracy: 1,
    );
    _address = address.address;
    _addressTypeIndex = _addressTypeList.indexOf(address.addressType);
  }

  void setPickData() {
    _pickPosition = _position;
    _pickAddress = _address;
  }

  void clearPickAddress() {
    _pickAddress = '';
    update();
  }

  void setMapController(GoogleMapController mapController) {
    _mapController = mapController;
  }

  Future<String> getAddressFromGeocode(LatLng latLng) async {
    return await locationServiceInterface.getAddressFromGeocode(latLng);
  }

  Future<List<PredictionModel>> searchLocation(String text) async {
    _predictionList = [];
    if(text.isNotEmpty) {
      _predictionList = await locationServiceInterface.searchLocation(text);
    }
    return _predictionList;
  }

  void setPlaceMark(String address) {
    _address = address;
  }

  void checkPermission(Function onTap) {
    locationServiceInterface.checkLocationPermission(onTap);
  }

  Future<void> updateZone() async {
    await locationServiceInterface.updateZone();
  }

  /// Save a zone as the user's current address.
  /// Converts the zone to an AddressModel using the zone's center point.
  /// Used when user selects a zone from zone mode on the map.
  Future<void> saveZoneAsAddress(ZoneListModel zone, {bool refreshData = true}) async {
    // Get zone center from formatted coordinates
    final center = _getZoneCenter(zone);

    // Keep browsing zone in sync when user saves a zone as their address
    _activeZone.value = zone;

    // Geocode the center point for a human-readable address
    String addressStr = '';
    try {
      addressStr = await getAddressFromGeocode(center);
    } catch (e) {
      // Fallback to zone name if geocoding fails
      addressStr = zone.displayName ?? zone.name ?? 'Zone ${zone.id}';
    }

    // Convert ZoneListModel to ZoneData for AddressModel
    final zoneData = ZoneData(
      id: zone.id,
      status: zone.status,
      minimumShippingCharge: zone.minimumShippingCharge,
      perKmShippingCharge: zone.perKmShippingCharge,
      maximumShippingCharge: zone.maximumShippingCharge,
      maxCodOrderAmount: zone.maxCodOrderAmount,
      increasedDeliveryFee: zone.increasedDeliveryFee,
      increasedDeliveryFeeStatus: zone.increasedDeliveryFeeStatus,
      increaseDeliveryFeeMessage: zone.increaseDeliveryChargeMessage,
    );

    // Create address model with zone data
    final address = AddressModel(
      latitude: center.latitude.toString(),
      longitude: center.longitude.toString(),
      address: addressStr,
      addressType: 'zone',
      zoneId: zone.id,
      zoneIds: [zone.id!],
      zoneData: [zoneData],
    );

    // Handle topic subscription
    locationServiceInterface.handleTopicSubscription(
      AddressHelper.getAddressFromSharedPref(),
      address,
    );

    // Save address to shared preferences
    await AddressHelper.saveAddressInSharedPref(address);

    if (refreshData) {
      // Update API header with new zone
      await updateZone();
      // Refresh home data
      HomeScreen.loadData(true);
      Get.find<CheckoutController>().clearPrevData();
    }

    update();
  }

  /// Calculate the center point of a zone polygon
  LatLng _getZoneCenter(ZoneListModel zone) {
    final coords = zone.formattedCoordinates;
    if (coords == null || coords.isEmpty) {
      return const LatLng(0, 0);
    }

    double sumLat = 0, sumLng = 0;
    for (final c in coords) {
      sumLat += c.lat ?? 0;
      sumLng += c.lng ?? 0;
    }
    return LatLng(sumLat / coords.length, sumLng / coords.length);
  }

  Future<void> getZoneList() async {
    // Only show loading if zones aren't already loaded
    if (_zoneList.isEmpty) {
      _loadingZoneList = true;
      update();
    }
    try {
      _zoneList = await locationServiceInterface.getZoneList();
      print('Zone list loaded: ${_zoneList.length} zones');

      // Initialize activeZone from user's stored address if not already set
      if (_activeZone.value == null) {
        _initializeActiveZoneFromAddress();
      }
    } catch (e) {
      print('Error loading zone list: $e');
      _zoneList = [];
    } finally {
      _loadingZoneList = false;
      update();
    }
  }

  /// Initialize the active zone from the user's stored address.
  /// Called once when zone list loads to ensure header shows correct zone.
  void _initializeActiveZoneFromAddress() {
    final storedAddress = AddressHelper.getAddressFromSharedPref();
    if (storedAddress == null || storedAddress.zoneId == null) {
      print('🌍 [ZONE] No stored address/zone to initialize from');
      return;
    }

    // Find the zone in our list that matches the stored zoneId
    final matchingZone = _zoneList.firstWhereOrNull(
      (zone) => zone.id == storedAddress.zoneId,
    );

    if (matchingZone != null) {
      _activeZone.value = matchingZone;
      print('🌍 [ZONE] Initialized activeZone from stored address: ${matchingZone.displayName ?? matchingZone.name}');
    } else {
      print('🌍 [ZONE] Could not find zone ${storedAddress.zoneId} in zone list');
    }
  }

  /// Change the active browsing zone.
  /// This updates the zone used for filtering content (restaurants, banners, etc.)
  /// WITHOUT changing the user's delivery address.
  ///
  /// Use this when user wants to explore a different zone from the home screen.
  Future<void> changeZone(ZoneListModel zone) async {
    // Setting reactive variable automatically updates Obx listeners (header)
    _activeZone.value = zone;
    print('🌍 [ZONE] Changed to: ${zone.displayName ?? zone.name ?? "ID: ${zone.id}"}');

    // Calculate zone center for API coordinates
    final center = _getZoneCenter(zone);

    // Update API header with new zone
    final apiClient = Get.find<ApiClient>();
    final sharedPreferences = Get.find<SharedPreferences>();

    apiClient.updateHeader(
      sharedPreferences.getString(AppConstants.token),
      [zone.id!], // New zone ID
      sharedPreferences.getString(AppConstants.languageCode),
      center.latitude.toString(),
      center.longitude.toString(),
    );

    // Refresh all zone-dependent data
    await HomeScreen.loadData(true);

    // Clear checkout data since zone changed
    Get.find<CheckoutController>().clearPrevData();

    // Update other GetBuilder listeners
    update();
  }

  void selectZone(ZoneListModel zone) {
    if (zone.formattedCoordinates != null && zone.formattedCoordinates!.isNotEmpty) {
      // Calculate center point of the zone polygon for better positioning
      double totalLat = 0;
      double totalLng = 0;
      int count = zone.formattedCoordinates!.length;

      for (FormattedCoordinates coord in zone.formattedCoordinates!) {
        totalLat += coord.lat!;
        totalLng += coord.lng!;
      }

      double centerLat = totalLat / count;
      double centerLng = totalLng / count;

      _pickPosition = Position(
        latitude: centerLat, longitude: centerLng, timestamp: DateTime.now(),
        heading: 1, accuracy: 1, altitude: 1, speedAccuracy: 1, speed: 1, altitudeAccuracy: 1, headingAccuracy: 1,
      );
      _pickAddress = zone.displayName ?? zone.name ?? 'Selected Zone';
      _inZone = true;
      _zoneID = zone.id!;
      _buttonDisabled = false;

      if (_mapController != null) {
        _mapController!.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(centerLat, centerLng), zoom: 12)
        ));
      }

      update();
    }
  }

}
