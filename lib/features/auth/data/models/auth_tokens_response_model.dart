import 'package:json_annotation/json_annotation.dart';

import 'user_model.dart';

part 'auth_tokens_response_model.g.dart';

@JsonSerializable(explicitToJson: true)
class AuthTokensResponseModel {
  const AuthTokensResponseModel({
    required this.accessToken,
    required this.refreshToken,
    this.user,
  });

  @JsonKey(defaultValue: '')
  final String accessToken;

  @JsonKey(defaultValue: '')
  final String refreshToken;

  final UserModel? user;

  bool get hasValidTokens => accessToken.isNotEmpty && refreshToken.isNotEmpty;

  factory AuthTokensResponseModel.fromJson(Map<String, dynamic> json) =>
      _$AuthTokensResponseModelFromJson(json);

  factory AuthTokensResponseModel.fromApiResponse(Map<String, dynamic> json) {
    final payload = _extractPayload(json);
    final tokensPayload = _extractTokensPayload(payload);

    final accessToken =
      _readAsString(tokensPayload['accessToken']) ??
      _readAsString(tokensPayload['access_token']) ??
        _readAsString(payload['accessToken']) ??
        _readAsString(payload['access_token']) ??
        _readAsString(json['accessToken']) ??
        _readAsString(json['access_token']) ??
        '';

    final refreshToken =
      _readAsString(tokensPayload['refreshToken']) ??
      _readAsString(tokensPayload['refresh_token']) ??
        _readAsString(payload['refreshToken']) ??
        _readAsString(payload['refresh_token']) ??
        _readAsString(json['refreshToken']) ??
        _readAsString(json['refresh_token']) ??
        '';

    final dynamic userCandidate = payload['user'] ?? json['user'];

    Map<String, dynamic>? userJson;
    if (userCandidate is Map<String, dynamic>) {
      userJson = userCandidate;
    } else if (_looksLikeUser(payload)) {
      userJson = payload;
    }

    return AuthTokensResponseModel(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: userJson == null ? null : UserModel.fromJson(userJson),
    );
  }

  Map<String, dynamic> toJson() => _$AuthTokensResponseModelToJson(this);

  static Map<String, dynamic> _extractPayload(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }

    final result = json['result'];
    if (result is Map<String, dynamic>) {
      return result;
    }

    return json;
  }

  static Map<String, dynamic> _extractTokensPayload(
    Map<String, dynamic> payload,
  ) {
    final tokens = payload['tokens'];
    if (tokens is Map<String, dynamic>) {
      return tokens;
    }

    return payload;
  }

  static String? _readAsString(dynamic value) {
    if (value == null) {
      return null;
    }

    final stringValue = value.toString();
    if (stringValue.trim().isEmpty) {
      return null;
    }

    return stringValue;
  }

  static bool _looksLikeUser(Map<String, dynamic> map) {
    return map.containsKey('name') ||
        map.containsKey('email') ||
        map.containsKey('phoneNumber') ||
        map.containsKey('role');
  }
}
