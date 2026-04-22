import '../../../../core/config/app_config.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/api_client.dart';
import '../models/device_status_model.dart';

abstract class HomeRemoteDataSource {
  Future<HomeDevicesStatusModel> getDevicesStatus();
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  HomeRemoteDataSourceImpl({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<HomeDevicesStatusModel> getDevicesStatus() async {
    try {
      final response = await _apiClient.get(path: AppConfig.devicesPath);
      return _mapDevicesResponse(response);
    } on AppException catch (error) {
      if (error.statusCode != 404) {
        rethrow;
      }

      final fallbackResponse = await _apiClient.get(
        path: AppConfig.statusDevicesPath,
      );
      return _mapDevicesResponse(fallbackResponse);
    }
  }

  HomeDevicesStatusModel _mapDevicesResponse(Map<String, dynamic> response) {
    final payload = response['data'];
    if (payload is! Map<String, dynamic>) {
      throw const AppException(
        message: 'Devices status response has invalid data payload.',
      );
    }

    return HomeDevicesStatusModel.fromApi(payload);
  }
}
