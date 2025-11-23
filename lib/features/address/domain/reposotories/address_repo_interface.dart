import 'package:godelivery_user/features/address/domain/models/address_model.dart';
import 'package:godelivery_user/interface/repository_interface.dart';

abstract class AddressRepoInterface<T> implements RepositoryInterface<AddressModel> {
  @override
  Future<List<AddressModel>?> getList({int? offset, bool isLocal = false});
}