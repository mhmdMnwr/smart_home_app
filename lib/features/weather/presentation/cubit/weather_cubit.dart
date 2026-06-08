import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/mqtt_live_service.dart';
import 'weather_state.dart';

class WeatherCubit extends Cubit<WeatherState> {
  WeatherCubit({required MqttLiveService mqttLiveService})
    : _mqttLiveService = mqttLiveService,
      super(const WeatherState());

  final MqttLiveService _mqttLiveService;
  StreamSubscription<WeatherReading>? _weatherSubscription;

  /// Start listening to MQTT weather readings.
  void start() {
    _mqttLiveService.connect();
    _weatherSubscription?.cancel();
    _weatherSubscription = _mqttLiveService.weatherReadings.listen(
      (reading) {
        emit(state.copyWith(
          latestReading: reading,
          isConnecting: false,
        ));
      },
    );
  }

  @override
  Future<void> close() async {
    await _weatherSubscription?.cancel();
    _weatherSubscription = null;
    return super.close();
  }
}
