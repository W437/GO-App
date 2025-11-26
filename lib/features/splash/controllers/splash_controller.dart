import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart';
import 'package:godelivery_user/api/api_client.dart';
import 'package:godelivery_user/common/widgets/shared/feedback/custom_loader_widget.dart';
import 'package:godelivery_user/common/widgets/shared/feedback/custom_toast_widget.dart';
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
import 'package:godelivery_user/features/app_data/controllers/app_data_controller.dart';
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

  // Progress tracking for splash data loading
  double _loadingProgress = 0.0;
  double get loadingProgress => _loadingProgress;

  String _loadingMessage = '';
  String get loadingMessage => _loadingMessage;

  bool _dataLoadingComplete = false;
  bool get dataLoadingComplete => _dataLoadingComplete;

  bool _dataLoadingFailed = false;
  bool get dataLoadingFailed => _dataLoadingFailed;

  String _dataLoadingError = '';
  String get dataLoadingError => _dataLoadingError;

  DateTime get currentTime => DateTime.now();

  /// Check if we should load data during splash
  /// Returns true ONLY if the user is a returning user (Intro done + Address saved)
  /// This prevents wasting bandwidth for fresh installs who need to go through onboarding
  bool get shouldLoadData {
    final bool introShown = showIntro() ?? true; // Default to true (show intro) if null
    final bool hasAddress = AddressHelper.getAddressFromSharedPref() != null;
    
    // If intro is NOT shown (meaning it's done) AND we have an address,
    // then it's a returning user who goes straight to home. Load data!
    return !introShown && hasAddress;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // OLD ARCHITECTURE - REMOVED
  // ═══════════════════════════════════════════════════════════════════════════
  // The deprecated getConfigData() method has been removed.
  // Use loadConfig() and AppNavigator.navigateOnAppLaunch() instead.
  // ═══════════════════════════════════════════════════════════════════════════

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

  /// Load all application data during splash screen
  /// Returns true if successful, false if failed
  /// Delegates to AppDataController for actual loading
  Future<bool> loadAllData({bool useCache = true}) async {
    try {
      print('🚀 [SPLASH] Starting data load via AppDataController...');

      _dataLoadingComplete = false;
      _dataLoadingFailed = false;
      _loadingProgress = 0.0;
      _loadingMessage = 'Initializing...';
      update();

      // Config must be loaded first
      if (_configModel == null) {
        print('⚠️ [SPLASH] Config not loaded, loading now...');
        final configLoaded = await loadConfig();
        if (!configLoaded) {
          _dataLoadingFailed = true;
          _dataLoadingError = 'Failed to load configuration';
          update();
          return false;
        }
      }

      // Use AppDataController for loading
      final appDataController = Get.find<AppDataController>();

      // Subscribe to progress updates
      appDataController.addListener(() {
        _loadingProgress = appDataController.loadingProgress;
        _loadingMessage = appDataController.loadingMessage;

        if (appDataController.hasError) {
          _dataLoadingFailed = true;
          _dataLoadingError = appDataController.errorMessage;
        }

        update();
      });

      final success = await appDataController.loadInitialData();

      if (success) {
        _dataLoadingComplete = true;
        _loadingProgress = 100.0;
        _loadingMessage = 'Ready!';
        print('✅ [SPLASH] All data loaded successfully');
      } else {
        _dataLoadingFailed = true;
        if (_dataLoadingError.isEmpty) {
          _dataLoadingError = 'Failed to load application data';
        }
        print('❌ [SPLASH] Data loading failed');
      }

      update();
      return success;
    } catch (e) {
      print('❌ [SPLASH] Fatal error during data loading: $e');
      _dataLoadingFailed = true;
      _dataLoadingError = e.toString();
      update();
      return false;
    }
  }

  /// Reset data loading state (for retry)
  void resetDataLoading() {
    _loadingProgress = 0.0;
    _loadingMessage = '';
    _dataLoadingComplete = false;
    _dataLoadingFailed = false;
    _dataLoadingError = '';
    Get.find<AppDataController>().resetLoadingState();
    update();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // OLD ARCHITECTURE SUPPORT METHODS - REMOVED
  // ═══════════════════════════════════════════════════════════════════════════
  // Deprecated methods removed. Use new architecture instead.
  // ═══════════════════════════════════════════════════════════════════════════

  void _onRemoveLoader() {
    final preloader = html.document.querySelector('.preloader');
    if (preloader != null) {
      preloader.remove();
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
    // Go directly to pick map screen - zone selection first approach
    // The map screen starts in zone selection mode, user selects zone first
    // No need to auto-validate GPS location against zones on startup
    Get.toNamed(RouteHelper.getPickMapRoute(page, false));
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