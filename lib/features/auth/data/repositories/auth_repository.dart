import '../../../../core/errors/app_exception.dart';
import '../../../../core/storage/token_storage.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/login_request_model.dart';
import '../models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel> login({required String email, required String password});
  Future<void> refreshSession();
  Future<void> logout();

  String? get accessToken;
  String? get refreshToken;
}

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required TokenStorage tokenStorage,
  }) : _remoteDataSource = remoteDataSource,
       _tokenStorage = tokenStorage;

  final AuthRemoteDataSource _remoteDataSource;
  final TokenStorage _tokenStorage;

  UserModel? _cachedUser;

  UserModel? get cachedUser => _cachedUser;

  @override
  String? get accessToken => _tokenStorage.accessToken;

  @override
  String? get refreshToken => _tokenStorage.refreshToken;

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _remoteDataSource.login(
      LoginRequestModel(email: email, password: password),
    );

    if (!response.hasValidTokens) {
      throw const AppException(
        message: 'Login response is missing access or refresh token.',
      );
    }

    await _tokenStorage.saveTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
    );

    final user = await _remoteDataSource.getMe();
    if (!user.isValid) {
      throw const AppException(
        message: 'Get me response is missing user profile fields.',
      );
    }

    _cachedUser = user;
    return user;
  }

  @override
  Future<void> refreshSession() async {
    final currentRefreshToken = refreshToken;
    if (currentRefreshToken == null || currentRefreshToken.isEmpty) {
      throw const AppException(
        message: 'No refresh token found. Login is required.',
      );
    }

    final response = await _remoteDataSource.refreshToken(currentRefreshToken);
    if (!response.hasValidTokens) {
      throw const AppException(message: 'Refresh response is missing tokens.');
    }

    await _tokenStorage.saveTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
    );

    _cachedUser = await _remoteDataSource.getMe();
  }

  @override
  Future<void> logout() async {
    _cachedUser = null;
    await _tokenStorage.clear();
  }
}
