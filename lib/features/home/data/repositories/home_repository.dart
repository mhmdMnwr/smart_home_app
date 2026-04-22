import '../datasources/home_remote_data_source.dart';
import '../models/device_status_model.dart';

abstract class HomeRepository {
  Future<HomeDevicesStatusModel> getDevicesStatus();
}

class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl({required HomeRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  final HomeRemoteDataSource _remoteDataSource;

  @override
  Future<HomeDevicesStatusModel> getDevicesStatus() {
    return _remoteDataSource.getDevicesStatus();
  }
}
