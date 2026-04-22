import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../features/auth/data/models/auth_tokens_response_model.dart';
import '../config/app_config.dart';
import '../storage/token_storage.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({required Dio dio, required TokenStorage tokenStorage})
    : _dio = dio,
      _tokenStorage = tokenStorage;

  static const String _retryKey = 'retryAfterRefresh';
  static const String _skipAuthKey = 'skipAuth';
  static const String _skipRefreshKey = 'skipRefresh';

  final Dio _dio;
  final TokenStorage _tokenStorage;

  Completer<String?>? _refreshCompleter;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final shouldSkipAuth =
        options.extra[_skipAuthKey] == true || _isPublicAuthPath(options.path);

    if (shouldSkipAuth) {
      handler.next(options);
      return;
    }

    final accessToken = _tokenStorage.accessToken;
    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final requestOptions = err.requestOptions;
    final statusCode = err.response?.statusCode;
    final hasRetried = requestOptions.extra[_retryKey] == true;
    final skipRefresh = requestOptions.extra[_skipRefreshKey] == true;
    final shouldSkip =
        _isPublicAuthPath(requestOptions.path) || skipRefresh || hasRetried;

    if (statusCode != 401 || shouldSkip) {
      handler.next(err);
      return;
    }

    final newAccessToken = await _refreshAccessToken();
    if (newAccessToken == null || newAccessToken.isEmpty) {
      await _tokenStorage.clear();
      handler.next(err);
      return;
    }

    requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
    requestOptions.extra[_retryKey] = true;

    try {
      final response = await _dio.fetch<dynamic>(requestOptions);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    } catch (_) {
      handler.next(err);
    }
  }

  Future<String?> _refreshAccessToken() async {
    final pendingRefresh = _refreshCompleter;
    if (pendingRefresh != null) {
      return pendingRefresh.future;
    }

    final refreshToken = _tokenStorage.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      return null;
    }

    final completer = Completer<String?>();
    _refreshCompleter = completer;

    try {
      final response = await _dio.post<dynamic>(
        AppConfig.refreshPath,
        data: <String, dynamic>{'refreshToken': refreshToken},
        options: Options(
          extra: const <String, dynamic>{
            _skipAuthKey: true,
            _skipRefreshKey: true,
          },
        ),
      );

      final responseMap = _asJsonMap(response.data);
      final refreshedTokens = AuthTokensResponseModel.fromApiResponse(
        responseMap,
      );

      if (!refreshedTokens.hasValidTokens) {
        await _tokenStorage.clear();
        completer.complete(null);
        return null;
      }

      await _tokenStorage.saveTokens(
        accessToken: refreshedTokens.accessToken,
        refreshToken: refreshedTokens.refreshToken,
      );

      completer.complete(refreshedTokens.accessToken);
      return refreshedTokens.accessToken;
    } on DioException {
      await _tokenStorage.clear();
      completer.complete(null);
      return null;
    } catch (_) {
      await _tokenStorage.clear();
      completer.complete(null);
      return null;
    } finally {
      _refreshCompleter = null;
    }
  }

  Map<String, dynamic> _asJsonMap(dynamic body) {
    if (body == null) {
      return <String, dynamic>{};
    }

    if (body is Map<String, dynamic>) {
      return body;
    }

    if (body is String && body.trim().isNotEmpty) {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return <String, dynamic>{'data': decoded};
    }

    return <String, dynamic>{'data': body};
  }

  bool _isPublicAuthPath(String path) {
    return _matchesPath(path, AppConfig.loginPath) ||
        _matchesPath(path, AppConfig.refreshPath);
  }

  bool _matchesPath(String path, String endpointPath) {
    return path == endpointPath || path.endsWith(endpointPath);
  }
}
