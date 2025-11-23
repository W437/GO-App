import 'package:get/get.dart';
import 'package:godelivery_user/features/home/domain/models/advertisement_model.dart';
import 'package:godelivery_user/features/home/domain/services/advertisement_service_interface.dart';

class AdvertisementController extends GetxController implements GetxService {
  final AdvertisementServiceInterface advertisementServiceInterface;
  AdvertisementController({required this.advertisementServiceInterface});

  List<AdvertisementModel>? _advertisementList;
  List<AdvertisementModel>? get advertisementList => _advertisementList;

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  Duration autoPlayDuration = const Duration(seconds: 7);

  bool autoPlay = true;

  Future<void> getAdvertisementList() async {
    // Use cached data if available
    if (_advertisementList != null) {
      print('✅ [ADVERTISEMENT] Using cached data');
      return;
    }

    List<AdvertisementModel>? advertisementList = await advertisementServiceInterface.getAdvertisementList();
    _prepareAdvertisement(advertisementList);
  }

  _prepareAdvertisement(List<AdvertisementModel>? advertisementList) {
    if (advertisementList != null) {
      _advertisementList = [];
      _advertisementList = advertisementList;
    }
    update();
  }

  void setCurrentIndex(int index, bool notify) {
    _currentIndex = index;
    if(notify) {
      update();
    }
  }

  void updateAutoPlayStatus({bool shouldUpdate = false, bool status = false}){
    autoPlay = status;
    if(shouldUpdate){
      update();
    }
  }

}