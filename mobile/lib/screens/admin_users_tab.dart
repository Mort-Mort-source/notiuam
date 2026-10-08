import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../core/theme.dart';
import '../models/admin_user.dart';
import '../state/admin_provider.dart';
import '../state/auth_provider.dart';

class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key});

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadUsers();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    await context.read<AdminProvider>().loadUsers(query: _searchCtrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final me = context.watch<AuthProvider>().user;
    final isSuper = me?.isSuperAdmin ?? false;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Buscar por correo...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchCtrl.clear();
                  context.read<AdminProvider>().loadUsers();
                },
              ),
            ),
            onSubmitted: (v) => context.read<AdminProvider>().loadUsers(query: v.trim()),
          ),
        ),
        if (provider.loadingUsers) const LinearProgressIndicator(),
        if (provider.usersError != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(provider.usersError!,
                style: const TextStyle(color: NotiuamColors.danger)),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _reload,
            child: provider.users.isEmpty && !provider.loadingUsers
                ? ListView(
                    children: const [
                      SizedBox(height: 80),
                      Center(child: Text('Sin usuarios')),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: provider.users.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final u = provider.users[i];
                      final isMe = me?.id == u.id;
                      return _UserCard(
                        user: u,
                        isMe: isMe,
                        isSuperAdmin: isSuper,
                        onManage: () => _showUserActions(u, isSuper),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _showUserActions(AdminUser user, bool isSuper) async {
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => _UserActionsSheet(
        user: user,
        isSuperAdmin: isSuper,
      ),
    );
    if (mounted) await _reload();
  }
}

class _UserCard extends StatelessWidget {
  final AdminUser user;
  final bool isMe;
  final bool isSuperAdmin;
  final VoidCallback onManage;

  const _UserCard({
    required this.user,
    required this.isMe,
    required this.isSuperAdmin,
    required this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: _roleColor().withValues(alpha: 0.15),
          child: Text(
            user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
            style: TextStyle(color: _roleColor(), fontWeight: FontWeight.bold),
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(user.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis),
            ),
            if (isMe) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(user.email, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 4),
            Row(
              children: [
                _roleBadge(user.role),
                const SizedBox(width: 6),
                if (!user.enabled) _statusBadge('BANEADO', NotiuamColors.danger),
              ],
            ),
          ],
        ),
        trailing: !isMe
            ? IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: onManage,
              )
            : null,
      ),
    );
  }

  Color _roleColor() {
    switch (user.role) {
      case 'SUPERADMIN':
        return NotiuamColors.danger;
      case 'ADMIN':
        return NotiuamColors.orange;
      case 'PROFESSOR':
        return NotiuamColors.info;
      default:
        return Colors.grey;
    }
  }

  Widget _roleBadge(String role) {
    final color = _roleColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(userRoleLabel(role),
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _statusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

String userRoleLabel(String role) {
  switch (role) {
    case 'STUDENT':
      return 'Estudiante';
    case 'PROFESSOR':
      return 'Profesor';
    case 'ADMIN':
      return 'Administrador';
    case 'SUPERADMIN':
      return 'Superadmin';
    default:
      return role;
  }
}

// ---------- Bottom sheet de acciones ----------

class _UserActionsSheet extends StatelessWidget {
  final AdminUser user;
  final bool isSuperAdmin;

  const _UserActionsSheet({required this.user, required this.isSuperAdmin});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.displayName,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                Text(user.email,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
          ),
          const Divider(height: 1),
          _buildChangeRoleSection(context),
          const Divider(height: 1),
          if (isSuperAdmin) _buildBanSection(context),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildChangeRoleSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Cambiar rol',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _roleAction(context, 'STUDENT', Icons.school_outlined),
              _roleAction(context, 'PROFESSOR', Icons.school_outlined),
              _roleAction(context, 'ADMIN', Icons.shield_outlined),
              _roleAction(context, 'SUPERADMIN', Icons.star_outline),
            ],
          ),
        ],
      ),
    );
  }

  Widget _roleAction(BuildContext context, String role, IconData icon) {
    final selected = user.role == role;
    return ActionChip(
      avatar: Icon(icon, size: 16),
      label: Text(userRoleLabel(role)),
      backgroundColor: selected
          ? NotiuamColors.orange.withValues(alpha: 0.15)
          : null,
      onPressed: selected ? null : () => _changeRole(context, role),
    );
  }

  Future<void> _changeRole(BuildContext context, String role) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar cambio de rol'),
        content: Text(
            '¿Cambiar a ${user.displayName} al rol "${userRoleLabel(role)}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await context.read<AdminProvider>().changeRole(user.id, role);
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rol actualizado a ${userRoleLabel(role)}'),
          backgroundColor: NotiuamColors.success,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiClient.extractError(e))),
      );
    }
  }

  Widget _buildBanSection(BuildContext context) {
    final banned = !user.enabled;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: banned
            ? FilledButton.icon(
                onPressed: () => _toggleStatus(context, true),
                style: FilledButton.styleFrom(
                    backgroundColor: NotiuamColors.success),
                icon: const Icon(Icons.lock_open_outlined),
                label: const Text('Reactivar usuario'),
              )
            : OutlinedButton.icon(
                onPressed: () => _toggleStatus(context, false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: NotiuamColors.danger,
                  side: const BorderSide(
                      color: NotiuamColors.danger, width: 1.4),
                ),
                icon: const Icon(Icons.block),
                label: const Text('Banear usuario'),
              ),
      ),
    );
  }

  Future<void> _toggleStatus(BuildContext context, bool enabled) async {
    final verb = enabled ? 'reactivar' : 'banear';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Confirmar ${verb}'),
        content: Text('¿${enabled ? "Reactivar" : "Banear"} a ${user.displayName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor:
                  enabled ? NotiuamColors.success : NotiuamColors.danger,
            ),
            child: Text(enabled ? 'Reactivar' : 'Banear'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await context.read<AdminProvider>().toggleUserStatus(user.id, enabled);
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(enabled ? 'Usuario reactivado' : 'Usuario baneado'),
          backgroundColor:
              enabled ? NotiuamColors.success : NotiuamColors.danger,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiClient.extractError(e))),
      );
    }
  }
}