class User {
  final String id;
  final String email;
  final String displayName;
  final String role;

  User({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        email: json['email'] as String,
        displayName: json['displayName'] as String,
        role: json['role'] as String,
      );

  bool get isStudent => role == 'STUDENT';
  bool get isProfessor => role == 'PROFESSOR';
  bool get isAdmin => role == 'ADMIN';
  bool get isSuperAdmin => role == 'SUPERADMIN';
  bool get isAdminOrSuper => isAdmin || isSuperAdmin;

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