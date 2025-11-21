import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/features/location/controllers/location_controller.dart';
import 'package:godelivery_user/helper/business_logic/address_helper.dart';
import 'package:godelivery_user/helper/ui/responsive_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/images.dart';
import 'package:godelivery_user/util/styles.dart';

class BadWeatherWidget extends StatefulWidget {
  const BadWeatherWidget({super.key});

  @override
  State<BadWeatherWidget> createState() => _BadWeatherWidgetState();
}

class _BadWeatherWidgetState extends State<BadWeatherWidget> {
  final LocationController _locationController = Get.find<LocationController>();
  late Future<BadWeatherAlertData?> _alertDataFuture;

  @override
  void initState() {
    super.initState();
    _alertDataFuture = _fetchAlertData();
  }

  Future<BadWeatherAlertData?> _fetchAlertData() async {
    final address = AddressHelper.getAddressFromSharedPref();
    print('🌧️ [BAD WEATHER] Checking alert...');
    if (address == null) {
      print('   ❌ No address');
      return null;
    }

    await _locationController.getZone(address.latitude, address.longitude, false);
    print('   Zone ID: ${address.zoneId}');

    // Use fresh zone data from controller, not stale cached data from address
    final zoneData = _locationController.zoneList?.firstWhereOrNull(
      (data) => data.id == address.zoneId &&
      data.increasedDeliveryFeeStatus == 1 &&
      data.increaseDeliveryChargeMessage?.isNotEmpty == true,
    );

    if (zoneData != null) {
      print('   ✅ ALERT SHOWING!');
      print('   Message: "${zoneData.increaseDeliveryChargeMessage}"');
    } else {
      print('   ❌ No alert');
      print('   Controller zones: ${_locationController.zoneList?.length}');
      _locationController.zoneList?.forEach((z) {
        print('   Zone ${z.id}: status=${z.increasedDeliveryFeeStatus}, msg="${z.increaseDeliveryChargeMessage}"');
      });
    }

    return zoneData != null ? BadWeatherAlertData(
      showAlert: zoneData.increasedDeliveryFeeStatus == 1,
      message: zoneData.increaseDeliveryChargeMessage ?? '',
    ) : null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<BadWeatherAlertData?>(
      future: _alertDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox();
        }

        final alertData = snapshot.data;
        if (alertData == null || !alertData.showAlert || alertData.message.isEmpty) {
          return const SizedBox();
        }

        return _buildAlertWidget(context, alertData.message);
      },
    );
  }

  Widget _buildAlertWidget(BuildContext context, String message) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
          width: 2.0,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.isDesktop(context) ? 0 : Dimensions.paddingSizeDefault,
        vertical: Dimensions.paddingSizeExtraSmall,
      ),
      child: Row(children: [

        Image.asset(Images.weather, height: 50, width: 50),
        const SizedBox(width: Dimensions.paddingSizeSmall),

        Expanded(
          child: Text(
            "Weather's rough out there! Delivery fees are up 25% to support our amazing delivery partners. All proceeds go directly to them. 💙",
            style: robotoMedium.copyWith(
              fontSize: Dimensions.fontSizeDefault,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ),

      ]),
    );
  }
}

class BadWeatherAlertData {
  final bool showAlert;
  final String message;

  BadWeatherAlertData({required this.showAlert, required this.message});
}