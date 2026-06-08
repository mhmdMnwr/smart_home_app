import '../datasources/devices_remote_data_source.dart';
import '../models/device_status_model.dart';

abstract class DevicesRepository {
  Future<HomeDevicesStatusModel> getDevicesStatus();

  Future<void> setDevicePower({
    required String deviceKey,
    required bool isOn,
  });

  Future<void> setFanTempThreshold({required double value});
}

class DevicesRepositoryImpl implements DevicesRepository {
  DevicesRepositoryImpl({required DevicesRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  final DevicesRemoteDataSource _remoteDataSource;

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
  Future<void> setFanTempThreshold({required double value}) {
    return _remoteDataSource.setFanTempThreshold(value: value);
  }
}
