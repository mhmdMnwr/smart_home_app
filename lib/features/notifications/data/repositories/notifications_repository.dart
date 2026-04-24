import '../datasources/notifications_remote_data_source.dart';
import '../models/notification_model.dart';

abstract class NotificationsRepository {
  Future<int> getUnreadCount();
  Future<List<NotificationModel>> getNotifications({required int page});
  Future<void> markAllAsRead();
}

class NotificationsRepositoryImpl implements NotificationsRepository {
  NotificationsRepositoryImpl({
    required NotificationsRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final NotificationsRemoteDataSource _remoteDataSource;

  @override
  Future<int> getUnreadCount() {
    return _remoteDataSource.getUnreadCount();
  }

  @override
  Future<List<NotificationModel>> getNotifications({required int page}) {
    return _remoteDataSource.getNotifications(page: page);
  }

  @override
  Future<void> markAllAsRead() {
    return _remoteDataSource.markAllAsRead();
  }
}
