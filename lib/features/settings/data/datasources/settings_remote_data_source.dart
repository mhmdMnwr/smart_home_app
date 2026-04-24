import '../../../../core/config/app_config.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/mqtt_client.dart';
import '../../../auth/data/models/user_model.dart';
import '../models/create_user_request_model.dart';
import '../models/family_member_model.dart';
import '../models/update_me_request_model.dart';

abstract class SettingsRemoteDataSource {
  Future<UserModel> getMe();
  Future<UserModel> updateMe(UpdateMeRequestModel request);
  Future<void> createUser(CreateUserRequestModel request);
  Future<List<FamilyMemberModel>> getUsers();
  Future<void> deleteUser({required String userId});
  Future<void> changeDoorPassword({
    required String oldPassword,
    required String newPassword,
  });
}

class SettingsRemoteDataSourceImpl implements SettingsRemoteDataSource {
  SettingsRemoteDataSourceImpl({
    required ApiClient apiClient,
    required MqttClient mqttClient,
  })  : _apiClient = apiClient,
        _mqttClient = mqttClient;

  final ApiClient _apiClient;
  final MqttClient _mqttClient;

  @override
  Future<UserModel> getMe() async {
    final response = await _apiClient.get(path: AppConfig.mePath);
    return _extractUser(response);
  }

  @override
  Future<UserModel> updateMe(UpdateMeRequestModel request) async {
    final response = await _apiClient.patch(
      path: '${AppConfig.usersBasePath}/me',
      body: request.toJson(),
    );
    return _extractUser(response);
  }

  @override
  Future<void> createUser(CreateUserRequestModel request) {
    return _apiClient.post(
      path: AppConfig.usersBasePath,
      body: request.toJson(),
    );
  }

  @override
  Future<List<FamilyMemberModel>> getUsers() async {
    final response = await _apiClient.get(path: AppConfig.usersBasePath);
    final data = response['data'];

    List<dynamic> items = const <dynamic>[];
    if (data is List<dynamic>) {
      items = data;
    } else if (data is Map<String, dynamic>) {
      final rawUsers = data['users'] ?? data['items'] ?? data['data'];
      if (rawUsers is List<dynamic>) {
        items = rawUsers;
      }
    }

    return items
        .whereType<Map<String, dynamic>>()
        .map(FamilyMemberModel.fromJson)
        .toList(growable: false);
  }

  @override
  Future<void> deleteUser({required String userId}) {
    return _apiClient.delete(path: '${AppConfig.usersBasePath}/$userId');
  }

  @override
  Future<void> changeDoorPassword({
    required String oldPassword,
    required String newPassword,
  }) {
    return _mqttClient.changeDoorPassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
  }

  UserModel _extractUser(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw const AppException(message: 'Invalid user payload.');
    }

    final rawUser = data['user'];
    if (rawUser is Map<String, dynamic>) {
      return UserModel.fromJson(rawUser);
    }

    return UserModel.fromJson(data);
  }
}
