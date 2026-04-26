import '../../data/models/log_entry_model.dart';

class LogsState {
  const LogsState({
    this.logs = const <LogEntryModel>[],
    this.total = 0,
    this.currentPage = 1,
    this.limit = 10,
    this.isLoading = false,
    this.errorMessage,
  });

  final List<LogEntryModel> logs;
  final int total;
  final int currentPage;
  final int limit;
  final bool isLoading;
  final String? errorMessage;

  static const Object _unset = Object();

  int get totalPages {
    if (total <= 0) {
      return 1;
    }
    return (total / limit).ceil();
  }

  LogsState copyWith({
    List<LogEntryModel>? logs,
    int? total,
    int? currentPage,
    int? limit,
    bool? isLoading,
    Object? errorMessage = _unset,
  }) {
    return LogsState(
      logs: logs ?? this.logs,
      total: total ?? this.total,
      currentPage: currentPage ?? this.currentPage,
      limit: limit ?? this.limit,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}
