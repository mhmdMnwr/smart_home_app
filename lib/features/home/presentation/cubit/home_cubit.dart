import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/errors/app_exception.dart';
import '../../data/repositories/home_repository.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit({required HomeRepository homeRepository})
    : _homeRepository = homeRepository,
      super(const HomeState());

  final HomeRepository _homeRepository;

  Future<void> loadDevicesStatus() async {
    if (state.isLoading) {
      return;
    }

    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final devices = await _homeRepository.getDevicesStatus();
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

  void setDevicePower({required String deviceKey, required bool isOn}) {
    final currentDevices = state.devices;
    if (currentDevices == null) {
      return;
    }

    emit(
      state.copyWith(
        devices: currentDevices.updateDeviceStatus(
          deviceKey: deviceKey,
          isOn: isOn,
        ),
      ),
    );
  }
}
