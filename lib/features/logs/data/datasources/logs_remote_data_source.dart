import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_client.dart';
import '../models/log_entry_model.dart';
import '../models/logs_page_model.dart';

abstract class LogsRemoteDataSource {
  Future<LogsPageModel> getLogs({
    required int page,
    required int limit,
  });
}

class LogsRemoteDataSourceImpl implements LogsRemoteDataSource {
  LogsRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<LogsPageModel> getLogs({
    required int page,
    required int limit,
  }) async {
    final response = await _apiClient.get(
      path: AppConfig.logsBasePath,
      queryParameters: <String, dynamic>{
        'page': page,
        'limit': limit,
      },
    );

    final data = response['data'];
    final source = data is Map<String, dynamic> ? data : response;
    final rawItems = source['data'];

    final items = rawItems is List<dynamic>
        ? rawItems
              .whereType<Map<String, dynamic>>()
              .map(LogEntryModel.fromJson)
              .toList(growable: false)
        : const <LogEntryModel>[];

    return LogsPageModel(
      items: items,
      total: (source['total'] as num?)?.toInt() ?? items.length,
      page: page,
      limit: limit,
    );
  }
}
