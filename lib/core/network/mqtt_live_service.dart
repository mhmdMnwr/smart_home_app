import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import '../config/app_config.dart';
import '../storage/mqtt_broker_storage.dart';

/// Holds one live sensor reading.
class SensorReading {
  const SensorReading({required this.topic, required this.value});
  final String topic;
  final double value;
}

/// Holds live weather data assembled from four individual topics.
///
/// All values are percentages (0–100) except [temperature] which is °C.
class WeatherReading {
  const WeatherReading({
    required this.temperature,
    required this.humidity,
    required this.light,
    required this.water,
    required this.receivedAt,
  });

  /// Temperature in degrees Celsius.
  final double temperature;

  /// Humidity percentage (0–100).
  final double humidity;

  /// Light / brightness percentage (0–100).
  final double light;

  /// Water / rain percentage (0–100).
  final double water;

  final DateTime receivedAt;

  WeatherReading copyWith({
    double? temperature,
    double? humidity,
    double? light,
    double? water,
    DateTime? receivedAt,
  }) {
    return WeatherReading(
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      light: light ?? this.light,
      water: water ?? this.water,
      receivedAt: receivedAt ?? this.receivedAt,
    );
  }
}

/// Singleton service that connects to the MQTT broker and exposes streams
/// for both numeric sensor readings and aggregated weather payloads.
///
/// The broker host is read from [MqttBrokerStorage] so it can be changed
/// at runtime from the Settings page.
class MqttLiveService {
  MqttLiveService({required MqttBrokerStorage brokerStorage})
    : _brokerStorage = brokerStorage;

  final MqttBrokerStorage _brokerStorage;

  MqttServerClient? _client;
  final StreamController<SensorReading> _controller =
      StreamController<SensorReading>.broadcast();
  final StreamController<WeatherReading> _weatherController =
      StreamController<WeatherReading>.broadcast();
  StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>? _subscription;

  bool _isConnecting = false;
  bool _disposed = false;

  /// Tracks the latest weather reading assembled from individual topics.
  WeatherReading _latestWeather = WeatherReading(
    temperature: 0,
    humidity: 0,
    light: 0,
    water: 0,
    receivedAt: DateTime.now(),
  );

  /// The list of topics we subscribe to.
  static const List<String> _sensorTopics = [
    AppConfig.mqttTopicTemperature,
    AppConfig.mqttTopicHumidity,
    AppConfig.mqttTopicGas,
  ];

  /// Weather-specific topics (individual values).
  static const List<String> _weatherTopics = [
    AppConfig.mqttTopicWeatherWater,
    AppConfig.mqttTopicWeatherLight,
    AppConfig.mqttTopicWeatherTemperature,
    AppConfig.mqttTopicWeatherHumidity,
  ];

  /// Stream of live sensor readings.
  Stream<SensorReading> get readings => _controller.stream;

  /// Stream of live weather payloads.
  Stream<WeatherReading> get weatherReadings => _weatherController.stream;

  /// Whether the client is currently connected.
  bool get isConnected =>
      _client?.connectionStatus?.state == MqttConnectionState.connected;

  // ────────────────────── connect ──────────────────────

  /// Connect to the broker and subscribe to sensor topics.
  Future<void> connect() async {
    if (isConnected || _isConnecting || _disposed) return;
    _isConnecting = true;

    final brokerHost = _brokerStorage.getHost();

    final client = MqttServerClient.withPort(
      brokerHost,
      '${AppConfig.mqttClientId}_${DateTime.now().millisecondsSinceEpoch}',
      AppConfig.mqttBrokerPort,
    );

    client.logging(on: true);
    client.keepAlivePeriod = 30;
    client.connectTimeoutPeriod = 5000; // 5 s timeout
    client.autoReconnect = true;
    client.resubscribeOnAutoReconnect = true;
    client.onAutoReconnect = _onAutoReconnect;
    client.onAutoReconnected = _onAutoReconnected;
    client.onDisconnected = _onDisconnected;
    client.onConnected = _onConnected;
    client.onSubscribed = _onSubscribed;
    client.setProtocolV311();

    // Build a *valid* CONNECT message — no will topic/message means
    // we must NOT set willQos, otherwise the broker rejects the packet.
    final connMessage = MqttConnectMessage()
        .withClientIdentifier(client.clientIdentifier)
        .startClean();
    client.connectionMessage = connMessage;

    debugPrint(
      '[MQTT] Connecting to $brokerHost:${AppConfig.mqttBrokerPort}...',
    );

    try {
      await client.connect();
    } catch (e) {
      debugPrint('[MQTT] Connection exception: $e');
      _isConnecting = false;
      client.disconnect();
      return;
    }

    if (client.connectionStatus?.state != MqttConnectionState.connected) {
      debugPrint(
        '[MQTT] Failed to connect. Status: ${client.connectionStatus}',
      );
      _isConnecting = false;
      client.disconnect();
      return;
    }

    debugPrint('[MQTT] Connected successfully!');

    _client = client;
    _isConnecting = false;

    _subscribeToTopics(client);
    _listenForMessages(client);
  }

  // ────────────────────── subscribe & listen ──────────────────────

