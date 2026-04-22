import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  TokenStorage(this._preferences);

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  final SharedPreferences _preferences;

  String? get accessToken => _preferences.getString(_accessTokenKey);
  String? get refreshToken => _preferences.getString(_refreshTokenKey);

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait<void>([
      _preferences.setString(_accessTokenKey, accessToken),
      _preferences.setString(_refreshTokenKey, refreshToken),
    ]);
  }

  Future<void> clear() async {
    await Future.wait<void>([
      _preferences.remove(_accessTokenKey),
      _preferences.remove(_refreshTokenKey),
    ]);
  }
}
