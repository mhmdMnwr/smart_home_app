import '../datasources/logs_remote_data_source.dart';
import '../models/logs_page_model.dart';

abstract class LogsRepository {
  Future<LogsPageModel> getLogs({
    required int page,
    required int limit,
  });
}

class LogsRepositoryImpl implements LogsRepository {
  LogsRepositoryImpl({
    required LogsRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final LogsRemoteDataSource _remoteDataSource;

  @override
  Future<LogsPageModel> getLogs({
    required int page,
    required int limit,
  }) {
    return _remoteDataSource.getLogs(page: page, limit: limit);
  }
}
