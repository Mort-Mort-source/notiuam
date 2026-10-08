class AdminUser {
  final String id;
  final String email;
  final String displayName;
  final String role;
  final bool enabled;
  final DateTime createdAt;

  AdminUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    required this.enabled,
    required this.createdAt,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(
        id: json['id'] as String,
        email: json['email'] as String,
        displayName: json['displayName'] as String,
        role: json['role'] as String,
        enabled: json['enabled'] as bool? ?? true,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  String get roleLabel {
    switch (role) {
      case 'STUDENT':
        return 'Estudiante';
      case 'PROFESSOR':
        return 'Profesor';
      case 'ADMIN':
        return 'Administrador';
      case 'SUPERADMIN':
        return 'Superadministrador';
      default:
        return role;
    }
  }
}