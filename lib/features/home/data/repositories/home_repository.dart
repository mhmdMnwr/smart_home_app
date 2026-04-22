import '../datasources/home_remote_data_source.dart';
import '../models/device_status_model.dart';

abstract class HomeRepository {
  Future<HomeDevicesStatusModel> getDevicesStatus();

  /// Set device power via MQTT
  /// 
  /// Device types:
  /// - lamp1, lamp2: setLed endpoint
  /// - fan1, fan2: setfan endpoint
  /// - alarm: setAlarm endpoint (can only be turned off)
  /// 
  /// Throws AppException if device is offline or command fails
  Future<void> setDevicePower({
    required String deviceKey,
    required bool isOn,
  });

  Future<void> openDoor({required String password});

  Future<void> setFanTempThreshold({required int value});
}

class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl({required HomeRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  final HomeRemoteDataSource _remoteDataSource;

  @override
  Future<HomeDevicesStatusModel> getDevicesStatus() {
    return _remoteDataSource.getDevicesStatus();
  }

  @override
  Future<void> setDevicePower({
    required String deviceKey,
    required bool isOn,
  }) {
    return _remoteDataSource.setDevicePower(
      deviceKey: deviceKey,
      isOn: isOn,
    );
  }

  @override
  Future<void> openDoor({required String password}) {
    return _remoteDataSource.openDoor(password: password);
  }

  @override
  Future<void> setFanTempThreshold({required int value}) {
    return _remoteDataSource.setFanTempThreshold(value: value);
  }
}
