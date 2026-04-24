import '../../data/models/notification_model.dart';

class NotificationsState {
  const NotificationsState({
    this.unreadCount = 0,
    this.notifications = const <NotificationModel>[],
    this.isLoadingCount = false,
    this.isLoadingNotifications = false,
    this.isLoadingMore = false,
    this.hasReachedEnd = false,
    this.currentPage = 0,
    this.errorMessage,
  });

  final int unreadCount;
  final List<NotificationModel> notifications;
  final bool isLoadingCount;
  final bool isLoadingNotifications;
  final bool isLoadingMore;
  final bool hasReachedEnd;
  final int currentPage;
  final String? errorMessage;

  static const Object _unset = Object();

  NotificationsState copyWith({
    int? unreadCount,
    List<NotificationModel>? notifications,
    bool? isLoadingCount,
    bool? isLoadingNotifications,
    bool? isLoadingMore,
    bool? hasReachedEnd,
    int? currentPage,
    Object? errorMessage = _unset,
  }) {
    return NotificationsState(
      unreadCount: unreadCount ?? this.unreadCount,
      notifications: notifications ?? this.notifications,
      isLoadingCount: isLoadingCount ?? this.isLoadingCount,
      isLoadingNotifications:
          isLoadingNotifications ?? this.isLoadingNotifications,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
      currentPage: currentPage ?? this.currentPage,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}
