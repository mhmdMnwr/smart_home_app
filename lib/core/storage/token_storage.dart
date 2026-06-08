import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  TokenStorage(this._preferences);

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _usernameKey = 'cached_username';

  final SharedPreferences _preferences;

  String? get accessToken => _preferences.getString(_accessTokenKey);
  String? get refreshToken => _preferences.getString(_refreshTokenKey);
  String? get cachedUsername => _preferences.getString(_usernameKey);

  bool get hasTokens {
    final access = accessToken;
    return access != null && access.isNotEmpty;
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait<void>([
      _preferences.setString(_accessTokenKey, accessToken),
      _preferences.setString(_refreshTokenKey, refreshToken),
    ]);
  }

  Future<void> saveUsername(String username) async {
    await _preferences.setString(_usernameKey, username);
  }

  Future<void> clear() async {
    await Future.wait<void>([
      _preferences.remove(_accessTokenKey),
      _preferences.remove(_refreshTokenKey),
      _preferences.remove(_usernameKey),
    ]);
  }
}
