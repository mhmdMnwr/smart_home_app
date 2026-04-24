import '../../../auth/data/models/user_model.dart';

class CreateUserRequestModel {
  const CreateUserRequestModel({
    required this.name,
    required this.email,
    required this.password,
    this.phoneNumber,
    this.role,
  });

  final String name;
  final String email;
  final String password;
  final String? phoneNumber;
  final UserRole? role;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'email': email,
      'password': password,
      if (phoneNumber != null && phoneNumber!.trim().isNotEmpty)
        'phoneNumber': phoneNumber!.trim(),
      if (role != null) 'role': role!.name,
    };
  }
}
