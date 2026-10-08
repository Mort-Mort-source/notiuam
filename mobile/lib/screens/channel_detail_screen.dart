import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../core/theme.dart';
import '../models/channel.dart';
import '../models/post.dart';
import '../state/auth_provider.dart';
import '../state/channel_provider.dart';
import '../state/post_provider.dart';
import '../state/unread_provider.dart';
import '../widgets/channel_owner_badge.dart';
import '../widgets/report_dialog.dart';

class ChannelDetailScreen extends StatefulWidget {
  final String channelId;
  const ChannelDetailScreen({super.key, required this.channelId});

  @override
  State<ChannelDetailScreen> createState() => _ChannelDetailScreenState();
}

class _ChannelDetailScreenState extends State<ChannelDetailScreen> {
  Channel? _channel;
  bool _loading = true;
  String? _error;
  bool _toggling = false;
  final _postCtrl = TextEditingController();
  bool _posting = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _postCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ch = await context.read<ChannelProvider>().getById(widget.channelId);
      setState(() => _channel = ch);
      await context.read<PostProvider>().load(widget.channelId, refresh: true);
      await context.read<UnreadProvider>().markRead(widget.channelId);
    } catch (e) {
      setState(() => _error = ApiClient.extractError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleSubscription() async {
    if (_channel == null || _toggling) return;
    setState(() => _toggling = true);
    try {
      await context.read<ChannelProvider>().toggleSubscription(_channel!);
      await _loadAll();
    } catch (e) {
      _showSnack(ApiClient.extractError(e), isError: true);
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  Future<void> _publish() async {
    final content = _postCtrl.text.trim();
    if (content.isEmpty || _posting) return;
    setState(() => _posting = true);
    try {
      await context.read<PostProvider>().create(widget.channelId, content);
      _postCtrl.clear();
      if (mounted) FocusScope.of(context).unfocus();
    } catch (e) {
      _showSnack(ApiClient.extractError(e), isError: true);
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  Future<void> _deletePost(Post post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar publicación'),
        content: const Text(
            '¿Estás seguro de que quieres eliminar esta publicación? '
            'Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: NotiuamColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await context.read<PostProvider>().delete(widget.channelId, post.id);
      _showSnack('Publicación eliminada', isError: false);
    } catch (e) {
      _showSnack(ApiClient.extractError(e), isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            isError ? NotiuamColors.danger : NotiuamColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthProvider>().user;
    final isOwner = _channel != null && me != null && _channel!.ownerId == me.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(_channel?.name ?? 'Canal'),
        actions: [
          if (_channel != null && !isOwner)
            IconButton(
              tooltip: 'Reportar canal',
              icon: const Icon(Icons.flag_outlined),
              onPressed: () => ReportDialog.show(
                context,
                targetType: 'CHANNEL',
                targetId: _channel!.id,
                targetLabel: 'Canal: ${_channel!.name}',
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!,
                        style: const TextStyle(color: NotiuamColors.danger)),
                  ),
                )
              : _buildBody(_channel!, me),
    );
  }

  Widget _buildBody(Channel ch, dynamic me) {
    final posts = context.watch<PostProvider>().postsOf(widget.channelId);
    final loadingPosts = context.watch<PostProvider>().isLoading(widget.channelId);

    // ¿Puedo moderar cualquier post? Sí, si soy dueño del canal o admin/superadmin
    final canModerateAny = me != null &&
        (ch.ownerId == me.id || me.isAdminOrSuper);

    return Column(
      children: [
        // ----- Encabezado del canal -----
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(ch.name,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                  ),
                  Chip(label: Text(ch.category)),
                ],
              ),
              if (ch.ownerRole != 'STUDENT') ...[
                const SizedBox(height: 8),
                ChannelOwnerBadge(ownerRole: ch.ownerRole),
              ],
              const SizedBox(height: 8),
              if (ch.description != null && ch.description!.isNotEmpty)
                Text(ch.description!, style: const TextStyle(fontSize: 15)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(ch.ownerDisplayName,
                      style: TextStyle(
                          color: Colors.grey.shade700, fontSize: 13)),
                  const SizedBox(width: 12),
                  const Icon(Icons.people_outline, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('${ch.subscriberCount}',
                      style: TextStyle(
                          color: Colors.grey.shade700, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ch.subscribedByMe
                    ? OutlinedButton.icon(
                        onPressed: _toggling ? null : _toggleSubscription,
                        icon: const Icon(Icons.notifications_off_outlined),
                        label: const Text('Desuscribirse'),
                      )
                    : FilledButton.icon(
                        onPressed: _toggling ? null : _toggleSubscription,
                        icon: const Icon(Icons.notifications_active_outlined),
                        label: const Text('Suscribirse'),
                      ),
              ),
              const Divider(height: 32),
              const Text('Publicaciones',
                  style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
            ],
          ),
        ),

        // ----- Caja para publicar -----
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _postCtrl,
                  maxLines: 3,
                  minLines: 1,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    hintText: 'Escribe un aviso...',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _posting ? null : _publish,
                icon: _posting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ----- Lista de posts -----
        if (loadingPosts && posts.isEmpty)
          const Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator()),

        Expanded(
          child: posts.isEmpty && !loadingPosts
              ? const Center(child: Text('Aún no hay publicaciones'))
              : RefreshIndicator(
                  onRefresh: () => context
                      .read<PostProvider>()
                      .load(widget.channelId, refresh: true),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    itemCount: posts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _PostCard(
                      post: posts[i],
                      currentUserId: me?.id,
                      canModerateAny: canModerateAny,
                      onDelete: () => _deletePost(posts[i]),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _PostCard extends StatelessWidget {
  final Post post;
  final String? currentUserId;
  final bool canModerateAny;
  final VoidCallback onDelete;

  const _PostCard({
    required this.post,
    this.currentUserId,
    required this.canModerateAny,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d MMM yyyy · HH:mm', 'es');
    final isOwn = currentUserId != null && post.authorId == currentUserId;
    final canDelete = isOwn || canModerateAny;
    final canReport = !isOwn;
    final hasMenu = canReport || canDelete;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: NotiuamColors.orange.withValues(alpha: 0.2),
                  child: Text(
                    post.authorDisplayName.isNotEmpty
                        ? post.authorDisplayName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        fontSize: 12, color: NotiuamColors.orangeDark),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(post.authorDisplayName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (isOwn) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: NotiuamColors.info.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Tú',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: NotiuamColors.info,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ],
                  ),
                ),
                Text(fmt.format(post.createdAt.toLocal()),
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                if (hasMenu)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert,
                        size: 18, color: Colors.grey.shade600),
                    onSelected: (value) {
                      if (value == 'report') {
                        ReportDialog.show(
                          context,
                          targetType: 'POST',
                          targetId: post.id,
                          targetLabel:
                              'Publicación de ${post.authorDisplayName}: '
                              '"${post.content.length > 60 ? '${post.content.substring(0, 57)}...' : post.content}"',
                        );
                      } else if (value == 'delete') {
                        onDelete();
                      }
                    },
                    itemBuilder: (_) => [
                      if (canReport)
                        const PopupMenuItem(
                          value: 'report',
                          child: ListTile(
                            leading: Icon(Icons.flag_outlined, size: 20),
                            title: Text('Reportar'),
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                        ),
                      if (canDelete)
                        const PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(Icons.delete_outline,
                                size: 20, color: NotiuamColors.danger),
                            title: Text('Eliminar',
                                style: TextStyle(
                                    color: NotiuamColors.danger)),
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                        ),
                    ],
                  )
                else
                  const SizedBox(width: 32),
              ],
            ),
            const SizedBox(height: 8),
            Text(post.content, style: const TextStyle(fontSize: 15)),
          ],
        ),
      ),
    );
  }
}