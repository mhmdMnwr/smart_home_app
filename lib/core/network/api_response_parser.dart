import 'dart:convert';

import '../errors/app_exception.dart';

class ApiResponseParser {
  const ApiResponseParser._();

  static Map<String, dynamic> decodeBody(dynamic responseBody) {
    if (responseBody == null) {
      return <String, dynamic>{};
    }

    if (responseBody is Map<String, dynamic>) {
      return responseBody;
    }

    if (responseBody is String) {
      if (responseBody.trim().isEmpty) {
        return <String, dynamic>{};
      }

      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return <String, dynamic>{'data': decoded};
    }

    return <String, dynamic>{'data': responseBody};
  }

  static void validateEnvelope({
    required Map<String, dynamic> responseBody,
    int? fallbackStatusCode,
  }) {
    if (!responseBody.containsKey('success') &&
        !responseBody.containsKey('sucess')) {
      return;
    }

    final rawSuccess = responseBody['success'] ?? responseBody['sucess'];
    final isSuccessful = _readAsBool(rawSuccess);
    if (isSuccessful == null || isSuccessful) {
      return;
    }

    throw ServerException(
      message: extractMessage(responseBody) ?? 'Request failed.',
      statusCode: _readAsInt(responseBody['statusCode']) ?? fallbackStatusCode,
    );
  }

  static String? extractMessage(Map<String, dynamic> responseBody) {
    final message = responseBody['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message;
    }

    if (message is List && message.isNotEmpty) {
      return message.first.toString();
    }

    final error = responseBody['error'];
    if (error is String && error.trim().isNotEmpty) {
      return error;
    }

    final data = responseBody['data'];
    if (data is Map<String, dynamic>) {
      final nestedMessage = data['message'];
      if (nestedMessage is String && nestedMessage.trim().isNotEmpty) {
        return nestedMessage;
      }

      final nestedError = data['error'];
      if (nestedError is String && nestedError.trim().isNotEmpty) {
        return nestedError;
      }
    }

    return null;
  }

  static bool? _readAsBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is String) {
      final lower = value.toLowerCase().trim();
      if (lower == 'true') {
        return true;
      }

      if (lower == 'false') {
        return false;
      }
    }

    return null;
  }

  static int? _readAsInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is String) {
      return int.tryParse(value);
    }

    return null;
  }
}
