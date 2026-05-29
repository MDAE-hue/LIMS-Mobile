class UserModel {
  final int id;
  final String name;
  final String? email;
  final List<String> roles;

  const UserModel({
    required this.id,
    required this.name,
    this.email,
    this.roles = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final rawRoles = json['roles'];
    final roles = rawRoles is List
        ? rawRoles.map((role) => role is String ? role : role['name']?.toString() ?? '').where((role) => role.isNotEmpty).toList()
        : <String>[];

    return UserModel(
      id: json['id'] as int,
      name: json['name']?.toString() ?? '-',
      email: json['email']?.toString(),
      roles: roles,
    );
  }
}
