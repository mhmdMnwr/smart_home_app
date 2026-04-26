import 'log_entry_model.dart';

class LogsPageModel {
  const LogsPageModel({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
  });

  final List<LogEntryModel> items;
  final int total;
  final int page;
  final int limit;

  int get totalPages {
    if (total <= 0) {
      return 1;
    }
    return (total / limit).ceil();
  }
}
