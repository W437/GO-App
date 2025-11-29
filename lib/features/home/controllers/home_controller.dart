import 'package:godelivery_user/features/home/domain/models/banner_model.dart';
import 'package:godelivery_user/features/home/domain/models/cashback_model.dart';
import 'package:godelivery_user/features/home/domain/models/home_feed_model.dart';
import 'package:godelivery_user/features/home/domain/services/home_service_interface.dart';
import 'package:godelivery_user/features/restaurant/domain/services/restaurant_service_interface.dart';
import 'package:get/get.dart';

class HomeController extends GetxController implements GetxService {
  final HomeServiceInterface homeServiceInterface;
  final RestaurantServiceInterface restaurantServiceInterface;

  HomeController({
    required this.homeServiceInterface,
    required this.restaurantServiceInterface,
  });

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

  // Home Feed data
  HomeFeedModel? _homeFeedModel;
  HomeFeedModel? get homeFeedModel => _homeFeedModel;

  List<HomeFeedCategorySection>? get homeFeedCategories => _homeFeedModel?.categories;

  final Map<String, int> _sectionOffsets = {};
  final Map<String, bool> _sectionHasMore = {};

  Future<void> getBannerList(bool reload) async {
    // Use cached data if available and not forcing reload
    if (_bannerImageList != null && !reload) {
      print('✅ [BANNER] Using cached data');
      return;
    }

    // Show shimmer while loading
    if (reload) {
      _bannerImageList = null;
      update();
    }

    // Fetch from API
    BannerModel? bannerModel = await homeServiceInterface.getBannerList();
    _prepareBannerList(bannerModel);
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


  Future<void> getCashBackOfferList() async {
    _cashBackOfferList = null;
    List<CashBackModel>? cashBackOfferList = await homeServiceInterface.getCashBackOfferList();
    _prepareCashBackOfferList(cashBackOfferList);
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

  // ==================== HOME FEED METHODS ====================

  Future<void> getHomeFeed(bool reload) async {
    if (_homeFeedModel != null && !reload) return;

    if (reload) {
      _homeFeedModel = null;
      _sectionOffsets.clear();
      _sectionHasMore.clear();
      update();
    }

    HomeFeedModel? homeFeedModel = await restaurantServiceInterface.getHomeFeed();

    if (homeFeedModel != null) {
      _homeFeedModel = homeFeedModel;

      // Initialize pagination state for each section
      if (homeFeedModel.newRestaurants != null) {
        _sectionOffsets['new'] = homeFeedModel.newRestaurants!.offset ?? 1;
        _sectionHasMore['new'] = homeFeedModel.newRestaurants!.hasMore ?? false;
      }
      if (homeFeedModel.popular != null) {
        _sectionOffsets['popular'] = homeFeedModel.popular!.offset ?? 1;
        _sectionHasMore['popular'] = homeFeedModel.popular!.hasMore ?? false;
      }

      // Initialize category pagination
      if (homeFeedModel.categories != null) {
        for (var category in homeFeedModel.categories!) {
          if (category.id != null) {
            _sectionOffsets['category_${category.id}'] = category.offset ?? 1;
            _sectionHasMore['category_${category.id}'] = category.hasMore ?? false;
          }
        }
      }
    }

    update();
  }

  Future<void> loadMoreForSection(String section, {int? categoryId}) async {
    String key = categoryId != null ? 'category_$categoryId' : section;
    if (_sectionHasMore[key] != true) return;

    int nextOffset = (_sectionOffsets[key] ?? 1) + 1;

    HomeFeedSectionResponse? response = await restaurantServiceInterface.getHomeFeedSection(
      section,
      categoryId: categoryId,
      offset: nextOffset,
    );

    if (response != null && response.restaurants != null) {
      _sectionOffsets[key] = response.offset ?? nextOffset;
      _sectionHasMore[key] = response.hasMore ?? false;

      // Append restaurants to the appropriate section
      if (categoryId != null && _homeFeedModel?.categories != null) {
        final categoryIndex = _homeFeedModel!.categories!.indexWhere((c) => c.id == categoryId);
        if (categoryIndex != -1) {
          _homeFeedModel!.categories![categoryIndex].restaurants?.addAll(response.restaurants!);
        }
      } else if (section == 'new' && _homeFeedModel?.newRestaurants != null) {
        _homeFeedModel!.newRestaurants!.restaurants?.addAll(response.restaurants!);
      } else if (section == 'popular' && _homeFeedModel?.popular != null) {
        _homeFeedModel!.popular!.restaurants?.addAll(response.restaurants!);
      }

      update();
    }
  }

  bool hasMoreForSection(String section, {int? categoryId}) {
    String key = categoryId != null ? 'category_$categoryId' : section;
    return _sectionHasMore[key] ?? false;
  }

}