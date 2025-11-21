import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart';
import 'package:godelivery_user/api/api_client.dart';
import 'package:godelivery_user/common/enums/data_source_enum.dart';
import 'package:godelivery_user/common/widgets/shared/feedback/custom_loader_widget.dart';
import 'package:godelivery_user/common/widgets/shared/feedback/custom_snackbar_widget.dart';
import 'package:godelivery_user/features/address/controllers/address_controller.dart';
import 'package:godelivery_user/features/address/domain/models/address_model.dart';
import 'package:godelivery_user/features/auth/controllers/auth_controller.dart';
import 'package:godelivery_user/features/location/controllers/location_controller.dart';
import 'package:godelivery_user/features/location/widgets/pick_map_dialog.dart';
import 'package:godelivery_user/features/notification/domain/models/notification_body_model.dart';
import 'package:godelivery_user/features/splash/domain/models/config_model.dart';
import 'package:godelivery_user/features/splash/domain/models/deep_link_body.dart';
import 'package:godelivery_user/features/splash/domain/services/splash_service_interface.dart';
import 'package:godelivery_user/features/splash/domain/services/config_service.dart';
import 'package:godelivery_user/helper/business_logic/address_helper.dart';
import 'package:godelivery_user/helper/utilities/maintance_helper.dart';
import 'package:godelivery_user/helper/ui/responsive_helper.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/helper/navigation/app_navigator.dart';
import 'package:godelivery_user/helper/navigation/splash_route_helper.dart'; // OLD - keeping for deprecated getConfigData()
import 'package:universal_html/html.dart' as html;

class SplashController extends GetxController implements GetxService {
  final SplashServiceInterface splashServiceInterface;
  late final ConfigService _configService;

  SplashController({required this.splashServiceInterface}) {
    _configService = ConfigService(splashServiceInterface);
  }

  ConfigModel? _configModel;
  ConfigModel? get configModel => _configModel;

  bool _firstTimeConnectionCheck = true;
  bool get firstTimeConnectionCheck => _firstTimeConnectionCheck;

  bool _hasConnection = true;
  bool get hasConnection => _hasConnection;

  bool _savedCookiesData = false;
  bool get savedCookiesData => _savedCookiesData;

  String? _htmlText;
  String? get htmlText => _htmlText;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _showReferBottomSheet = false;
  bool get showReferBottomSheet => _showReferBottomSheet;

  DateTime get currentTime => DateTime.now();

  // ═══════════════════════════════════════════════════════════════════════════
  // OLD ARCHITECTURE - DEPRECATED (keeping temporarily for reference/rollback)
  // ═══════════════════════════════════════════════════════════════════════════
  // This old method mixed config loading with navigation, causing bugs.
  // It has been replaced by:
  // - loadConfig() for data fetching
  // - AppNavigator for navigation
  //
  // All callsites have been migrated. This code can be removed after testing.
  // ═══════════════════════════════════════════════════════════════════════════

