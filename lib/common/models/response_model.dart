/// Generic API response wrapper model
/// Standardizes API responses with success status, messages, and optional data payloads
import 'package:godelivery_user/features/auth/domain/models/auth_response_model.dart';
import 'package:godelivery_user/features/profile/domain/models/update_profile_response_model.dart';

class ResponseModel {
  final bool _isSuccess;
  final String? _message;
  final String? code;
  List<int>? zoneIds;
  AuthResponseModel? authResponseModel;
  UpdateProfileResponseModel? updateProfileResponseModel;
  ResponseModel(this._isSuccess, this._message, {this.zoneIds, this.authResponseModel, this.updateProfileResponseModel, this.code});

  String? get message => _message;
  bool get isSuccess => _isSuccess;
}