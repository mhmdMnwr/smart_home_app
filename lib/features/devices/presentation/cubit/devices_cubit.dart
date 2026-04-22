import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/errors/app_exception.dart';
import '../../data/repositories/devices_repository.dart';
import 'devices_state.dart';

class DevicesCubit extends Cubit<DevicesState> {
  DevicesCubit({required DevicesRepository devicesRepository})
    : _devicesRepository = devicesRepository,
      super(const DevicesState());

  final DevicesRepository _devicesRepository;

  Future<void> loadDevicesStatus() async {
    if (state.isLoading) {
      return;
    }

    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final devices = await _devicesRepository.getDevicesStatus();
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: null,
          devices: devices,
        ),
      );
    } on AppException catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: error.message));
    } catch (_) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: AppStrings.genericError,
        ),
      );
    }
  }

  void setDevicePower({
    required String deviceKey,
    required bool isOn,
  }) {
    final currentDevices = state.devices;
    if (currentDevices == null) {
      emit(state.copyWith(errorMessage: 'Devices not loaded'));
      return;
    }

    final device = currentDevices.deviceByKey(deviceKey);
    if (deviceKey == 'alarm') {
      if (!device.isOnline) {
        emit(
          state.copyWith(
            errorMessage: 'Alarm is already off. You can switch only when it is on.',
          ),
        );
        return;
      }

      if (isOn) {
        emit(
          state.copyWith(
            errorMessage: 'Alarm can only be switched off via the app.',
          ),
        );
        return;
      }
    }

    final optimisticDevices = currentDevices.updateDeviceStatus(
      deviceKey: deviceKey,
      isOn: isOn,
    );
    emit(
      state.copyWith(
        devices: optimisticDevices,
        errorMessage: null,
      ),
    );

    _devicesRepository.setDevicePower(
      deviceKey: deviceKey,
      isOn: isOn,
    );
  }

  Future<bool> openDoor({required String password}) async {
    final normalizedPassword = password.trim();
    if (normalizedPassword.isEmpty) {
      emit(state.copyWith(errorMessage: 'Door password is required.'));
      return false;
    }

    try {
      await _devicesRepository.openDoor(password: normalizedPassword);
      emit(state.copyWith(errorMessage: null));
      return true;
    } on AppException catch (error) {
      emit(state.copyWith(errorMessage: error.message));
      return false;
    } catch (_) {
      emit(state.copyWith(errorMessage: AppStrings.genericError));
      return false;
    }
  }

  Future<bool> setFanTempThreshold({required int value}) async {
    if (value < 0 || value > 100) {
      emit(
        state.copyWith(
          errorMessage: 'Temperature threshold must be between 0 and 100.',
        ),
      );
      return false;
    }

    try {
      await _devicesRepository.setFanTempThreshold(value: value);
      emit(state.copyWith(errorMessage: null));
      return true;
    } on AppException catch (error) {
      emit(state.copyWith(errorMessage: error.message));
      return false;
    } catch (_) {
      emit(state.copyWith(errorMessage: AppStrings.genericError));
      return false;
    }
  }
}
