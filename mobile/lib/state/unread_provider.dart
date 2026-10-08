import 'package:flutter/foundation.dart';
import '../core/api_client.dart';

class UnreadProvider extends ChangeNotifier {
  final ApiClient _api;
  UnreadProvider(this._api);

  Map<String, int> _counts = {};
  Map<String, int> get counts => _counts;

  int get total => _counts.values.fold(0, (a, b) => a + b);
  int countFor(String channelId) => _counts[channelId] ?? 0;

  Future<void> refresh() async {
    try {
      final res = await _api.dio.get('/api/me/unread');
      final raw = res.data as Map<String, dynamic>;
      _counts = raw.map((k, v) => MapEntry(k, (v as num).toInt()));
      notifyListeners();
    } catch (e) {
      // Silencioso: si falla, el usuario ve el contador viejo.
    }
  }

  Future<void> markRead(String channelId) async {
    if (!_counts.containsKey(channelId)) return;
    try {
      await _api.dio.delete('/api/me/unread/$channelId');
      _counts.remove(channelId);
      notifyListeners();
    } catch (_) {
      // Nada crítico.
    }
  }

  void clear() {
    _counts = {};
    notifyListeners();
  }
}