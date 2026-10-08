import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../core/theme.dart';
import '../models/report.dart';
import '../state/admin_provider.dart';
import '../state/auth_provider.dart';

class ReportDetailScreen extends StatefulWidget {
  final String reportId;
  const ReportDetailScreen({super.key, required this.reportId});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  Report? _report;
  bool _loading = true;
  String? _error;
  bool _voting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await context.read<AdminProvider>().getReport(widget.reportId);
      setState(() => _report = r);
    } catch (e) {
      setState(() => _error = ApiClient.extractError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _vote(String decision) async {
    if (_report == null || _voting) return;
    // Pedir comentario opcional
    final comment = await _promptComment(decision);
    if (comment == null) return; // cancelado

    setState(() => _voting = true);
    try {
      await context.read<AdminProvider>().vote(
            widget.reportId,
            decision,
            comment: comment,
          );
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(decision == 'KEEP'
                ? 'Voto registrado: conservar'
                : 'Voto registrado: eliminar'),
            backgroundColor: decision == 'KEEP'
                ? NotiuamColors.success
                : NotiuamColors.danger,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiClient.extractError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _voting = false);
    }
  }

  Future<String?> _promptComment(String decision) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(decision == 'KEEP'
            ? 'Votar: conservar contenido'
            : 'Votar: eliminar contenido'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          maxLength: 500,
          decoration: const InputDecoration(
            labelText: 'Comentario (opcional)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(ctrl.text.trim()),
            child: const Text('Confirmar voto'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del reporte')),
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
              : _buildBody(_report!, me),
    );
  }

  Widget _buildBody(Report r, dynamic me) {
    final fmt = DateFormat('d MMM yyyy · HH:mm', 'es');
    final canVote = r.status == 'PENDING' && !r.votedByMe;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ----- Estado + tipo -----
          Row(
            children: [
              _chip(r.targetType == 'POST' ? 'Publicación' : 'Canal',
                  NotiuamColors.info),
              const SizedBox(width: 8),
              _chip(_reasonLabel(r.reason), Colors.grey.shade600),
              const Spacer(),
              _statusChip(r.status, r.statusLabel),
            ],
          ),
          const SizedBox(height: 16),

          // ----- Contenido reportado -----
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Contenido reportado',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(r.targetPreview,
                      style: const TextStyle(fontSize: 15)),
                  if (r.targetDetails != null && r.targetDetails!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(r.targetDetails!,
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade700)),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ----- Info del reporte -----
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Motivo del reporte',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(r.reasonLabel),
                  if (r.details != null && r.details!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(r.details!,
                        style: TextStyle(color: Colors.grey.shade700)),
                  ],
                  const Divider(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 16),
                      const SizedBox(width: 6),
                      Text('Reportado por ${r.reporterDisplayName}',
                          style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 16),
                      const SizedBox(width: 6),
                      Text(fmt.format(r.createdAt.toLocal()),
                          style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ----- Contador de votos -----
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Votación',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Text('${r.voteCount} / 3',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: (r.voteCount / 3).clamp(0.0, 1.0),
                    backgroundColor: Colors.grey.shade200,
                    color: NotiuamColors.orange,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _voteStat(
                          Icons.thumb_up_outlined,
                          'Conservar',
                          r.keepVotes,
                          NotiuamColors.success,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _voteStat(
                          Icons.thumb_down_outlined,
                          'Eliminar',
                          r.deleteVotes,
                          NotiuamColors.danger,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ----- Botones de voto -----
          if (canVote) ...[
            const SizedBox(height: 20),
            const Text('Emitir voto',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _voting ? null : () => _vote('KEEP'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: NotiuamColors.success,
                      side: const BorderSide(
                          color: NotiuamColors.success, width: 1.4),
                    ),
                    icon: const Icon(Icons.thumb_up_outlined),
                    label: const Text('Conservar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _voting ? null : () => _vote('DELETE'),
                    style: FilledButton.styleFrom(
                      backgroundColor: NotiuamColors.danger,
                    ),
                    icon: const Icon(Icons.thumb_down_outlined),
                    label: const Text('Eliminar'),
                  ),
                ),
              ],
            ),
          ] else if (r.votedByMe) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: NotiuamColors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.how_to_vote, color: NotiuamColors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ya emitiste tu voto: ${r.myVote == "KEEP" ? "conservar" : "eliminar"}',
                      style: const TextStyle(
                          color: NotiuamColors.orangeDark,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (r.status != 'PENDING') ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Este reporte ya fue resuelto',
                      style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _statusChip(String status, String label) {
    Color color;
    switch (status) {
      case 'PENDING':
        color = NotiuamColors.orange;
        break;
      case 'RESOLVED_KEEP':
        color = NotiuamColors.success;
        break;
      case 'RESOLVED_DELETE':
        color = NotiuamColors.danger;
        break;
      default:
        color = Colors.grey;
    }
    return _chip(label, color);
  }

  Widget _voteStat(IconData icon, String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text('$count',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          Text(label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  String _reasonLabel(String reason) {
    switch (reason) {
      case 'SPAM':
        return 'Spam';
      case 'INAPPROPRIATE':
        return 'Contenido inapropiado';
      case 'MISINFORMATION':
        return 'Desinformación';
      case 'HARASSMENT':
        return 'Acoso';
      case 'OTHER':
        return 'Otro';
      default:
        return reason;
    }
  }
}