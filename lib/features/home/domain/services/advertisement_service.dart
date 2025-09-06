import 'package:godelivery_user/common/enums/data_source_enum.dart';
import 'package:godelivery_user/features/home/domain/models/advertisement_model.dart';
import 'package:godelivery_user/features/home/domain/repositories/advertisement_repository_interface.dart';
import 'package:godelivery_user/features/home/domain/services/advertisement_service_interface.dart';

class AdvertisementService implements AdvertisementServiceInterface{
  final AdvertisementRepositoryInterface advertisementRepositoryInterface;
  AdvertisementService({required this.advertisementRepositoryInterface});

  @override
  Future<List<AdvertisementModel>?> getAdvertisementList({required DataSourceEnum source}) async {
    return await advertisementRepositoryInterface.getList(source: source);
  }

}