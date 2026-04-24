import '../../../../core/config/app_config.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/api_client.dart';
import '../models/sensor_history_models.dart';
import '../models/sensors_status_model.dart';

abstract class SensorsRemoteDataSource {
  Future<SensorHistoryPage> getHistory({
    required String type,
    int page = 1,
    int limit = 10,
  });

  Future<SensorsStatusModel> getSensorsStatus();
}

class SensorsRemoteDataSourceImpl implements SensorsRemoteDataSource {
  SensorsRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<SensorHistoryPage> getHistory({
    required String type,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _apiClient.get(
        path: AppConfig.historyBasePath,
        queryParameters: <String, dynamic>{
          'type': type,
          'page': page,
          'limit': limit,
        },
      );

      return _mapHistoryResponse(response);
    } on AppException catch (error) {
      if (error.statusCode != 404) {
        rethrow;
      }

      final fallbackResponse = await _apiClient.get(
        path: '${AppConfig.historyBasePath}/type/$type',
        queryParameters: <String, dynamic>{
          'page': page,
          'limit': limit,
        },
      );

      return _mapHistoryResponse(fallbackResponse);
    }
  }

  @override
  Future<SensorsStatusModel> getSensorsStatus() async {
    final response = await _apiClient.get(path: AppConfig.sensorsStatusPath);

    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw const AppException(
        message: 'Sensors status response has invalid data payload.',
      );
    }

    return SensorsStatusModel.fromApi(data);
  }

  SensorHistoryPage _mapHistoryResponse(Map<String, dynamic> response) {
    final payload = response['data'];
    if (payload is! Map<String, dynamic>) {
      throw const AppException(
        message: 'History response has invalid data payload.',
      );
    }

    return SensorHistoryPage.fromApi(payload);
  }
}
