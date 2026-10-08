import 'package:flutter/foundation.dart';
import '../core/api_client.dart';
import '../models/post.dart';

class PostProvider extends ChangeNotifier {
  final ApiClient _api;
  PostProvider(this._api);

  final Map<String, List<Post>> _byChannel = {};
  final Map<String, bool> _loading = {};
  String? _error;

  List<Post> postsOf(String channelId) => _byChannel[channelId] ?? const [];
  bool isLoading(String channelId) => _loading[channelId] ?? false;
  String? get error => _error;

  Future<void> load(String channelId, {bool refresh = false}) async {
    if (_loading[channelId] == true) return;
    _loading[channelId] = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.dio.get(
        '/api/channels/$channelId/posts',
        queryParameters: {'page': 0, 'size': 50},
      );
      final content = (res.data['content'] as List)
          .map((e) => Post.fromJson(e as Map<String, dynamic>))
          .toList();
      _byChannel[channelId] = content;
    } catch (e) {
      _error = ApiClient.extractError(e);
    } finally {
      _loading[channelId] = false;
      notifyListeners();
    }
  }

  Future<Post> create(String channelId, String content) async {
    final res = await _api.dio.post(
      '/api/channels/$channelId/posts',
      data: {'content': content},
    );
    final post = Post.fromJson(res.data as Map<String, dynamic>);
    _byChannel.putIfAbsent(channelId, () => []).insert(0, post);
    notifyListeners();
    return post;
  }

  /// Elimina una publicación. El backend valida los permisos.
  /// Quita el post de la lista local para reflejarlo inmediatamente en la UI.
  Future<void> delete(String channelId, String postId) async {
    await _api.dio.delete('/api/posts/$postId');
    final list = _byChannel[channelId];
    if (list != null) {
      list.removeWhere((p) => p.id == postId);
      notifyListeners();
    }
  }
}