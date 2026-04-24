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

/// Singleton service that connects to the MQTT broker and exposes a stream
/// of [SensorReading]s for the three sensor topics.
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
  StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>? _subscription;

  bool _isConnecting = false;
  bool _disposed = false;

  /// The list of topics we subscribe to.
  static const List<String> _sensorTopics = [
    AppConfig.mqttTopicTemperature,
    AppConfig.mqttTopicHumidity,
    AppConfig.mqttTopicGas,
  ];

  /// Stream of live sensor readings.
  Stream<SensorReading> get readings => _controller.stream;

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

      double? value;
      try {
        final json = jsonDecode(rawString.trim());
        if (json is Map<String, dynamic>) {
          // Try common keys: "value", "temperature", "humidity", "gas"
          final raw =
              json['value'] ?? json['temperature'] ?? json['humidity'] ?? json['gas'];
          value =
              raw is num ? raw.toDouble() : double.tryParse(raw?.toString() ?? '');
        } else if (json is num) {
          value = json.toDouble();
        }
      } catch (_) {
        // Fallback: try parsing as plain number
        value = double.tryParse(rawString.trim());
      }

      if (value == null) continue;

      _controller.add(SensorReading(topic: topic, value: value));
    }
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
  }
}
