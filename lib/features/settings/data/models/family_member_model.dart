import '../../../auth/data/models/user_model.dart';

class FamilyMemberModel {
  const FamilyMemberModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.role,
  });

  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final UserRole role;

  factory FamilyMemberModel.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? json['_id'] ?? json['userId'] ?? '')
        .toString()
        .trim();
    final roleRaw = (json['role'] ?? 'user').toString().toLowerCase();

    return FamilyMemberModel(
      id: id.isEmpty ? (json['email'] ?? '').toString() : id,
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phoneNumber: (json['phoneNumber'] ?? json['phone_number'] ?? '').toString(),
      role: roleRaw == 'admin' ? UserRole.admin : UserRole.user,
    );
  }
}

