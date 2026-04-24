import '../../data/models/sensor_history_models.dart';
import '../../data/models/sensors_status_model.dart';

enum SensorType { temperature, humidity, gas, fire }

class SensorHistoryState {
  const SensorHistoryState({
    this.isLoading = false,
    this.errorMessage,
    this.pageData,
    this.allItems = const <SensorHistoryItem>[],
    this.hasReachedMax = false,
    this.currentPage = 0,
  });

  final bool isLoading;
  final String? errorMessage;
  final SensorHistoryPage? pageData;

  /// Accumulated items across all loaded pages (for infinite scroll).
  final List<SensorHistoryItem> allItems;

  /// Whether the last page has been reached.
  final bool hasReachedMax;

  /// The latest page that was loaded.
  final int currentPage;

  static const Object _unset = Object();

  SensorHistoryState copyWith({
    bool? isLoading,
    Object? errorMessage = _unset,
    Object? pageData = _unset,
    List<SensorHistoryItem>? allItems,
    bool? hasReachedMax,
    int? currentPage,
  }) {
    return SensorHistoryState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      pageData: identical(pageData, _unset)
          ? this.pageData
          : pageData as SensorHistoryPage?,
      allItems: allItems ?? this.allItems,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class SensorsState {
  const SensorsState({
    this.selectedType = SensorType.temperature,
    this.temperatureState = const SensorHistoryState(),
    this.humidityState = const SensorHistoryState(),
    this.gasState = const SensorHistoryState(),
    this.liveTemperature,
    this.liveHumidity,
    this.liveGas,
    this.sensorsStatus,
  });

  final SensorType selectedType;
  final SensorHistoryState temperatureState;
  final SensorHistoryState humidityState;
  final SensorHistoryState gasState;

  /// Live MQTT values (null = not yet received).
  final double? liveTemperature;
  final double? liveHumidity;
  final double? liveGas;

  /// Online/offline status of dht11 and mq2 from /status/sensors.
  final SensorsStatusModel? sensorsStatus;

  /// Returns the live value for the given sensor type, or null.
  double? liveValueFor(SensorType type) {
    switch (type) {
      case SensorType.temperature:
        return liveTemperature;
      case SensorType.humidity:
        return liveHumidity;
      case SensorType.gas:
        return liveGas;
      case SensorType.fire:
        return null;
    }
  }

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
    double? liveTemperature,
    double? liveHumidity,
    double? liveGas,
    SensorsStatusModel? sensorsStatus,
  }) {
    return SensorsState(
      selectedType: selectedType ?? this.selectedType,
      temperatureState: temperatureState ?? this.temperatureState,
      humidityState: humidityState ?? this.humidityState,
      gasState: gasState ?? this.gasState,
      liveTemperature: liveTemperature ?? this.liveTemperature,
      liveHumidity: liveHumidity ?? this.liveHumidity,
      liveGas: liveGas ?? this.liveGas,
      sensorsStatus: sensorsStatus ?? this.sensorsStatus,
    );
  }
}

