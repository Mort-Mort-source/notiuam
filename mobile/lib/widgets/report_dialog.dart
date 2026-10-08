import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../core/theme.dart';
import '../state/report_provider.dart';

class ReportDialog extends StatefulWidget {
  final String targetType;   // 'POST' | 'CHANNEL'
  final String targetId;
  final String targetLabel;  // texto para mostrar en el diálogo

  const ReportDialog({
    super.key,
    required this.targetType,
    required this.targetId,
    required this.targetLabel,
  });

  /// Helper para abrir el diálogo desde cualquier parte.
  static Future<void> show(
    BuildContext context, {
    required String targetType,
    required String targetId,
    required String targetLabel,
  }) {
    return showDialog(
      context: context,
      builder: (_) => ReportDialog(
        targetType: targetType,
        targetId: targetId,
        targetLabel: targetLabel,
      ),
    );
  }

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  String _reason = 'SPAM';
  final _detailsCtrl = TextEditingController();
  bool _sending = false;
  String? _error;

  static const _reasons = [
    ('SPAM', 'Spam'),
    ('INAPPROPRIATE', 'Contenido inapropiado'),
    ('MISINFORMATION', 'Desinformación'),
    ('HARASSMENT', 'Acoso'),
    ('OTHER', 'Otro'),
  ];

  @override
  void dispose() {
    _detailsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await context.read<ReportProvider>().createReport(
            targetType: widget.targetType,
            targetId: widget.targetId,
            reason: _reason,
            details: _detailsCtrl.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reporte enviado. Un administrador lo revisará.'),
          backgroundColor: NotiuamColors.success,
        ),
      );
    } catch (e) {
      setState(() => _error = ApiClient.extractError(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.flag_outlined, color: NotiuamColors.danger),
          SizedBox(width: 8),
          Text('Reportar contenido'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.targetLabel,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            const Text('Motivo del reporte:',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ..._reasons.map(
              (r) => RadioListTile<String>(
                value: r.$1,
                groupValue: _reason,
                onChanged: _sending ? null : (v) => setState(() => _reason = v!),
                title: Text(r.$2),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _detailsCtrl,
              maxLines: 3,
              maxLength: 500,
              enabled: !_sending,
              decoration: const InputDecoration(
                labelText: 'Detalles (opcional)',
                hintText: 'Cuéntanos qué problema ves con este contenido',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!,
                  style: const TextStyle(color: NotiuamColors.danger, fontSize: 13)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _sending ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _sending ? null : _submit,
          icon: _sending
              ? const SizedBox(
                  height: 16, width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.send, size: 18),
          label: const Text('Enviar reporte'),
        ),
      ],
    );
  }
}