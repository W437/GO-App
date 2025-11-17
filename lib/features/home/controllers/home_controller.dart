import 'package:godelivery_user/common/enums/data_source_enum.dart';
import 'package:godelivery_user/features/home/domain/models/banner_model.dart';
import 'package:godelivery_user/features/home/domain/models/cashback_model.dart';
import 'package:godelivery_user/features/home/domain/services/home_service_interface.dart';
import 'package:get/get.dart';

class HomeController extends GetxController implements GetxService {
  final HomeServiceInterface homeServiceInterface;

  HomeController({required this.homeServiceInterface});

  List<String?>? _bannerImageList;
  List<dynamic>? _bannerDataList;
  List<Banner>? _bannerObjectList;

  List<String?>? get bannerImageList => _bannerImageList;
  List<dynamic>? get bannerDataList => _bannerDataList;
  List<Banner>? get bannerObjectList => _bannerObjectList;

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  List<CashBackModel>? _cashBackOfferList;
  List<CashBackModel>? get cashBackOfferList => _cashBackOfferList;

  CashBackModel? _cashBackData;
  CashBackModel? get cashBackData => _cashBackData;

  bool _showFavButton = true;
  bool get showFavButton => _showFavButton;

  Future<void> getBannerList(bool reload, {DataSourceEnum dataSource = DataSourceEnum.local, bool fromRecall = false}) async {
    if(_bannerImageList == null || reload || fromRecall) {
      if(!fromRecall) {
        _bannerImageList = null;
      }
      BannerModel? bannerModel;
      if(dataSource == DataSourceEnum.local){
        bannerModel = await homeServiceInterface.getBannerList(source: DataSourceEnum.local);
        _prepareBannerList(bannerModel);
        getBannerList(false, dataSource: DataSourceEnum.client, fromRecall: true);
      }else{
        bannerModel = await homeServiceInterface.getBannerList(source: DataSourceEnum.client);
        _prepareBannerList(bannerModel);
      }
    }
  }

  _prepareBannerList(BannerModel? bannerModel){
    if (bannerModel != null) {
      _bannerImageList = [];
      _bannerDataList = [];
      _bannerObjectList = [];

      print('🎯 Processing ${bannerModel.campaigns?.length ?? 0} campaigns');
      for (var campaign in bannerModel.campaigns!) {
        print('  ➡️ Campaign: "${campaign.title}" (ID: ${campaign.id})');
        _bannerImageList!.add(campaign.imageFullUrl);
        _bannerDataList!.add(campaign);
        // Create a Banner object for campaigns (they don't have video support yet)
        _bannerObjectList!.add(Banner(
          imageFullUrl: campaign.imageFullUrl,
          videoFullUrl: null,
          videoThumbnailUrl: null,
        ));
      }

      print('🎯 Processing ${bannerModel.banners?.length ?? 0} regular banners');
      for (var banner in bannerModel.banners!) {
        // Prioritize video over image for the display list
        String? displayUrl = banner.videoFullUrl ?? banner.imageFullUrl;

        if(_bannerImageList!.contains(displayUrl)){
          _bannerImageList!.add('$displayUrl${bannerModel.banners!.indexOf(banner)}');
        }else {
          _bannerImageList!.add(displayUrl);
        }

        if(banner.food != null) {
          _bannerDataList!.add(banner.food);
        }else {
          _bannerDataList!.add(banner.restaurant);
        }

        // Store the actual Banner object with all fields
        _bannerObjectList!.add(banner);
      }

      print('✅ Total banner items prepared: ${_bannerImageList!.length}');
    }
    update();
  }

  void setCurrentIndex(int index, bool notify) {
    _currentIndex = index;
    if(notify) {
      update();
    }
  }


  Future<void> getCashBackOfferList({DataSourceEnum dataSource = DataSourceEnum.local}) async {
    _cashBackOfferList = null;
    List<CashBackModel>? cashBackOfferList;

    if(dataSource == DataSourceEnum.local){
      cashBackOfferList = await homeServiceInterface.getCashBackOfferList(source: DataSourceEnum.local);
      _prepareCashBackOfferList(cashBackOfferList);
      getCashBackOfferList(dataSource: DataSourceEnum.client);
    }else{
      cashBackOfferList = await homeServiceInterface.getCashBackOfferList(source: DataSourceEnum.client);
      _prepareCashBackOfferList(cashBackOfferList);
    }
  }

  _prepareCashBackOfferList(List<CashBackModel>? cashBackOfferList){
    if(cashBackOfferList != null) {
      _cashBackOfferList = [];
      _cashBackOfferList!.addAll(cashBackOfferList);
    }
    update();
  }

  void forcefullyNullCashBackOffers() {
    _cashBackOfferList = null;
    update();
  }

  Future<void> getCashBackData(double amount) async {
    CashBackModel? cashBackModel = await homeServiceInterface.getCashBackData(amount);
    if(cashBackModel != null) {
      _cashBackData = cashBackModel;
    }
    update();
  }

  void changeFavVisibility(){
    _showFavButton = !_showFavButton;
    update();
  }

}