import '../../../../core/config/app_config.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/mqtt_client.dart';
import '../models/device_status_model.dart';

abstract class DevicesRemoteDataSource {
  Future<HomeDevicesStatusModel> getDevicesStatus();

  Future<void> setDevicePower({
    required String deviceKey,
    required bool isOn,
  });

  Future<void> openDoor({required String password});

  Future<void> setFanTempThreshold({required double value});
}

class DevicesRemoteDataSourceImpl implements DevicesRemoteDataSource {
  DevicesRemoteDataSourceImpl({
    required ApiClient apiClient,
    required MqttClient mqttClient,
  })  : _apiClient = apiClient,
        _mqttClient = mqttClient;

  final ApiClient _apiClient;
  final MqttClient _mqttClient;

  @override
  Future<HomeDevicesStatusModel> getDevicesStatus() async {
    final response = await _apiClient.get(path: AppConfig.devicesStatusPath);
    return _mapDevicesResponse(response);
  }

  @override
  Future<void> setDevicePower({
    required String deviceKey,
    required bool isOn,
  }) async {
    switch (deviceKey) {
      case 'lamp1':
      case 'lamp2':
        return _mqttClient.setLampPower(
          lampId: deviceKey,
          isOn: isOn,
        );
      case 'fan1':
      case 'fan2':
        return _mqttClient.setFanPower(
          fanId: deviceKey,
          isOn: isOn,
        );
      case 'alarm':
        return _mqttClient.setAlarm(isOn: isOn);
      default:
        throw AppException(message: 'Unknown device: $deviceKey');
    }
  }

  @override
  Future<void> openDoor({required String password}) {
    return _mqttClient.openDoor(password: password);
  }

  @override
  Future<void> setFanTempThreshold({required double value}) {
    return _mqttClient.setTempThreshold(value: value);
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
