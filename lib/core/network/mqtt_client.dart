import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../errors/app_exception.dart';
import 'api_response_parser.dart';

/// MQTT client for controlling smart home devices
/// Base URL: http://localhost:3000/mqtt
/// No auth middleware on MQTT routes
class MqttClient {
  MqttClient({required Dio dio}) : _dio = dio;

  final Dio _dio;

  /// Set lamp power (lamp1 or lamp2)
  Future<void> setLampPower({
    required String lampId,
    required bool isOn,
  }) async {
    final endpoint = '${AppConfig.mqttBasePath}/setLed/$lampId';
    await _sendSetCommand(endpoint, isOn);
  }

  /// Set fan power (fan1 or fan2)
  Future<void> setFanPower({
    required String fanId,
    required bool isOn,
  }) async {
    final endpoint = '${AppConfig.mqttBasePath}/setfan/$fanId';
    await _sendSetCommand(endpoint, isOn);
  }

  /// Set alarm (can only turn off)
  Future<void> setAlarm({required bool isOn}) async {
    if (isOn) {
      throw const AppException(
        message: 'Alarm can only be turned off via app.',
      );
    }
    final endpoint = '${AppConfig.mqttBasePath}/setAlarm';
    await _sendSetCommand(endpoint, false);
  }

  Future<void> openDoor({required String password}) async {
    final endpoint = '${AppConfig.mqttBasePath}/opendoor';
    await _sendMqttRequest(endpoint, <String, dynamic>{
      'password': password,
    });
  }

  Future<void> setTempThreshold({required int value}) async {
    final endpoint = '${AppConfig.mqttBasePath}/setTempTreshold';
    await _sendMqttRequest(endpoint, <String, dynamic>{
      'value': value,
    });
  }

  Future<void> _sendSetCommand(String endpoint, bool isOn) {
    return _sendMqttRequest(endpoint, <String, dynamic>{
      'set': isOn ? 'on' : 'off',
    });
  }

  Future<void> _sendMqttRequest(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _dio.post<dynamic>(
        endpoint,
        data: body,
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      final responseBody = ApiResponseParser.decodeBody(response.data);
      ApiResponseParser.validateEnvelope(
        responseBody: responseBody,
        fallbackStatusCode: response.statusCode,
      );

      if (response.statusCode == null ||
          response.statusCode! < 200 ||
          response.statusCode! >= 300) {
        throw const AppException(message: 'Failed to send MQTT command');
      }
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  AppException _mapDioException(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return const NetworkException('MQTT command timed out. Device may be offline.');
    }

    final response = error.response;
    if (response != null) {
      final responseBody = ApiResponseParser.decodeBody(response.data);
      return ServerException(
        message: ApiResponseParser.extractMessage(responseBody) ??
            'Failed to control device. Status: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }

    return NetworkException(
      error.message ?? 'Network error. Device may be offline.',
    );
  }
}
