import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/report.dart';
import '../state/admin_provider.dart';
import 'report_detail_screen.dart';

class AdminReportsTab extends StatefulWidget {
  const AdminReportsTab({super.key});

  @override
  State<AdminReportsTab> createState() => _AdminReportsTabState();
}

class _AdminReportsTabState extends State<AdminReportsTab> {
  String _filter = 'PENDING';

  static const _filters = [
    ('PENDING', 'Pendientes'),
    ('RESOLVED_KEEP', 'Conservados'),
    ('RESOLVED_DELETE', 'Eliminados'),
    ('ALL', 'Todos'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadReports(status: 'PENDING');
    });
  }

  Future<void> _reload() async {
    await context.read<AdminProvider>().loadReports(
          status: _filter == 'ALL' ? null : _filter,
        );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: _filters.map((f) {
              final selected = _filter == f.$1;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(f.$2),
                  selected: selected,
                  onSelected: (_) {
                    setState(() => _filter = f.$1);
                    context.read<AdminProvider>().loadReports(
                          status: f.$1 == 'ALL' ? null : f.$1,
                        );
                  },
                ),
              );
            }).toList(),
          ),
        ),
        if (provider.loadingReports) const LinearProgressIndicator(),
        if (provider.reportsError != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(provider.reportsError!,
                style: const TextStyle(color: NotiuamColors.danger)),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _reload,
            child: provider.reports.isEmpty && !provider.loadingReports
                ? ListView(
                    children: const [
                      SizedBox(height: 80),
                      Center(child: Text('No hay reportes con este filtro')),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    itemCount: provider.reports.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _ReportCard(
                      report: provider.reports[i],
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReportDetailScreen(
                              reportId: provider.reports[i].id,
                            ),
                          ),
                        );
                        await _reload();
                      },
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

// _ReportCard se queda igual que en D3
class _ReportCard extends StatelessWidget {
  final Report report;
  final VoidCallback onTap;

  const _ReportCard({required this.report, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d MMM · HH:mm', 'es');
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _typeChip(report.targetType),
                  const SizedBox(width: 8),
                  _reasonChip(report.reasonLabel),
                  const Spacer(),
                  _statusChip(report.status, report.statusLabel),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                report.targetPreview,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (report.targetDetails != null &&
                  report.targetDetails!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  report.targetDetails!,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Reportado por ${report.reporterDisplayName}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    fmt.format(report.createdAt.toLocal()),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _voteIndicator(Icons.thumb_up_outlined, '${report.keepVotes}',
                      NotiuamColors.success),
                  const SizedBox(width: 12),
                  _voteIndicator(Icons.thumb_down_outlined, '${report.deleteVotes}',
                      NotiuamColors.danger),
                  const SizedBox(width: 12),
                  Text('${report.voteCount}/3',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700)),
                  if (report.votedByMe) ...[
                    const Spacer(),
                    const Icon(Icons.how_to_vote,
                        size: 16, color: NotiuamColors.orange),
                    const SizedBox(width: 4),
                    const Text('Ya votaste',
                        style: TextStyle(
                            fontSize: 12, color: NotiuamColors.orangeDark)),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeChip(String type) {
    final isPost = type == 'POST';
    final color = isPost ? NotiuamColors.info : NotiuamColors.orangeDark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isPost ? Icons.article_outlined : Icons.folder_outlined,
              size: 12, color: color),
          const SizedBox(width: 4),
          Text(isPost ? 'Post' : 'Canal',
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _reasonChip(String reason) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(reason,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _voteIndicator(IconData icon, String count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 2),
        Text(count,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }
}