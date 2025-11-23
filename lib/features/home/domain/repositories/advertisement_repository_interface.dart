import 'package:godelivery_user/features/home/domain/models/advertisement_model.dart';
import 'package:godelivery_user/interface/repository_interface.dart';

abstract class AdvertisementRepositoryInterface extends RepositoryInterface{
  @override
  Future<List<AdvertisementModel>?> getList({int? offset});
}