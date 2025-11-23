import 'package:godelivery_user/features/home/domain/models/banner_model.dart';
import 'package:godelivery_user/features/home/domain/models/cashback_model.dart';
import 'package:godelivery_user/interface/repository_interface.dart';

abstract class HomeRepositoryInterface extends RepositoryInterface {
  @override
  Future<BannerModel?> getList({int? offset});
  Future<List<CashBackModel>?> getCashBackOfferList();
  Future<CashBackModel?> getCashBackData(double amount);
}
