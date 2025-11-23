Performing hot restart...
Syncing files to device sdk gphone64 arm64...
lib/features/restaurant/controllers/restaurant_controller.dart:132:58: Error: Type 'DataSourceEnum' not found.
  Future<void> getOrderAgainRestaurantList(bool reload, {DataSourceEnum dataSource = DataSourceEnum.local}) async {
                                                         ^^^^^^^^^^^^^^
lib/features/restaurant/controllers/restaurant_controller.dart:156:88: Error: Type 'DataSourceEnum' not found.
  Future<void> getRecentlyViewedRestaurantList(bool reload, String type, bool notify, {DataSourceEnum dataSource = DataSourceEnum.local, bool fromRecall = false}) async {
                                                                                       ^^^^^^^^^^^^^^
lib/features/restaurant/controllers/restaurant_controller.dart:260:81: Error: Type 'DataSourceEnum' not found.
  Future<void> getPopularRestaurantList(bool reload, String type, bool notify, {DataSourceEnum dataSource = DataSourceEnum.local, bool fromRecall = false}) async {
                                                                                ^^^^^^^^^^^^^^
lib/features/restaurant/controllers/restaurant_controller.dart:290:80: Error: Type 'DataSourceEnum' not found.
  Future<void> getLatestRestaurantList(bool reload, String type, bool notify, {DataSourceEnum dataSource = DataSourceEnum.local, bool fromRecall = false}) async {
                                                                               ^^^^^^^^^^^^^^
lib/features/splash/domain/services/splash_service_interface.dart:5:44: Error: Type 'DataSourceEnum' not found.
  Future<Response> getConfigData({required DataSourceEnum? source});
                                           ^^^^^^^^^^^^^^
lib/features/address/domain/services/address_service_interface.dart:5:62: Error: Type 'DataSourceEnum' not found.
  Future<List<AddressModel>?> getList({bool isLocal = false, DataSourceEnum? source});
                                                             ^^^^^^^^^^^^^^
lib/features/splash/domain/services/splash_service.dart:17:44: Error: Type 'DataSourceEnum' not found.
  Future<Response> getConfigData({required DataSourceEnum? source}) async {
                                           ^^^^^^^^^^^^^^
lib/features/address/domain/services/address_service.dart:30:31: Error: The method 'AddressService.getList' has fewer named arguments than those of overridden method 'AddressServiceInterface.getList'.
  Future<List<AddressModel>?> getList({bool isLocal = false}) async {
                              ^
lib/features/address/domain/services/address_service_interface.dart:5:31: Context: This is the overridden method ('getList').
  Future<List<AddressModel>?> getList({bool isLocal = false, DataSourceEnum? source});
                              ^
lib/features/restaurant/controllers/restaurant_controller.dart:132:86: Error: Undefined name 'DataSourceEnum'.
  Future<void> getOrderAgainRestaurantList(bool reload, {DataSourceEnum dataSource = DataSourceEnum.local}) async {
                                                                                     ^^^^^^^^^^^^^^
lib/features/restaurant/controllers/restaurant_controller.dart:156:116: Error: Undefined name 'DataSourceEnum'.
  Future<void> getRecentlyViewedRestaurantList(bool reload, String type, bool notify, {DataSourceEnum dataSource = DataSourceEnum.local, bool fromRecall = false}) async {
                                                                                          ^^^^^^^^^^^^^^
lib/features/restaurant/controllers/restaurant_controller.dart:260:109: Error: Undefined name 'DataSourceEnum'.
  Future<void> getPopularRestaurantList(bool reload, String type, bool notify, {DataSourceEnum dataSource = DataSourceEnum.local, bool fromRecall = false}) async {
                                                                                          ^^^^^^^^^^^^^^
lib/features/restaurant/controllers/restaurant_controller.dart:290:108: Error: Undefined name 'DataSourceEnum'.
  Future<void> getLatestRestaurantList(bool reload, String type, bool notify, {DataSourceEnum dataSource = DataSourceEnum.local, bool fromRecall = false}) async {
                                                                                          ^^^^^^^^^^^^^^
lib/features/restaurant/controllers/restaurant_controller.dart:132:58: Error: 'DataSourceEnum' isn't a type.
  Future<void> getOrderAgainRestaurantList(bool reload, {DataSourceEnum dataSource = DataSourceEnum.local}) async {
                                                         ^^^^^^^^^^^^^^
lib/features/restaurant/controllers/restaurant_controller.dart:138:22: Error: The getter 'DataSourceEnum' isn't defined for the type 'RestaurantController'.
 - 'RestaurantController' is from 'package:godelivery_user/features/restaurant/controllers/restaurant_controller.dart' ('lib/features/restaurant/controllers/restaurant_controller.dart').
Try correcting the name to the name of an existing getter, or defining a getter or field named 'DataSourceEnum'.
    if(dataSource == DataSourceEnum.local) {
                     ^^^^^^^^^^^^^^
lib/features/restaurant/controllers/restaurant_controller.dart:139:103: Error: The getter 'DataSourceEnum' isn't defined for the type 'RestaurantController'.
 - 'RestaurantController' is from 'package:godelivery_user/features/restaurant/controllers/restaurant_controller.dart' ('lib/features/restaurant/controllers/restaurant_controller.dart').
Try correcting the name to the name of an existing getter, or defining a getter or field named 'DataSourceEnum'.
      orderAgainRestaurantList = await restaurantServiceInterface.getOrderAgainRestaurantList(source: DataSourceEnum.local);
                                                                                          ^^^^^^^^^^^^^^
lib/features/restaurant/controllers/restaurant_controller.dart:139:95: Error: No named parameter with the name 'source'.
      orderAgainRestaurantList = await restaurantServiceInterface.getOrderAgainRestaurantList(source: DataSourceEnum.local);
                                                                                          ^^^^^^
lib/features/restaurant/controllers/restaurant_controller.dart:141:54: Error: The getter 'DataSourceEnum' isn't defined for the type 'RestaurantController'.
 - 'RestaurantController' is from 'package:godelivery_user/features/restaurant/controllers/restaurant_controller.dart' ('lib/features/restaurant/controllers/restaurant_controller.dart').
Try correcting the name to the name of an existing getter, or defining a getter or field named 'DataSourceEnum'.
      getOrderAgainRestaurantList(false, dataSource: DataSourceEnum.client);
                                                     ^^^^^^^^^^^^^^
lib/features/restaurant/controllers/restaurant_controller.dart:143:103: Error: The getter 'DataSourceEnum' isn't defined for the type 'RestaurantController'.
 - 'RestaurantController' is from 'package:godelivery_user/features/restaurant/controllers/restaurant_controller.dart' ('lib/features/restaurant/controllers/restaurant_controller.dart').
Try correcting the name to the name of an existing getter, or defining a getter or field named 'DataSourceEnum'.
      orderAgainRestaurantList = await restaurantServiceInterface.getOrderAgainRestaurantList(source: DataSourceEnum.client);
                                                                                          ^^^^^^^^^^^^^^
lib/features/restaurant/controllers/restaurant_controller.dart:143:95: Error: No named parameter with the name 'source'.
      orderAgainRestaurantList = await restaurantServiceInterface.getOrderAgainRestaurantList(source: DataSourceEnum.client);
                                                                                          ^^^^^^
lib/features/restaurant/controllers/restaurant_controller.dart:156:88: Error: 'DataSourceEnum' isn't a type.
  Future<void> getRecentlyViewedRestaurantList(bool reload, String type, bool notify, {DataSourceEnum dataSource = DataSourceEnum.local, bool fromRecall = false}) async {
                                                                                       ^^^^^^^^^^^^^^
lib/features/restaurant/controllers/restaurant_controller.dart:166:24: Error: The getter 'DataSourceEnum' isn't defined for the type 'RestaurantController'.
 - 'RestaurantController' is from 'package:godelivery_user/features/restaurant/controllers/restaurant_controller.dart' ('lib/features/restaurant/controllers/restaurant_controller.dart').
Try correcting the name to the name of an existing getter, or defining a getter or field named 'DataSourceEnum'.
      if(dataSource == DataSourceEnum.local) {
                       ^^^^^^^^^^^^^^
lib/features/restaurant/controllers/restaurant_controller.dart:167:119: Error: The getter 'DataSourceEnum' isn't defined for the type 'RestaurantController'.
 - 'RestaurantController' is from 'package:godelivery_user/features/restaurant/controllers/restaurant_controller.dart' ('lib/features/restaurant/controllers/restaurant_controller.dart').
Try correcting the name to the name of an existing getter, or defining a getter or field named 'DataSourceEnum'.
        recentlyViewedRestaurantList = await restaurantServiceInterface.getRecentlyViewedRestaurantList(type, source: DataSourceEnum.local);
                                                                                          ^^^^^^^^^^^^^^
lib/features/restaurant/controllers/restaurant_controller.dart:167:111: Error: No named parameter with the name 'source'.
        recentlyViewedRestaurantList = await restaurantServiceInterface.getRecentlyViewedRestaurantList(type, source: DataSourceEnum.local);
                                                                                          ^^^^^^
lib/features/restaurant/controllers/restaurant_controller.dart:169:73: Error: The getter 'DataSourceEnum' isn't defined for the type 'RestaurantController'.
 - 'RestaurantController' is from 'package:godelivery_user/features/restaurant/controllers/restaurant_controller.dart' ('lib/features/restaurant/controllers/restaurant_controller.dart').
Try correcting the name to the name of an existing getter, or defining a getter or field named 'DataSourceEnum'.
        getRecentlyViewedRestaurantList(false, type, false, dataSource: DataSourceEnum.client, fromRecall: true);
                                                                        ^^^^^^^^^^^^^^
lib/features/restaurant/controllers/restaurant_controller.dart:171:119: Error: The getter 'DataSourceEnum' isn't defined for the type 'RestaurantController'.
 - 'RestaurantController' is from 'package:godelivery_user/features/restaurant/controllers/restaurant_controller.dart' ('lib/features/restaurant/controllers/restaurant_controller.dart').
Try correcting the name to the name of an existing getter, or defining a getter or field named 'DataSourceEnum'.
        recentlyViewedRestaurantList = await restaurantServiceInterface.getRecentlyViewedRestaurantList(type, source: DataSourceEnum.client);
                                                                                          ^^^^^^^^^^^^^^
lib/features/restaurant/controllers/restaurant_controller.dart:171:111: Error: No named parameter with the name 'source'.
        recentlyViewedRestaurantList = await restaurantServiceInterface.getRecentlyViewedRestaurantList(type, source: DataSourceEnum.client);
                                                                                          ^^^^^^
lib/features/restaurant/controllers/restaurant_controller.dart:260:81: Error: 'DataSourceEnum' isn't a type.
  Future<void> getPopularRestaurantList(bool reload, String type, bool notify, {DataSourceEnum dataSource = DataSourceEnum.local, bool fromRecall = false}) async {
                                                                                ^^^^^^^^^^^^^^
lib/features/restaurant/controllers/restaurant_controller.dart:271:25: Error: The getter 'DataSourceEnum' isn't defined for the type 'RestaurantController'.
 - 'RestaurantController' is from 'package:godelivery_user/features/restaurant/controllers/restaurant_controller.dart' ('lib/features/restaurant/controllers/restaurant_controller.dart').
Try correcting the name to the name of an existing getter, or defining a getter or field named 'DataSourceEnum'.
      if (dataSource == DataSourceEnum.local) {
                        ^^^^^^^^^^^^^^
lib/features/restaurant/controllers/restaurant_controller.dart:272:105: Error: The getter 'DataSourceEnum' isn't defined for the type 'RestaurantController'.
 - 'RestaurantController' is from 'package:godelivery_user/features/restaurant/controllers/restaurant_controller.dart' ('lib/features/restaurant/controllers/restaurant_controller.dart').
Try correcting the name to the name of an existing getter, or defining a getter or field named 'DataSourceEnum'.
        popularRestaurantList = await restaurantServiceInterface.getPopularRestaurantList(type, source: DataSourceEnum.local);
                                                                                          ^^^^^^^^^^^^^^
lib/features/restaurant/controllers/restaurant_controller.dart:272:97: Error: No named parameter with the name 'source'.
        popularRestaurantList = await restaurantServiceInterface.getPopularRestaurantList(type, source: DataSourceEnum.local);
                                                                                          ^^^^^^
lib/features/restaurant/controllers/restaurant_controller.dart:274:66: Error: The getter 'DataSourceEnum' isn't defined for the type 'RestaurantController'.
 - 'RestaurantController' is from 'package:godelivery_user/features/restaurant/controllers/restaurant_controller.dart' ('lib/features/restaurant/controllers/restaurant_controller.dart').
Try correcting the name to the name of an existing getter, or defining a getter or field named 'DataSourceEnum'.
        getPopularRestaurantList(false, type, false, dataSource: DataSourceEnum.client, fromRecall: true);
                                                                 ^^^^^^^^^^^^^^
lib/features/restaurant/controllers/restaurant_controller.dart:276:105: Error: The getter 'DataSourceEnum' isn't defined for the type 'RestaurantController'.
 - 'RestaurantController' is from 'package:godelivery_user/features/restaurant/controllers/restaurant_controller.dart' ('lib/features/restaurant/controllers/restaurant_controller.dart').
Try correcting the name to the name of an existing getter, or defining a getter or field named 'DataSourceEnum'.
        popularRestaurantList = await restaurantServiceInterface.getPopularRestaurantList(type, source: DataSourceEnum.client);
                                                                                          ^^^^^^^^^^^^^^
lib/features/restaurant/controllers/restaurant_controller.dart:276:97: Error: No named parameter with the name 'source'.
        popularRestaurantList = await restaurantServiceInterface.getPopularRestaurantList(type, source: DataSourceEnum.client);
                                                                                          ^^^^^^
lib/features/restaurant/controllers/restaurant_controller.dart:290:80: Error: 'DataSourceEnum' isn't a type.
  Future<void> getLatestRestaurantList(bool reload, String type, bool notify, {DataSourceEnum dataSource = DataSourceEnum.local, bool fromRecall = false}) async {
                                                                               ^^^^^^^^^^^^^^
lib/features/restaurant/controllers/restaurant_controller.dart:302:24: Error: The getter 'DataSourceEnum' isn't defined for the type 'RestaurantController'.
 - 'RestaurantController' is from 'package:godelivery_user/features/restaurant/controllers/restaurant_controller.dart' ('lib/features/restaurant/controllers/restaurant_controller.dart').
Try correcting the name to the name of an existing getter, or defining a getter or field named 'DataSourceEnum'.
      if(dataSource == DataSourceEnum.local) {
                       ^^^^^^^^^^^^^^
lib/features/restaurant/controllers/restaurant_controller.dart:303:103: Error: The getter 'DataSourceEnum' isn't defined for the type 'RestaurantController'.
 - 'RestaurantController' is from 'package:godelivery_user/features/restaurant/controllers/restaurant_controller.dart' ('lib/features/restaurant/controllers/restaurant_controller.dart').
Try correcting the name to the name of an existing getter, or defining a getter or field named 'DataSourceEnum'.
        latestRestaurantList = await restaurantServiceInterface.getLatestRestaurantList(type, source: DataSourceEnum.local);
                                                                                          ^^^^^^^^^^^^^^
lib/features/restaurant/controllers/restaurant_controller.dart:303:95: Error: No named parameter with the name 'source'.
        latestRestaurantList = await restaurantServiceInterface.getLatestRestaurantList(type, source: DataSourceEnum.local);
                                                                                          ^^^^^^
lib/features/restaurant/controllers/restaurant_controller.dart:305:65: Error: The getter 'DataSourceEnum' isn't defined for the type 'RestaurantController'.
 - 'RestaurantController' is from 'package:godelivery_user/features/restaurant/controllers/restaurant_controller.dart' ('lib/features/restaurant/controllers/restaurant_controller.dart').
Try correcting the name to the name of an existing getter, or defining a getter or field named 'DataSourceEnum'.
        getLatestRestaurantList(false, type, false, dataSource: DataSourceEnum.client, fromRecall: true);
                                                                ^^^^^^^^^^^^^^
lib/features/restaurant/controllers/restaurant_controller.dart:307:103: Error: The getter 'DataSourceEnum' isn't defined for the type 'RestaurantController'.
 - 'RestaurantController' is from 'package:godelivery_user/features/restaurant/controllers/restaurant_controller.dart' ('lib/features/restaurant/controllers/restaurant_controller.dart').
Try correcting the name to the name of an existing getter, or defining a getter or field named 'DataSourceEnum'.
        latestRestaurantList = await restaurantServiceInterface.getLatestRestaurantList(type, source: DataSourceEnum.client);
                                                                                          ^^^^^^^^^^^^^^
lib/features/restaurant/controllers/restaurant_controller.dart:307:95: Error: No named parameter with the name 'source'.
        latestRestaurantList = await restaurantServiceInterface.getLatestRestaurantList(type, source: DataSourceEnum.client);
                                                                                          ^^^^^^
lib/features/splash/domain/services/splash_service_interface.dart:5:44: Error: 'DataSourceEnum' isn't a type.
  Future<Response> getConfigData({required DataSourceEnum? source});
                                           ^^^^^^^^^^^^^^
lib/features/splash/domain/services/config_service.dart:23:15: Error: The getter 'DataSourceEnum' isn't defined for the type 'ConfigService'.
 - 'ConfigService' is from 'package:godelivery_user/features/splash/domain/services/config_service.dart' ('lib/features/splash/domain/services/config_service.dart').
Try correcting the name to the name of an existing getter, or defining a getter or field named 'DataSourceEnum'.
      source: DataSourceEnum.client,
              ^^^^^^^^^^^^^^
lib/features/splash/domain/services/config_service.dart:43:15: Error: The getter 'DataSourceEnum' isn't defined for the type 'ConfigService'.
 - 'ConfigService' is from 'package:godelivery_user/features/splash/domain/services/config_service.dart' ('lib/features/splash/domain/services/config_service.dart').
Try correcting the name to the name of an existing getter, or defining a getter or field named 'DataSourceEnum'.
      source: DataSourceEnum.local,
              ^^^^^^^^^^^^^^
lib/features/splash/domain/services/config_service.dart:64:15: Error: The getter 'DataSourceEnum' isn't defined for the type 'ConfigService'.
 - 'ConfigService' is from 'package:godelivery_user/features/splash/domain/services/config_service.dart' ('lib/features/splash/domain/services/config_service.dart').
Try correcting the name to the name of an existing getter, or defining a getter or field named 'DataSourceEnum'.
      source: DataSourceEnum.local,
              ^^^^^^^^^^^^^^
lib/features/notification/controllers/notification_controller.dart:22:71: Error: No named parameter with the name 'source'.
        notificationList = await notificationServiceInterface.getList(source: DataSourceEnum.local);
                                                                      ^^^^^^
lib/features/notification/controllers/notification_controller.dart:26:71: Error: No named parameter with the name 'source'.
        notificationList = await notificationServiceInterface.getList(source: DataSourceEnum.client);
                                                                      ^^^^^^
lib/features/story/controllers/story_controller.dart:43:9: Error: No named parameter with the name 'source'.
        source: reload ? DataSourceEnum.client : DataSourceEnum.local,
        ^^^^^^
lib/features/story/controllers/story_controller.dart:52:11: Error: No named parameter with the name 'source'.
          source: DataSourceEnum.client,
          ^^^^^^
lib/features/home/controllers/advertisement_controller.dart:26:84: Error: No named parameter with the name 'source'.
      advertisementList = await advertisementServiceInterface.getAdvertisementList(source: DataSourceEnum.local);
                                                                                   ^^^^^^
lib/features/home/controllers/advertisement_controller.dart:30:84: Error: No named parameter with the name 'source'.
      advertisementList = await advertisementServiceInterface.getAdvertisementList(source: DataSourceEnum.client);
                                                                                   ^^^^^^
lib/features/notification/domain/service/notification_service.dart:13:95: Error: No named parameter with the name 'source'.
    List<NotificationModel>? notificationList = await notificationRepositoryInterface.getList(source: source);
                                                                                          ^^^^^^
lib/features/address/domain/services/address_service.dart:31:55: Error: The getter 'source' isn't defined for the type 'AddressService'.
 - 'AddressService' is from 'package:godelivery_user/features/address/domain/services/address_service.dart' ('lib/features/address/domain/services/address_service.dart').
Try correcting the name to the name of an existing getter, or defining a getter or field named 'source'.
    return await addressRepoInterface.getList(source: source);
                                                      ^^^^^^
lib/features/address/domain/services/address_service.dart:31:47: Error: No named parameter with the name 'source'.
    return await addressRepoInterface.getList(source: source);
                                              ^^^^^^
lib/features/address/domain/services/address_service_interface.dart:5:62: Error: 'DataSourceEnum' isn't a type.
  Future<List<AddressModel>?> getList({bool isLocal = false, DataSourceEnum? source});
                                                             ^^^^^^^^^^^^^^
lib/features/cuisine/domain/services/cuisine_service.dart:12:54: Error: Expected an identifier, but got ')'.
Try inserting an identifier before ')'.
    return await cuisineRepositoryInterface.getList(!);
                                                     ^
lib/features/cuisine/domain/services/cuisine_service.dart:12:52: Error: Too many positional arguments: 0 allowed, but 1 found.
Try removing the extra positional arguments.
    return await cuisineRepositoryInterface.getList(!);
                                                   ^
lib/features/splash/domain/services/splash_service.dart:17:44: Error: 'DataSourceEnum' isn't a type.
  Future<Response> getConfigData({required DataSourceEnum? source}) async {
                                           ^^^^^^^^^^^^^^
Restarted application in 974ms.
