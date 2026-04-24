import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_client.dart';
import '../models/notification_model.dart';

abstract class NotificationsRemoteDataSource {
  /// Returns the count of unread notifications.
  Future<int> getUnreadCount();

  /// Fetches paginated notifications.
  /// [page] is 1-indexed.
  Future<List<NotificationModel>> getNotifications({required int page});

  /// Marks every notification as read.
  Future<void> markAllAsRead();
}

class NotificationsRemoteDataSourceImpl
    implements NotificationsRemoteDataSource {
  NotificationsRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<int> getUnreadCount() async {
    final response = await _apiClient.get(
      path: '${AppConfig.notificationsBasePath}/unread-number',
    );
    final data = response['data'];
    if (data is Map<String, dynamic>) {
      return (data['newNotifications'] as num?)?.toInt() ?? 0;
    }
    // The response envelope may return the count directly.
    return (response['newNotifications'] as num?)?.toInt() ?? 0;
  }

  @override
  Future<List<NotificationModel>> getNotifications({
    required int page,
  }) async {
    final response = await _apiClient.get(
      path: AppConfig.notificationsBasePath,
      queryParameters: <String, dynamic>{'page': page},
    );

    final data = response['data'];
    List<dynamic> items = const <dynamic>[];
    if (data is List<dynamic>) {
      items = data;
    } else if (data is Map<String, dynamic>) {
      final raw = data['notifications'] ??
          data['items'] ??
          data['docs'] ??
          data['data'];
      if (raw is List<dynamic>) {
        items = raw;
      }
    }

    return items
        .whereType<Map<String, dynamic>>()
        .map(NotificationModel.fromJson)
        .toList(growable: false);
  }

  @override
  Future<void> markAllAsRead() {
    return _apiClient.post(
      path: '${AppConfig.notificationsBasePath}/markAllAsRead',
    );
  }
}
