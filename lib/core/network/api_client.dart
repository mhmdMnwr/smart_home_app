import 'package:dio/dio.dart';

import '../errors/app_exception.dart';
import 'api_response_parser.dart';

class ApiClient {
  ApiClient({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<Map<String, dynamic>> get({
    required String path,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
        options: Options(headers: headers),
      );

      return _decodeAndValidateResponse(response);
    } on DioException catch (error) {
      throw _mapDioException(error);
    } on FormatException {
      throw const AppException(message: 'Invalid response format from server.');
    }
  }

  Future<Map<String, dynamic>> post({
    required String path,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        path,
        data: body ?? <String, dynamic>{},
        options: Options(headers: headers),
      );

      return _decodeAndValidateResponse(response);
    } on DioException catch (error) {
      throw _mapDioException(error);
    } on FormatException {
      throw const AppException(message: 'Invalid response format from server.');
    }
  }

  Future<Map<String, dynamic>> patch({
    required String path,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.patch<dynamic>(
        path,
        data: body ?? <String, dynamic>{},
        options: Options(headers: headers),
      );

      return _decodeAndValidateResponse(response);
    } on DioException catch (error) {
      throw _mapDioException(error);
    } on FormatException {
      throw const AppException(message: 'Invalid response format from server.');
    }
  }

  Future<Map<String, dynamic>> delete({
    required String path,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.delete<dynamic>(
        path,
        data: body,
        options: Options(headers: headers),
      );

      return _decodeAndValidateResponse(response);
    } on DioException catch (error) {
      throw _mapDioException(error);
    } on FormatException {
      throw const AppException(message: 'Invalid response format from server.');
    }
  }

  Map<String, dynamic> _decodeAndValidateResponse(Response<dynamic> response) {
    final decodedBody = ApiResponseParser.decodeBody(response.data);
    ApiResponseParser.validateEnvelope(
      responseBody: decodedBody,
      fallbackStatusCode: response.statusCode,
    );
    return decodedBody;
  }

  AppException _mapDioException(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return const NetworkException('Request timed out. Please try again.');
    }

    final response = error.response;
    if (response != null) {
      final decodedBody = ApiResponseParser.decodeBody(response.data);
      return ServerException(
        message: ApiResponseParser.extractMessage(decodedBody) ??
            'Request failed.',
        statusCode: response.statusCode,
      );
    }

    return NetworkException(
      error.message ?? 'Network error. Please try again.',
    );
  }
}
