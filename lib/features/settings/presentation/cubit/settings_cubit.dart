import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/mqtt_live_service.dart';
import '../../../../core/storage/mqtt_broker_storage.dart';
import '../../../auth/data/models/user_model.dart';
import '../../data/models/create_user_request_model.dart';
import '../../data/models/update_me_request_model.dart';
import '../../data/repositories/settings_repository.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit({
    required SettingsRepository settingsRepository,
    required MqttBrokerStorage mqttBrokerStorage,
    required MqttLiveService mqttLiveService,
  })  : _settingsRepository = settingsRepository,
        _mqttBrokerStorage = mqttBrokerStorage,
        _mqttLiveService = mqttLiveService,
        super(const SettingsState());

  final SettingsRepository _settingsRepository;
  final MqttBrokerStorage _mqttBrokerStorage;
  final MqttLiveService _mqttLiveService;

  void loadMqttBrokerHost() {
    final host = _mqttBrokerStorage.getHost();
    emit(state.copyWith(mqttBrokerHost: host));
  }

  Future<bool> updateMqttBrokerHost(String host) async {
    final normalized = host.trim();
    if (normalized.isEmpty) {
      emit(state.copyWith(errorMessage: 'Broker host cannot be empty.'));
      return false;
    }

    emit(
      state.copyWith(
        isSavingMqttBrokerHost: true,
        errorMessage: null,
        successMessage: null,
      ),
    );

    try {
      await _mqttBrokerStorage.setHost(normalized);

      // Reconnect MQTT to the new broker host.
      await _mqttLiveService.reconnect();

      emit(
        state.copyWith(
          isSavingMqttBrokerHost: false,
          mqttBrokerHost: normalized,
          successMessage: 'MQTT broker updated. Reconnecting…',
        ),
      );
      return true;
    } catch (_) {
      emit(
        state.copyWith(
          isSavingMqttBrokerHost: false,
          errorMessage: AppStrings.genericError,
        ),
      );
      return false;
    }
  }

  Future<bool> resetMqttBrokerHost() async {
    emit(
      state.copyWith(
        isSavingMqttBrokerHost: true,
        errorMessage: null,
        successMessage: null,
      ),
    );

    try {
      // Empty string removes the stored override and falls back to AppConfig.
      await _mqttBrokerStorage.setHost('');

      await _mqttLiveService.reconnect();

      final effectiveHost = _mqttBrokerStorage.getHost();
      emit(
        state.copyWith(
          isSavingMqttBrokerHost: false,
          mqttBrokerHost: effectiveHost,
          successMessage: 'MQTT broker reset to default. Reconnecting…',
        ),
      );
      return true;
    } catch (_) {
      emit(
        state.copyWith(
          isSavingMqttBrokerHost: false,
          errorMessage: AppStrings.genericError,
        ),
      );
      return false;
    }
  }

  Future<void> loadProfile() async {
    if (state.isLoadingProfile) {
      return;
    }

    emit(
      state.copyWith(
        isLoadingProfile: true,
        errorMessage: null,
        successMessage: null,
      ),
    );

    try {
      final user = await _settingsRepository.getMe();
      emit(
        state.copyWith(
          currentUser: user,
          isLoadingProfile: false,
          errorMessage: null,
        ),
      );
    } on AppException catch (error) {
      emit(
        state.copyWith(
          isLoadingProfile: false,
          errorMessage: error.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isLoadingProfile: false,
          errorMessage: AppStrings.genericError,
        ),
      );
    }
  }

  Future<void> loadFamilyMembers() async {
    if (state.isLoadingFamilyMembers) return;
    emit(
      state.copyWith(
        isLoadingFamilyMembers: true,
        errorMessage: null,
        successMessage: null,
      ),
    );
    try {
      final users = await _settingsRepository.getUsers();
      emit(
        state.copyWith(
          isLoadingFamilyMembers: false,
          familyMembers: users,
        ),
      );
    } on AppException catch (error) {
      emit(
        state.copyWith(
          isLoadingFamilyMembers: false,
          errorMessage: error.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isLoadingFamilyMembers: false,
          errorMessage: AppStrings.genericError,
        ),
      );
    }
  }

  Future<bool> updateMyProfile({
    required String name,
    required String email,
    String? password,
  }) async {
    emit(
      state.copyWith(
        isSavingProfile: true,
        errorMessage: null,
        successMessage: null,
      ),
    );

    try {
      final user = await _settingsRepository.updateMe(
        UpdateMeRequestModel(
          name: name.trim(),
          email: email.trim(),
          password: password?.trim().isEmpty == true ? null : password?.trim(),
        ),
      );
      emit(
        state.copyWith(
          currentUser: user,
          isSavingProfile: false,
          successMessage: 'Profile updated successfully.',
        ),
      );
      return true;
    } on AppException catch (error) {
      emit(
        state.copyWith(
          isSavingProfile: false,
          errorMessage: error.message,
        ),
      );
      return false;
    } catch (_) {
      emit(
        state.copyWith(
          isSavingProfile: false,
          errorMessage: AppStrings.genericError,
        ),
      );
      return false;
    }
  }

  Future<bool> createUser({
    required String name,
    required String email,
    required String password,
    String? phoneNumber,
    UserRole? role,
  }) async {
    emit(
      state.copyWith(
        isCreatingUser: true,
        errorMessage: null,
        successMessage: null,
      ),
    );

    try {
      await _settingsRepository.createUser(
        CreateUserRequestModel(
          name: name.trim(),
          email: email.trim(),
          password: password.trim(),
          phoneNumber: phoneNumber?.trim(),
          role: role,
        ),
      );
      emit(
        state.copyWith(
          isCreatingUser: false,
          successMessage: 'User created successfully.',
        ),
      );
      await loadFamilyMembers();
      return true;
    } on AppException catch (error) {
      emit(
        state.copyWith(
          isCreatingUser: false,
          errorMessage: error.message,
        ),
      );
      return false;
    } catch (_) {
      emit(
        state.copyWith(
          isCreatingUser: false,
          errorMessage: AppStrings.genericError,
        ),
      );
      return false;
    }
  }

  Future<bool> deleteUser({required String userId}) async {
    emit(
      state.copyWith(
        deletingUserId: userId,
        errorMessage: null,
        successMessage: null,
      ),
    );
    try {
      await _settingsRepository.deleteUser(userId: userId);
      emit(
        state.copyWith(
          deletingUserId: null,
          successMessage: 'User removed successfully.',
        ),
      );
      await loadFamilyMembers();
      return true;
    } on AppException catch (error) {
      emit(
        state.copyWith(
          deletingUserId: null,
          errorMessage: error.message,
        ),
      );
      return false;
    } catch (_) {
      emit(
        state.copyWith(
          deletingUserId: null,
          errorMessage: AppStrings.genericError,
        ),
      );
      return false;
    }
  }

  Future<bool> changeDoorPassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    emit(
      state.copyWith(
        isChangingDoorPassword: true,
        errorMessage: null,
        successMessage: null,
      ),
    );

    try {
      await _settingsRepository.changeDoorPassword(
        oldPassword: oldPassword.trim(),
        newPassword: newPassword.trim(),
      );
      emit(
        state.copyWith(
          isChangingDoorPassword: false,
          successMessage: 'Door password updated successfully.',
        ),
      );
      return true;
    } on AppException catch (error) {
      emit(
        state.copyWith(
          isChangingDoorPassword: false,
          errorMessage: error.message,
        ),
      );
      return false;
    } catch (_) {
      emit(
        state.copyWith(
          isChangingDoorPassword: false,
          errorMessage: AppStrings.genericError,
        ),
      );
      return false;
    }
  }

  void clearMessages() {
    emit(state.copyWith(errorMessage: null, successMessage: null));
  }
}
