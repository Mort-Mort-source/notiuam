import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/audit_log.dart';
import '../state/admin_provider.dart';

class AdminAuditTab extends StatefulWidget {
  final bool isSuperAdmin;
  const AdminAuditTab({super.key, required this.isSuperAdmin});

  @override
  State<AdminAuditTab> createState() => _AdminAuditTabState();
}

class _AdminAuditTabState extends State<AdminAuditTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadAudit();
    });
  }

  Future<void> _reload() async {
    await context.read<AdminProvider>().loadAudit();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: NotiuamColors.orange.withValues(alpha: 0.08),
          child: Row(
            children: [
              Icon(
                widget.isSuperAdmin ? Icons.visibility : Icons.person_outline,
                color: NotiuamColors.orangeDark,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.isSuperAdmin
                      ? 'Viendo el log completo del sistema'
                      : 'Viendo solo tus acciones',
                  style: const TextStyle(
                      fontSize: 13,
                      color: NotiuamColors.orangeDark,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        if (provider.loadingAudit) const LinearProgressIndicator(),
        if (provider.auditError != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(provider.auditError!,
                style: const TextStyle(color: NotiuamColors.danger)),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _reload,
            child: provider.audit.isEmpty && !provider.loadingAudit
                ? ListView(
                    children: const [
                      SizedBox(height: 80),
                      Center(child: Text('Sin registros de auditoría')),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: provider.audit.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (_, i) => _AuditCard(log: provider.audit[i]),
                  ),
          ),
        ),
      ],
    );
  }
}

class _AuditCard extends StatelessWidget {
  final AuditLog log;
  const _AuditCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d MMM · HH:mm', 'es');
    final info = _actionInfo(log.action);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: info.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(info.icon, size: 20, color: info.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          info.label,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                      ),
                      Text(fmt.format(log.createdAt.toLocal()),
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade600)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('por ${log.adminDisplayName}',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                  if (log.details != null && log.details!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(log.details!,
                        style: const TextStyle(fontSize: 13)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _ActionInfo _actionInfo(String action) {
    switch (action) {
      case 'VOTE_KEEP':
        return const _ActionInfo(
            'Votó: conservar', Icons.thumb_up_outlined, NotiuamColors.success);
      case 'VOTE_DELETE':
        return const _ActionInfo(
            'Votó: eliminar', Icons.thumb_down_outlined, NotiuamColors.danger);
      case 'CHANGE_ROLE':
        return const _ActionInfo(
            'Cambió un rol', Icons.manage_accounts_outlined, NotiuamColors.info);
      case 'BAN_USER':
        return const _ActionInfo(
            'Baneó a un usuario', Icons.block, NotiuamColors.danger);
      case 'UNBAN_USER':
        return const _ActionInfo(
            'Reactivó a un usuario', Icons.lock_open_outlined, NotiuamColors.success);
      case 'DELETE_POST':
        return const _ActionInfo(
            'Eliminó una publicación', Icons.delete_outline, NotiuamColors.danger);
      default:
        return _ActionInfo(action, Icons.history, Colors.grey);
    }
  }
}

class _ActionInfo {
  final String label;
  final IconData icon;
  final Color color;
  const _ActionInfo(this.label, this.icon, this.color);
}