  @Deprecated('Use loadConfig() and AppNavigator.navigateOnAppLaunch() instead')
  Future<void> getConfigData({bool handleMaintenanceMode = false, DataSourceEnum source = DataSourceEnum.local, NotificationBodyModel? notificationBody, bool fromMainFunction = false, bool shouldNavigate = true}) async {
    _hasConnection = true;
    _savedCookiesData = getCookiesData();
    Response response;
    if(source == DataSourceEnum.local) {
      response = await splashServiceInterface.getConfigData(source: DataSourceEnum.local);
      // If local cache exists, handle it and fetch fresh data in background
      if(response.statusCode == 200) {
        _handleConfigResponse(response, handleMaintenanceMode, fromMainFunction, shouldNavigate: shouldNavigate, notificationBody: notificationBody, linkBody: null);
        // Refresh in background without blocking (but don't navigate again!)
        getConfigData(handleMaintenanceMode: handleMaintenanceMode, source: DataSourceEnum.client, shouldNavigate: false);
      } else {
        // No cache - must wait for API response
        response = await splashServiceInterface.getConfigData(source: DataSourceEnum.client);
        _handleConfigResponse(response, handleMaintenanceMode, fromMainFunction, shouldNavigate: shouldNavigate, notificationBody: notificationBody, linkBody: null);
      }
    } else {
      response = await splashServiceInterface.getConfigData(source: DataSourceEnum.client);
      _handleConfigResponse(response, handleMaintenanceMode, fromMainFunction, shouldNavigate: shouldNavigate, notificationBody: notificationBody, linkBody: null);
    }

  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NEW ARCHITECTURE: Separated config loading from navigation
  // ═══════════════════════════════════════════════════════════════════════════

  /// Load config data (pure data operation, no navigation)
  ///
  /// This is the NEW way to load config. It ONLY fetches and stores data,
  /// with NO navigation side effects.
  ///
  /// Use cases:
  /// - App initialization (main.dart)
  /// - Ensuring config exists before operations
  /// - Background refresh
  /// - After demo reset (followed by explicit navigation)
  ///
  /// Returns true if config was loaded successfully
  Future<bool> loadConfig({bool forceRefresh = false}) async {
    try {
      _savedCookiesData = getCookiesData();

      final config = forceRefresh
          ? await _configService.fetchConfig()
          : await _configService.fetchConfigCached();

      if (config != null) {
        _configModel = config;
        _hasConnection = true;

        // 🔍 DEBUG: Print loaded config
        print('═══════════════════════════════════════════════════════════');
        print('🔍 [CONFIG DEBUG] Configuration loaded successfully!');
        print('   Business Name: ${_configModel!.businessName ?? "N/A"}');
        if(_configModel!.centralizeLoginSetup != null) {
          print('📱 [CONFIG DEBUG] Centralize Login Setup:');
          print('   Manual Login: ${_configModel!.centralizeLoginSetup!.manualLoginStatus}');
          print('   OTP Login: ${_configModel!.centralizeLoginSetup!.otpLoginStatus}');
          print('   Social Login: ${_configModel!.centralizeLoginSetup!.socialLoginStatus}');
        }
        print('═══════════════════════════════════════════════════════════');

        update();
        _onRemoveLoader();
        return true;
      } else {
        _hasConnection = false;
        update();
        return false;
      }
    } catch (e) {
      print('❌ [CONFIG] Error loading config: $e');
      _hasConnection = false;
      update();
      return false;
    }
  }

  /// Refresh config in background (no side effects, no navigation)
  ///
  /// This forces a fresh fetch from the API without blocking.
  /// Used for keeping data fresh without disrupting user experience.
  ///
  /// Use cases:
  /// - Periodic background refresh
  /// - Pull-to-refresh in screens
  /// - Ensuring latest promotional content
  Future<void> refreshConfig() async {
    try {
      final freshConfig = await _configService.fetchConfig();
      if (freshConfig != null) {
        _configModel = freshConfig;
        print('✅ [CONFIG] Background refresh completed');
        update();
      }
    } catch (e) {
      print('⚠️ [CONFIG] Background refresh failed: $e');
      // Silent fail - don't disrupt user experience
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // OLD ARCHITECTURE SUPPORT METHODS - DEPRECATED
  // ═══════════════════════════════════════════════════════════════════════════
  // These methods support the deprecated getConfigData() above.
  // Can be removed after testing confirms migration was successful.
  // ═══════════════════════════════════════════════════════════════════════════

  @Deprecated('Part of old getConfigData() architecture')
  void _handleConfigResponse(Response response, bool handleMaintenanceMode, bool fromMainFunction, {required bool shouldNavigate, required NotificationBodyModel? notificationBody, required DeepLinkBody? linkBody}) {
    if(response.statusCode == 200) {
      _configModel = splashServiceInterface.prepareConfigData(response);
      if(_configModel != null) {
        // 🔍 DEBUG: Print loaded config
        print('═══════════════════════════════════════════════════════════');
        print('🔍 [CONFIG DEBUG] Configuration loaded successfully!');
        print('   Business Name: ${_configModel!.businessName ?? "N/A"}');
        if(_configModel!.centralizeLoginSetup != null) {
          print('📱 [CONFIG DEBUG] Centralize Login Setup:');
          print('   Manual Login: ${_configModel!.centralizeLoginSetup!.manualLoginStatus}');
          print('   OTP Login: ${_configModel!.centralizeLoginSetup!.otpLoginStatus}');
          print('   Social Login: ${_configModel!.centralizeLoginSetup!.socialLoginStatus}');
          print('   Google: ${_configModel!.centralizeLoginSetup!.googleLoginStatus}');
          print('   Facebook: ${_configModel!.centralizeLoginSetup!.facebookLoginStatus}');
          print('   Apple: ${_configModel!.centralizeLoginSetup!.appleLoginStatus}');
        } else {
          print('⚠️ [CONFIG DEBUG] centralizeLoginSetup is NULL!');
        }
        print('═══════════════════════════════════════════════════════════');

        // Only navigate if this is the initial load, not background refresh
        print('🚦 [NAVIGATION CHECK] shouldNavigate: $shouldNavigate');
        if(shouldNavigate) {
          print('✅ [NAVIGATION] Proceeding with navigation');
          if(!GetPlatform.isWeb){
            bool isMaintenanceMode = _configModel!.maintenanceMode!;
            bool isInMaintenance = MaintenanceHelper.isMaintenanceEnable();

            if (isInMaintenance && handleMaintenanceMode) {
              Get.offNamed(RouteHelper.getUpdateRoute(false));
            } else if (handleMaintenanceMode && ((Get.currentRoute.contains(RouteHelper.update) && !isMaintenanceMode) || !isInMaintenance)) {
              Get.offNamed(RouteHelper.getInitialRoute());
            }
          }
          if(fromMainFunction) {
            _mainConfigRouting();
          } else {
            route(notificationBody: notificationBody, linkBody: linkBody);
          }
        }
        _onRemoveLoader();
      }
    } else {
      if(response.statusText == ApiClient.noInternetMessage) {
        _hasConnection = false;
      }
    }

    update();
  }

  void _onRemoveLoader() {
    final preloader = html.document.querySelector('.preloader');
    if (preloader != null) {
      preloader.remove();
    }
  }

  @Deprecated('Part of old getConfigData() architecture')
  _mainConfigRouting() async {
    if(GetPlatform.isWeb) {
      bool isInMaintenance = MaintenanceHelper.isMaintenanceEnable();

      if (isInMaintenance) {
        Get.offNamed(RouteHelper.getUpdateRoute(false));
      }
    }
  }

  Future<bool> initSharedData() {
    return splashServiceInterface.initSharedData();
  }

  bool? showIntro() {
    return splashServiceInterface.showIntro();
  }

  void disableIntro() {
    splashServiceInterface.disableIntro();
  }

  void setFirstTimeConnectionCheck(bool isChecked) {
    _firstTimeConnectionCheck = isChecked;
  }

  void saveCookiesData(bool data) {
    splashServiceInterface.saveCookiesData(data);
    _savedCookiesData = true;
    update();
  }

  bool getCookiesData() {
    return splashServiceInterface.getCookiesData();
  }

  void cookiesStatusChange(String? data) {
    splashServiceInterface.cookiesStatusChange(data);
  }

  bool getAcceptCookiesStatus(String data) {
    return splashServiceInterface.getAcceptCookiesStatus(data);
  }

  Future<bool> subscribeMail(String email) async {
    _isLoading = true;
    bool isSuccess = false;
    update();
    isSuccess = await splashServiceInterface.subscribeMail(email);
    _isLoading = false;
    update();
    return isSuccess;
  }

  Future<void> navigateToLocationScreen(String page, {bool offNamed = false, bool offAll = false}) async {
    bool fromSignup = page == RouteHelper.signUp;
    bool fromHome = page == 'home';
    if(!fromHome && AddressHelper.getAddressFromSharedPref() != null) {
      Get.dialog(const CustomLoaderWidget(), barrierDismissible: false);
      Get.find<LocationController>().autoNavigate(
          AddressHelper.getAddressFromSharedPref(), fromSignup, null, false, ResponsiveHelper.isDesktop(Get.context)
      );
    }else if(Get.find<AuthController>().isLoggedIn()) {
      Get.dialog(const CustomLoaderWidget(), barrierDismissible: false);
      await Get.find<AddressController>().getAddressList();
      Get.back();
      if(Get.find<AddressController>().addressList != null && Get.find<AddressController>().addressList!.isEmpty) {
        if(ResponsiveHelper.isDesktop(Get.context)) {
          showGeneralDialog(context: Get.context!, pageBuilder: (_,__,___) {
            return SizedBox(
              height: 300, width: 300,
              child: PickMapDialog(
                fromSignUp: (page == RouteHelper.signUp), canRoute: false, fromAddAddress: false, route: null,
                // canTakeCurrentLocation: !AuthHelper.isLoggedIn(),
              ),
            );
          });
        } else {
          Get.toNamed(RouteHelper.getPickMapRoute(page, false));
        }
      }else {
        if(offNamed) {
          Get.offNamed(RouteHelper.getAccessLocationRoute(page));
        }else if(offAll) {
          Get.offAllNamed(RouteHelper.getAccessLocationRoute(page));
        }else {
          Get.toNamed(RouteHelper.getAccessLocationRoute(page));
        }
      }
    }else {
      if(ResponsiveHelper.isDesktop(Get.context)) {
        showGeneralDialog(context: Get.context!, pageBuilder: (_,__,___) {
          return SizedBox(
            height: 300, width: 300,
            child: PickMapDialog(
              fromSignUp: (page == RouteHelper.signUp), canRoute: false, fromAddAddress: false, route: null,
              // canTakeCurrentLocation: !fromHome,
            ),
          );
        });
      } else {
        _checkPermission(page);
      }
    }
  }

  void _checkPermission(String page) async {

    LocationPermission permission = await Geolocator.checkPermission();

    if(permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if(permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      Get.toNamed(RouteHelper.getPickMapRoute(page, false));
    } else {
      if(await _locationCheck()) {
        await Get.find<LocationController>().getCurrentLocation(false).then((value) {
          if (value.latitude != null) {
            _onPickAddressButtonPressed(Get.find<LocationController>(), page);
          }
        });
      } else {
        Get.toNamed(RouteHelper.getPickMapRoute(page, false));
      }
    }
  }

  Future<bool> _locationCheck() async {
    // bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    // if(!serviceEnabled) {
    //   await Geolocator.openLocationSettings();
    //   serviceEnabled = await Geolocator.isLocationServiceEnabled();
    // }
    Location location = Location();
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
    }
    return serviceEnabled;
  }

  void _onPickAddressButtonPressed(LocationController locationController, String page) {
    if(locationController.pickPosition.latitude != 0 && locationController.pickAddress!.isNotEmpty) {
      AddressModel address = AddressModel(
        latitude: locationController.pickPosition.latitude.toString(),
        longitude: locationController.pickPosition.longitude.toString(),
        addressType: 'others', address: locationController.pickAddress,
      );
      locationController.saveAddressAndNavigate(address, false, page, false, ResponsiveHelper.isDesktop(Get.context));
    } else {
      showCustomSnackBar('pick_an_address'.tr);
    }
  }

  void saveReferBottomSheetStatus(bool data) {
    splashServiceInterface.saveReferBottomSheetStatus(data);
    _showReferBottomSheet = data;
    update();
  }

  void getReferBottomSheetStatus(){
    _showReferBottomSheet = splashServiceInterface.getReferBottomSheetStatus();
  }

}