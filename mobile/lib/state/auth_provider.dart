import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/api_client.dart';
import '../core/fcm_service.dart';
import '../core/token_storage.dart';
import '../models/auth_response.dart';
import '../models/user.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final ApiClient _api;
  final TokenStorage _storage;
  final FcmService _fcm;

  AuthStatus _status = AuthStatus.unknown;
  User? _user;

  AuthProvider(this._api, this._storage, this._fcm);

  AuthStatus get status => _status;
  User? get user => _user;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isSuperAdmin => _user?.isSuperAdmin ?? false;
  bool get isAdminOrSuper => _user?.isAdminOrSuper ?? false;

  Future<void> bootstrap() async {
    final token = await _storage.getAccess();
    if (token == null) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    final decoded = _decodeJwt(token);
    if (decoded == null) {
      await _storage.clear();
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    _user = User(
      id: decoded['sub'] as String? ?? '',
      email: decoded['email'] as String? ?? '',
      displayName: (decoded['displayName'] ?? decoded['email'] ?? 'Usuario') as String,
      role: decoded['role'] as String? ?? 'STUDENT',
    );
    _status = AuthStatus.authenticated;
    notifyListeners();

    await _fcm.initialize();
  }

  Future<void> login(String email, String password) async {
    final res = await _api.dio.post('/api/auth/login', data: {
      'email': email,
      'password': password,
    });
    await _handleAuthResponse(res.data);
  }

  Future<void> register(String email, String password, String displayName) async {
    final res = await _api.dio.post('/api/auth/register', data: {
      'email': email,
      'password': password,
      'displayName': displayName,
      'role': 'STUDENT',
    });
    await _handleAuthResponse(res.data);
  }

  Future<void> logout() async {
    await _fcm.unregister();
    await _storage.clear();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> _handleAuthResponse(dynamic data) async {
    final auth = AuthResponse.fromJson(data as Map<String, dynamic>);
    await _storage.save(access: auth.accessToken, refresh: auth.refreshToken);
    _user = auth.user;
    _status = AuthStatus.authenticated;
    notifyListeners();

    await _fcm.initialize();
  }

  Map<String, dynamic>? _decodeJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final normalized = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(normalized));
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}