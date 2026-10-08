import 'user.dart';

class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final User user;

  AuthResponse({required this.accessToken, required this.refreshToken, required this.user});

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        user: User.fromJson(json['user'] as Map<String, dynamic>),
      );
}