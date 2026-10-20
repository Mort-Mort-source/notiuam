import 'package:flutter/foundation.dart';
import '../core/api_client.dart';

class VerificationProvider extends ChangeNotifier {
  final ApiClient _api;
  VerificationProvider(this._api);

  bool _sending = false;
  bool _verifying = false;
  String? _error;

  bool get sending => _sending;
  bool get verifying => _verifying;
  String? get error => _error;

  Future<bool> sendCode(String email) async {
    _sending = true;
    _error = null;
    notifyListeners();
    try {
      await _api.dio.post('/api/auth/send-verification', data: {'email': email});
      return true;
    } catch (e) {
      _error = ApiClient.extractError(e);
      return false;
    } finally {
      _sending = false;
      notifyListeners();
    }
  }

  Future<bool> verifyCode(String email, String code) async {
    _verifying = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.dio.post('/api/auth/verify-email',
          data: {'email': email, 'code': code});
      return res.data['verified'] == true;
    } catch (e) {
      _error = ApiClient.extractError(e);
      return false;
    } finally {
      _verifying = false;
      notifyListeners();
    }
  }
}