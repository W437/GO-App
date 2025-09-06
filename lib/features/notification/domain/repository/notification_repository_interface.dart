import 'package:godelivery_user/common/enums/data_source_enum.dart';
import 'package:godelivery_user/features/notification/domain/models/notification_model.dart';
import 'package:godelivery_user/interface/repository_interface.dart';

abstract class NotificationRepositoryInterface extends RepositoryInterface {
  @override
  Future<List<NotificationModel>?> getList({int? offset, DataSourceEnum? source});
  void saveSeenNotificationCount(int count);
  int? getSeenNotificationCount();
  List<int> getNotificationIdList();
  void addSeenNotificationIdList(List<int> notificationList);
}