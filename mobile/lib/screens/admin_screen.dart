import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../state/auth_provider.dart';
import 'admin_reports_tab.dart';
import 'admin_users_tab.dart';
import 'admin_audit_tab.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isSuper = auth.isSuperAdmin;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Administración'),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.flag_outlined), text: 'Reportes'),
              Tab(icon: Icon(Icons.people_outline), text: 'Usuarios'),
              Tab(icon: Icon(Icons.history), text: 'Auditoría'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const AdminReportsTab(),
            const AdminUsersTab(),
            AdminAuditTab(isSuperAdmin: isSuper),
          ],
        ),
      ),
    );
  }
}