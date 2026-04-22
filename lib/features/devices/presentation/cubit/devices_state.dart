import '../../data/models/device_status_model.dart';

class DevicesState {
  const DevicesState({
    this.isLoading = false,
    this.errorMessage,
    this.devices,
  });

  final bool isLoading;
  final String? errorMessage;
  final HomeDevicesStatusModel? devices;

  static const Object _unset = Object();

  DevicesState copyWith({
    bool? isLoading,
    Object? errorMessage = _unset,
    Object? devices = _unset,
  }) {
    return DevicesState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      devices: identical(devices, _unset)
          ? this.devices
          : devices as HomeDevicesStatusModel?,
    );
  }
}
