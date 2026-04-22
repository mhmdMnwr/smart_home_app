// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_tokens_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthTokensResponseModel _$AuthTokensResponseModelFromJson(
  Map<String, dynamic> json,
) => AuthTokensResponseModel(
  accessToken: json['accessToken'] as String? ?? '',
  refreshToken: json['refreshToken'] as String? ?? '',
  user: json['user'] == null
      ? null
      : UserModel.fromJson(json['user'] as Map<String, dynamic>),
);

Map<String, dynamic> _$AuthTokensResponseModelToJson(
  AuthTokensResponseModel instance,
) => <String, dynamic>{
  'accessToken': instance.accessToken,
  'refreshToken': instance.refreshToken,
  'user': instance.user?.toJson(),
};
