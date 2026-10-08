import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../state/channel_provider.dart';
import '../widgets/channel_owner_badge.dart';
import 'channel_detail_screen.dart';
import 'create_channel_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChannelProvider>().loadPublic();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChannelProvider>();

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar canales...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchCtrl.clear();
                    context.read<ChannelProvider>().loadPublic();
                  },
                ),
              ),
              onSubmitted: (value) {
                context.read<ChannelProvider>().loadPublic(query: value.trim());
              },
            ),
          ),
          if (provider.loading) const LinearProgressIndicator(),
          if (provider.error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(provider.error!,
                  style: const TextStyle(color: NotiuamColors.danger)),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => context.read<ChannelProvider>().loadPublic(
                    query: _searchCtrl.text.trim(),
                  ),
              child: provider.publicChannels.isEmpty && !provider.loading
                  ? ListView(
                      children: const [
                        SizedBox(height: 80),
                        Center(child: Text('No hay canales públicos')),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      itemCount: provider.publicChannels.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final ch = provider.publicChannels[i];
                        return Card(
                          child: ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: _categoryIcon(ch.category),
                            title: Row(
                              children: [
                                Flexible(
                                  child: Text(ch.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600),
                                      overflow: TextOverflow.ellipsis),
                                ),
                                if (ch.ownerRole != 'STUDENT') ...[
                                  const SizedBox(width: 8),
                                  ChannelOwnerBadge(
                                      ownerRole: ch.ownerRole, compact: true),
                                ],
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (ch.description != null &&
                                    ch.description!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(ch.description!,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    '${ch.subscriberCount} suscriptores · ${ch.ownerDisplayName}',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600),
                                  ),
                                ),
                              ],
                            ),
                            trailing: ch.subscribedByMe
                                ? const Icon(Icons.check_circle,
                                    color: NotiuamColors.success)
                                : null,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ChannelDetailScreen(channelId: ch.id),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateChannelScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Crear canal'),
      ),
    );
  }

  Widget _categoryIcon(String category) {
    IconData icon;
    Color color;
    switch (category) {
      case 'ACADEMIC':
        icon = Icons.school_outlined;
        color = NotiuamColors.info;
        break;
      case 'CULTURAL':
        icon = Icons.theater_comedy_outlined;
        color = const Color(0xFF9C27B0);
        break;
      case 'SPORTS':
        icon = Icons.sports_soccer_outlined;
        color = NotiuamColors.success;
        break;
      case 'ADMINISTRATIVE':
        icon = Icons.business_center_outlined;
        color = NotiuamColors.orangeDark;
        break;
      case 'SOCIAL':
        icon = Icons.groups_outlined;
        color = const Color(0xFFD81B60);
        break;
      default:
        icon = Icons.forum_outlined;
        color = NotiuamColors.charcoal;
    }
    return CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.15),
      child: Icon(icon, color: color),
    );
  }
}