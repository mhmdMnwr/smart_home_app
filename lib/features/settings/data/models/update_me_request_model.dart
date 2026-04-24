class UpdateMeRequestModel {
  const UpdateMeRequestModel({
    required this.name,
    required this.email,
    this.password,
  });

  final String name;
  final String email;
  final String? password;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'email': email,
      if (password != null && password!.trim().isNotEmpty)
        'password': password!.trim(),
    };
  }
}
