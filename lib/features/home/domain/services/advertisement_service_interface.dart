import 'package:godelivery_user/common/enums/data_source_enum.dart';
import 'package:godelivery_user/features/home/domain/models/advertisement_model.dart';

abstract class AdvertisementServiceInterface {
  Future<List<AdvertisementModel>?> getAdvertisementList({required DataSourceEnum source});
}