  void _subscribeToTopics(MqttServerClient client) {
    for (final topic in _sensorTopics) {
      client.subscribe(topic, MqttQos.atMostOnce);
    }
    for (final topic in _weatherTopics) {
      client.subscribe(topic, MqttQos.atMostOnce);
    }
  }

  void _listenForMessages(MqttServerClient client) {
    _subscription?.cancel();
    _subscription = client.updates?.listen(_onMessage);
  }

  void _onMessage(List<MqttReceivedMessage<MqttMessage>> messages) {
    for (final msg in messages) {
      final payload = msg.payload;
      if (payload is! MqttPublishMessage) continue;

      final topic = msg.topic;
      final rawString = MqttPublishPayload.bytesToStringAsString(
        payload.payload.message,
      );

      debugPrint('[MQTT] ← $topic : $rawString');

      // ── Handle weather topics ──
      if (_weatherTopics.contains(topic)) {
        _handleWeatherTopic(topic, rawString);
        continue;
      }

      // ── Handle sensor topics ──
      final jsonMap = _decodeJsonMap(rawString);

      double? value;
      if (jsonMap != null) {
        // Try common keys: "value", "temperature", "humidity", "gas"
        final raw =
            jsonMap['value'] ??
            jsonMap['temperature'] ??
            jsonMap['humidity'] ??
            jsonMap['gas'];
        value = _toDouble(raw);
      }

      if (value == null) {
        try {
          final json = jsonDecode(rawString.trim());
          if (json is num) {
            value = json.toDouble();
          }
        } catch (_) {
          // Fallback: try parsing as plain number
          value = double.tryParse(rawString.trim());
        }
      }

      if (value == null) continue;

      _controller.add(SensorReading(topic: topic, value: value));
    }
  }

  /// Handles an individual weather topic by parsing the numeric value
  /// and merging it into the latest aggregated [WeatherReading].
  void _handleWeatherTopic(String topic, String rawString) {
    final value = _parseNumericPayload(rawString);
    if (value == null) return;

    final now = DateTime.now();

    switch (topic) {
      case AppConfig.mqttTopicWeatherTemperature:
        _latestWeather = _latestWeather.copyWith(
          temperature: value,
          receivedAt: now,
        );
        break;
      case AppConfig.mqttTopicWeatherHumidity:
        _latestWeather = _latestWeather.copyWith(
          humidity: value.clamp(0, 100),
          receivedAt: now,
        );
        break;
      case AppConfig.mqttTopicWeatherLight:
        _latestWeather = _latestWeather.copyWith(
          light: value.clamp(0, 100),
          receivedAt: now,
        );
        break;
      case AppConfig.mqttTopicWeatherWater:
        _latestWeather = _latestWeather.copyWith(
          water: value.clamp(0, 100),
          receivedAt: now,
        );
        break;
    }

    _weatherController.add(_latestWeather);
  }

  /// Parses a raw MQTT string as a single numeric value.
  /// Supports plain numbers and simple JSON objects with common keys.
  double? _parseNumericPayload(String rawString) {
    final trimmed = rawString.trim();

    // Plain number
    final plain = double.tryParse(trimmed);
    if (plain != null) return plain;

    // JSON number
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is num) return decoded.toDouble();
      if (decoded is Map<String, dynamic>) {
        final raw =
            decoded['value'] ??
            decoded['temperature'] ??
            decoded['humidity'] ??
            decoded['light'] ??
            decoded['water'];
        return _toDouble(raw);
      }
    } catch (_) {}

    return null;
  }

  Map<String, dynamic>? _decodeJsonMap(String rawString) {
    try {
      final decoded = jsonDecode(rawString.trim());
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      // Ignore parsing errors and fallback to number parsing for sensor topics.
    }
    return null;
  }

  double? _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  // ────────────────────── callbacks ──────────────────────

  void _onConnected() {
    debugPrint('[MQTT] onConnected callback fired');
  }

  void _onSubscribed(String topic) {
    debugPrint('[MQTT] Subscribed to $topic');
  }

  void _onAutoReconnect() {
    debugPrint('[MQTT] Auto-reconnecting...');
  }

  void _onAutoReconnected() {
    debugPrint('[MQTT] Auto-reconnected — re-subscribing');
    final c = _client;
    if (c == null) return;
    _subscribeToTopics(c);
    // Re-attach the listener in case the old stream was closed.
    _listenForMessages(c);
  }

  void _onDisconnected() {
    debugPrint('[MQTT] Disconnected');
  }

  // ────────────────────── disconnect / reconnect ──────────────────────

  /// Disconnect and clean up resources.
  Future<void> disconnect() async {
    _subscription?.cancel();
    _subscription = null;
    try {
      _client?.disconnect();
    } catch (_) {
      // Ignore errors during disconnect
    }
    _client = null;
    _isConnecting = false;
  }

  /// Reconnect — disconnects first, then connects with the (possibly updated)
  /// broker host from storage.
  Future<void> reconnect() async {
    await disconnect();
    // Small delay so the old socket fully closes.
    await Future<void>.delayed(const Duration(milliseconds: 500));
    await connect();
  }

  /// Dispose the service entirely.
  void dispose() {
    _disposed = true;
    disconnect();
    _controller.close();
    _weatherController.close();
  }
}
