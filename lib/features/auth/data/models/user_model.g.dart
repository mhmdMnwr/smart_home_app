// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  name: json['name'] as String? ?? '',
  email: json['email'] as String? ?? '',
  phoneNumber: json['phoneNumber'] as String? ?? '',
  role: UserModel._roleFromJson(json['role']),
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'name': instance.name,
  'email': instance.email,
  'phoneNumber': instance.phoneNumber,
  'role': UserModel._roleToJson(instance.role),
};
