import 'package:godelivery_user/common/enums/data_source_enum.dart';
import 'package:godelivery_user/features/product/domain/models/basic_campaign_model.dart';
import 'package:godelivery_user/common/models/product_model.dart';
import 'package:godelivery_user/features/product/domain/services/campaign_service_interface.dart';
import 'package:get/get.dart';

class CampaignController extends GetxController implements GetxService {
  final CampaignServiceInterface campaignServiceInterface;
  CampaignController({required this.campaignServiceInterface});

  List<BasicCampaignModel>? _basicCampaignList;
  List<BasicCampaignModel>? get basicCampaignList => _basicCampaignList;

  BasicCampaignModel? _campaign;
  BasicCampaignModel? get campaign => _campaign;

  List<Product>? _itemCampaignList;
  List<Product>? get itemCampaignList => _itemCampaignList;

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  void setCurrentIndex(int index, bool notify) {
    _currentIndex = index;
    if(notify) {
      update();
    }
  }

  Future<void> getBasicCampaignList(bool reload) async {
    if(_basicCampaignList == null || reload) {
      _basicCampaignList = await campaignServiceInterface.getBasicCampaignList();
      update();
    }
  }

  Future<void> getBasicCampaignDetails(int? campaignID) async {
    _campaign = null;
    _campaign = await campaignServiceInterface.getCampaignDetails(campaignID.toString());
    update();
  }

  Future<void> getItemCampaignList(bool reload, {DataSourceEnum dataSource = DataSourceEnum.local, bool fromRecall = false}) async {
    print('🔍 getItemCampaignList called - reload: $reload, dataSource: $dataSource, fromRecall: $fromRecall');
    print('🔍 Current _itemCampaignList: ${_itemCampaignList?.length ?? "null"}');

    if(_itemCampaignList == null || reload || fromRecall) {
      if(!fromRecall) {
        _itemCampaignList = null;
      }

      List<Product>? itemCampaignList;
      if(dataSource == DataSourceEnum.local) {
        print('📦 Fetching from LOCAL cache...');
        itemCampaignList = await campaignServiceInterface.getItemCampaignList(source: DataSourceEnum.local);
        print('📦 Local result: ${itemCampaignList?.length ?? "null"} items');
        _prepareItemBasicCampaign(itemCampaignList);
        getItemCampaignList(false, dataSource: DataSourceEnum.client, fromRecall: true);
      } else {
        print('🌐 Fetching from API...');
        itemCampaignList = await campaignServiceInterface.getItemCampaignList(source: DataSourceEnum.client);
        print('🌐 API result: ${itemCampaignList?.length ?? "null"} items');
        _prepareItemBasicCampaign(itemCampaignList);
      }
    }
  }

  _prepareItemBasicCampaign(List<Product>? itemCampaignList) {
    print('🔄 _prepareItemBasicCampaign called with: ${itemCampaignList?.length ?? "null"} items');
    if (itemCampaignList != null) {
      _itemCampaignList = [];
      _itemCampaignList = itemCampaignList;
      print('✅ Set _itemCampaignList to ${_itemCampaignList!.length} items');
      if (_itemCampaignList!.isNotEmpty) {
        print('📋 First item: ${_itemCampaignList![0].name} (ID: ${_itemCampaignList![0].id})');
      }
    } else {
      print('⚠️ itemCampaignList is null, not updating _itemCampaignList');
    }
    update();
  }

}