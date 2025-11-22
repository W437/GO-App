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
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';

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
    String addressFromGeocode = await getAddressFromGeocode(LatLng(myPosition.latitude, myPosition.longitude));
    fromAddress ? _address = addressFromGeocode : _pickAddress = addressFromGeocode;
    ZoneResponseModel responseModel = await getZone(myPosition.latitude.toString(), myPosition.longitude.toString(), true, showSnackBar: showSnackBar);
    _buttonDisabled = !responseModel.isSuccess;
    addressModel = AddressModel(
      latitude: myPosition.latitude.toString(), longitude: myPosition.longitude.toString(), addressType: 'others',
      zoneId: responseModel.isSuccess ? responseModel.zoneIds[0] : 0, zoneIds: responseModel.zoneIds,
      address: addressFromGeocode, zoneData: responseModel.zoneData,
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

  void saveAddressAndNavigate(AddressModel address, bool fromSignUp, String? route, bool canRoute, bool isDesktop) {
    _prepareZoneData(address, fromSignUp, route, canRoute, isDesktop);
  }

  void _prepareZoneData(AddressModel address, bool fromSignUp, String? route, bool canRoute, bool isDesktop) {
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
      await Get.find<FavouriteController>().getFavouriteList();
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

  Future<void> getZoneList() async {
    // Only show loading if zones aren't already loaded
    if (_zoneList.isEmpty) {
      _loadingZoneList = true;
      update();
    }
    try {
      _zoneList = await locationServiceInterface.getZoneList();
      print('Zone list loaded: ${_zoneList.length} zones');
    } catch (e) {
      print('Error loading zone list: $e');
      _zoneList = [];
    } finally {
      _loadingZoneList = false;
      update();
    }
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
