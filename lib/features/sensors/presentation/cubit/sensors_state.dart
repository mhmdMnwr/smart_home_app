import '../../data/models/sensor_history_models.dart';

enum SensorType { temperature, humidity, gas, fire }

class SensorHistoryState {
  const SensorHistoryState({
    this.isLoading = false,
    this.errorMessage,
    this.pageData,
  });

  final bool isLoading;
  final String? errorMessage;
  final SensorHistoryPage? pageData;

  static const Object _unset = Object();

  SensorHistoryState copyWith({
    bool? isLoading,
    Object? errorMessage = _unset,
    Object? pageData = _unset,
  }) {
    return SensorHistoryState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      pageData: identical(pageData, _unset)
          ? this.pageData
          : pageData as SensorHistoryPage?,
    );
  }
}

class SensorsState {
  const SensorsState({
    this.selectedType = SensorType.temperature,
    this.temperatureState = const SensorHistoryState(),
    this.humidityState = const SensorHistoryState(),
    this.gasState = const SensorHistoryState(),
  });

  final SensorType selectedType;
  final SensorHistoryState temperatureState;
  final SensorHistoryState humidityState;
  final SensorHistoryState gasState;

  SensorHistoryState historyStateFor(SensorType type) {
    switch (type) {
      case SensorType.temperature:
        return temperatureState;
      case SensorType.humidity:
        return humidityState;
      case SensorType.gas:
        return gasState;
      case SensorType.fire:
        return const SensorHistoryState();
    }
  }

  SensorsState copyWith({
    SensorType? selectedType,
    SensorHistoryState? temperatureState,
    SensorHistoryState? humidityState,
    SensorHistoryState? gasState,
  }) {
    return SensorsState(
      selectedType: selectedType ?? this.selectedType,
      temperatureState: temperatureState ?? this.temperatureState,
      humidityState: humidityState ?? this.humidityState,
      gasState: gasState ?? this.gasState,
    );
  }
}
