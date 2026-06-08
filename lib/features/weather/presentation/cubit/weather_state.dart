import '../../../../core/network/mqtt_live_service.dart';

class WeatherState {
  const WeatherState({
    this.latestReading,
    this.isConnecting = true,
  });

  /// The latest weather reading from MQTT, null when waiting for first data.
  final WeatherReading? latestReading;

  /// Whether we're still waiting for the initial connection/data.
  final bool isConnecting;

  WeatherState copyWith({
    WeatherReading? latestReading,
    bool? isConnecting,
  }) {
    return WeatherState(
      latestReading: latestReading ?? this.latestReading,
      isConnecting: isConnecting ?? this.isConnecting,
    );
  }
}
