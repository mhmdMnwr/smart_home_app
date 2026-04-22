import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

enum UserRole { admin, user }

@JsonSerializable()
class UserModel {
  const UserModel({
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.role,
  });

  @JsonKey(defaultValue: '')
  final String name;

  @JsonKey(defaultValue: '')
  final String email;

  @JsonKey(defaultValue: '')
  final String phoneNumber;

  @JsonKey(fromJson: _roleFromJson, toJson: _roleToJson)
  final UserRole role;

  bool get isValid => name.isNotEmpty && email.isNotEmpty;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final normalizedJson = <String, dynamic>{
      ...json,
      'phoneNumber': json['phoneNumber'] ?? json['phone_number'] ?? '',
    };

    return _$UserModelFromJson(normalizedJson);
  }

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  static UserRole _roleFromJson(dynamic value) {
    switch (value?.toString().toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'user':
      default:
        return UserRole.user;
    }
  }

  static String _roleToJson(UserRole role) => role.name;
}
