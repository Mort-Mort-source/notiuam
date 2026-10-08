import 'package:flutter/foundation.dart';
import '../core/api_client.dart';
import '../models/channel.dart';

class ChannelProvider extends ChangeNotifier {
  final ApiClient _api;

  ChannelProvider(this._api);

  List<Channel> _publicChannels = [];
  List<Channel> _mine = [];
  List<Channel> _subscribed = [];
  bool _loading = false;
  String? _error;

  List<Channel> get publicChannels => _publicChannels;
  List<Channel> get mine => _mine;
  List<Channel> get subscribed => _subscribed;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadPublic({String? query}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.dio.get('/api/channels',
          queryParameters: query != null && query.isNotEmpty ? {'q': query} : null);
      _publicChannels = (res.data as List)
          .map((e) => Channel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = ApiClient.extractError(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMine() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.dio.get('/api/channels/mine');
      _mine = (res.data as List)
          .map((e) => Channel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = ApiClient.extractError(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadSubscribed() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.dio.get('/api/channels/subscribed');
      _subscribed = (res.data as List)
          .map((e) => Channel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = ApiClient.extractError(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Channel> getById(String id) async {
    final res = await _api.dio.get('/api/channels/$id');
    return Channel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Channel> create({
    required String name,
    String? description,
    required String category,
  }) async {
    final res = await _api.dio.post('/api/channels', data: {
      'name': name,
      'description': description,
      'category': category,
      'publicChannel': true,
    });
    final created = Channel.fromJson(res.data as Map<String, dynamic>);
    // Refresca la lista de "mine" para que aparezca el nuevo canal.
    await loadMine();
    return created;
  }

  Future<void> toggleSubscription(Channel channel) async {
    if (channel.subscribedByMe) {
      await _api.dio.delete('/api/channels/${channel.id}/subscribe');
    } else {
      await _api.dio.post('/api/channels/${channel.id}/subscribe');
    }
    // Recarga las listas afectadas.
    await loadPublic();
    await loadSubscribed();
  }
}