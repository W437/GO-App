import 'package:godelivery_user/common/enums/data_source_enum.dart';
import 'package:godelivery_user/interface/repository_interface.dart';

abstract class CampaignRepositoryInterface implements RepositoryInterface {
  @override
  Future<dynamic> getList({int? offset, bool basicCampaign = false, DataSourceEnum? source});
}