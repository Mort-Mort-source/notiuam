import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/channel.dart';
import '../state/auth_provider.dart';
import '../state/channel_provider.dart';
import '../state/unread_provider.dart';
import '../widgets/channel_owner_badge.dart';
import 'admin_screen.dart';
import 'channel_detail_screen.dart';
import 'explore_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UnreadProvider>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final unread = context.watch<UnreadProvider>();
    final totalUnread = unread.total;
    final isAdmin = auth.isAdminOrSuper;

    final pages = [
      const ExploreScreen(),
      const _MineScreen(),
      const _SubscribedScreen(),
      if (isAdmin) const AdminScreen(),
      _ProfileScreen(user: auth.user),
    ];

    final destinations = [
      const NavigationDestination(
          icon: Icon(Icons.explore_outlined), label: 'Explorar'),
      const NavigationDestination(
          icon: Icon(Icons.folder_outlined), label: 'Mis canales'),
      NavigationDestination(
        icon: totalUnread > 0
            ? Badge(
                label: Text('$totalUnread'),
                child: const Icon(Icons.bookmark_outline),
              )
            : const Icon(Icons.bookmark_outline),
        label: 'Suscritos',
      ),
      if (isAdmin)
        const NavigationDestination(
            icon: Icon(Icons.shield_outlined), label: 'Admin'),
      const NavigationDestination(
          icon: Icon(Icons.person_outline), label: 'Perfil'),
    ];

    if (_index >= pages.length) _index = 0;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('NotiUAM'),
            if (auth.isSuperAdmin) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, size: 12, color: Colors.white),
                    SizedBox(width: 4),
                    Text('SUPER',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ],
                ),
              ),
            ] else if (auth.isAdmin) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('ADMIN',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<UnreadProvider>().clear();
              auth.logout();
            },
          ),
        ],
      ),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: destinations,
      ),
    );
  }
}

class _MineScreen extends StatefulWidget {
  const _MineScreen();
  @override
  State<_MineScreen> createState() => _MineScreenState();
}

class _MineScreenState extends State<_MineScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChannelProvider>().loadMine();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChannelProvider>();
    if (provider.loading) return const Center(child: CircularProgressIndicator());
    if (provider.mine.isEmpty) {
      return const Center(child: Text('Aún no has creado canales'));
    }
    return _ChannelList(channels: provider.mine);
  }
}

class _SubscribedScreen extends StatefulWidget {
  const _SubscribedScreen();
  @override
  State<_SubscribedScreen> createState() => _SubscribedScreenState();
}

class _SubscribedScreenState extends State<_SubscribedScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChannelProvider>().loadSubscribed();
      context.read<UnreadProvider>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChannelProvider>();
    final unread = context.watch<UnreadProvider>();
    if (provider.loading) return const Center(child: CircularProgressIndicator());
    if (provider.subscribed.isEmpty) {
      return const Center(child: Text('No estás suscrito a ningún canal'));
    }
    return RefreshIndicator(
      onRefresh: () async {
        await context.read<ChannelProvider>().loadSubscribed();
        await context.read<UnreadProvider>().refresh();
      },
      child: _ChannelList(channels: provider.subscribed, unread: unread),
    );
  }
}

class _ChannelList extends StatelessWidget {
  final List<Channel> channels;
  final UnreadProvider? unread;

  const _ChannelList({required this.channels, this.unread});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: channels.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (_, i) {
        final ch = channels[i];
        final count = unread?.countFor(ch.id) ?? 0;
        return ListTile(
          leading: const Icon(Icons.folder_outlined),
          title: Row(
            children: [
              Flexible(
                child: Text(ch.name, overflow: TextOverflow.ellipsis),
              ),
              if (ch.ownerRole != 'STUDENT') ...[
                const SizedBox(width: 6),
                ChannelOwnerBadge(ownerRole: ch.ownerRole, compact: true),
              ],
            ],
          ),
          subtitle: Text('${ch.subscriberCount} suscriptores'),
          trailing: count > 0
              ? Badge(label: Text('$count'))
              : const Icon(Icons.chevron_right),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChannelDetailScreen(channelId: ch.id),
              ),
            );
            if (context.mounted && unread != null) {
              await context.read<UnreadProvider>().refresh();
              await context.read<ChannelProvider>().loadSubscribed();
            }
          },
        );
      },
    );
  }
}

class _ProfileScreen extends StatelessWidget {
  final dynamic user;
  const _ProfileScreen({this.user});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: NotiuamColors.orange.withValues(alpha: 0.15),
            child: const Icon(Icons.person, size: 40, color: NotiuamColors.orangeDark),
          ),
          const SizedBox(height: 12),
          Text(user?.displayName ?? 'Usuario',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(user?.email ?? '',
              style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Chip(label: Text(user?.roleLabel ?? 'Rol desconocido')),
        ],
      ),
    );
  }
}