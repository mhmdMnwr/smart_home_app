import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/errors/app_exception.dart';
import '../../data/repositories/notifications_repository.dart';
import 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit({
    required NotificationsRepository notificationsRepository,
  })  : _notificationsRepository = notificationsRepository,
        super(const NotificationsState());

  final NotificationsRepository _notificationsRepository;

  // ── Unread badge count ──────────────────────────────────────────────────

  Future<void> loadUnreadCount() async {
    emit(state.copyWith(isLoadingCount: true, errorMessage: null));
    try {
      final count = await _notificationsRepository.getUnreadCount();
      emit(state.copyWith(unreadCount: count, isLoadingCount: false));
    } on AppException catch (e) {
      emit(state.copyWith(isLoadingCount: false, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(
        isLoadingCount: false,
        errorMessage: AppStrings.genericError,
      ));
    }
  }

  // ── Paginated notifications list ────────────────────────────────────────

  Future<void> loadNotifications() async {
    if (state.isLoadingNotifications) return;
    emit(state.copyWith(
      isLoadingNotifications: true,
      errorMessage: null,
    ));

    try {
      final items =
          await _notificationsRepository.getNotifications(page: 1);
      emit(state.copyWith(
        notifications: items,
        isLoadingNotifications: false,
        currentPage: 1,
        hasReachedEnd: items.isEmpty,
      ));
    } on AppException catch (e) {
      emit(state.copyWith(
        isLoadingNotifications: false,
        errorMessage: e.message,
      ));
    } catch (_) {
      emit(state.copyWith(
        isLoadingNotifications: false,
        errorMessage: AppStrings.genericError,
      ));
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || state.hasReachedEnd) return;

    emit(state.copyWith(isLoadingMore: true));
    final nextPage = state.currentPage + 1;

    try {
      final items =
          await _notificationsRepository.getNotifications(page: nextPage);
      emit(state.copyWith(
        notifications: [...state.notifications, ...items],
        isLoadingMore: false,
        currentPage: nextPage,
        hasReachedEnd: items.isEmpty,
      ));
    } on AppException catch (e) {
      emit(state.copyWith(isLoadingMore: false, errorMessage: e.message));
    } catch (_) {
      emit(state.copyWith(
        isLoadingMore: false,
        errorMessage: AppStrings.genericError,
      ));
    }
  }

  // ── Mark all as read ────────────────────────────────────────────────────

  Future<void> markAllAsRead() async {
    try {
      await _notificationsRepository.markAllAsRead();
      emit(state.copyWith(unreadCount: 0));
    } catch (_) {
      // Silently fail — badge already cleared visually.
    }
  }
}
