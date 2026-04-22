import '../../../../core/config/app_config.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/api_client.dart';
import '../models/auth_tokens_response_model.dart';
import '../models/login_request_model.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthTokensResponseModel> login(LoginRequestModel request);
  Future<AuthTokensResponseModel> refreshToken(String refreshToken);

  /// Calls `GET /users/me` using `Authorization: Bearer <access_token>`
  /// and returns the authenticated user's profile data.
  Future<UserModel> getMe();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<AuthTokensResponseModel> login(LoginRequestModel request) async {
    final response = await _apiClient.post(
      path: AppConfig.loginPath,
      body: request.toJson(),
    );

    return AuthTokensResponseModel.fromApiResponse(response);
  }

  @override
  Future<AuthTokensResponseModel> refreshToken(String refreshToken) async {
    final response = await _apiClient.post(
      path: AppConfig.refreshPath,
      body: <String, dynamic>{'refreshToken': refreshToken},
    );

    return AuthTokensResponseModel.fromApiResponse(response);
  }

  @override
  Future<UserModel> getMe() async {
    final response = await _apiClient.get(path: AppConfig.mePath);
    final payload = response['data'];

    if (payload is Map<String, dynamic>) {
      final userPayload = payload['user'];
      if (userPayload is Map<String, dynamic>) {
        return UserModel.fromJson(userPayload);
      }

      return UserModel.fromJson(payload);
    }

    throw const AppException(message: 'Get me response has invalid user data.');
  }
}
