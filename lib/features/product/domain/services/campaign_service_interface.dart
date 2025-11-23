import 'package:godelivery_user/common/models/product_model.dart';
import 'package:godelivery_user/features/product/domain/models/basic_campaign_model.dart';

abstract class CampaignServiceInterface {
  Future<List<BasicCampaignModel>?> getBasicCampaignList();
  Future<List<Product>?> getItemCampaignList();
  Future<BasicCampaignModel?> getCampaignDetails(String campaignID);
}