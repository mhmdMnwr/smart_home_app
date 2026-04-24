import '../../../auth/data/models/user_model.dart';
import '../datasources/settings_remote_data_source.dart';
import '../models/create_user_request_model.dart';
import '../models/family_member_model.dart';
import '../models/update_me_request_model.dart';

abstract class SettingsRepository {
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

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl({required SettingsRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  final SettingsRemoteDataSource _remoteDataSource;

  @override
  Future<UserModel> getMe() {
    return _remoteDataSource.getMe();
  }

  @override
  Future<UserModel> updateMe(UpdateMeRequestModel request) {
    return _remoteDataSource.updateMe(request);
  }

  @override
  Future<void> createUser(CreateUserRequestModel request) {
    return _remoteDataSource.createUser(request);
  }

  @override
  Future<List<FamilyMemberModel>> getUsers() {
    return _remoteDataSource.getUsers();
  }

  @override
  Future<void> deleteUser({required String userId}) {
    return _remoteDataSource.deleteUser(userId: userId);
  }

  @override
  Future<void> changeDoorPassword({
    required String oldPassword,
    required String newPassword,
  }) {
    return _remoteDataSource.changeDoorPassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
  }
}
