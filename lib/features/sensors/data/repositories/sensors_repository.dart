import '../datasources/sensors_remote_data_source.dart';
import '../models/sensor_history_models.dart';
import '../models/sensors_status_model.dart';

abstract class SensorsRepository {
  Future<SensorHistoryPage> getHistory({
    required String type,
    int page = 1,
    int limit = 10,
  });

  Future<SensorsStatusModel> getSensorsStatus();
}

class SensorsRepositoryImpl implements SensorsRepository {
  SensorsRepositoryImpl({required SensorsRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  final SensorsRemoteDataSource _remoteDataSource;

  @override
  Future<SensorHistoryPage> getHistory({
    required String type,
    int page = 1,
    int limit = 10,
  }) {
    return _remoteDataSource.getHistory(type: type, page: page, limit: limit);
  }

  @override
  Future<SensorsStatusModel> getSensorsStatus() {
    return _remoteDataSource.getSensorsStatus();
  }
}
