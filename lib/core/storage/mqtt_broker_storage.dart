import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

/// Persists the MQTT broker host so it can be changed from the Settings page
/// and survives app restarts.
class MqttBrokerStorage {
  MqttBrokerStorage(this._preferences);

  static const String _brokerHostKey = 'mqtt_broker_host';

  final SharedPreferences _preferences;

  /// Returns the stored broker host, or the compile-time default.
  String getHost() {
    return _preferences.getString(_brokerHostKey) ??
        AppConfig.mqttBrokerHost;
  }

  /// Persists a new broker host.
  Future<void> setHost(String host) async {
    await _preferences.setString(_brokerHostKey, host);
  }

  /// Removes the stored override so the default is used again.
  Future<void> clear() async {
    await _preferences.remove(_brokerHostKey);
  }
}
