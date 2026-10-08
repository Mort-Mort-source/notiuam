import 'package:flutter/foundation.dart';
import '../core/api_client.dart';
import '../models/admin_user.dart';
import '../models/audit_log.dart';
import '../models/report.dart';

class AdminProvider extends ChangeNotifier {
  final ApiClient _api;
  AdminProvider(this._api);

  // Reportes
  List<Report> _reports = [];
  bool _loadingReports = false;
  String? _reportsError;

  // Usuarios
  List<AdminUser> _users = [];
  bool _loadingUsers = false;
  String? _usersError;

  // Auditoría
  List<AuditLog> _audit = [];
  bool _loadingAudit = false;
  String? _auditError;

  List<Report> get reports => _reports;
  bool get loadingReports => _loadingReports;
  String? get reportsError => _reportsError;

  List<AdminUser> get users => _users;
  bool get loadingUsers => _loadingUsers;
  String? get usersError => _usersError;

  List<AuditLog> get audit => _audit;
  bool get loadingAudit => _loadingAudit;
  String? get auditError => _auditError;

  // ---------- Reportes ----------

  Future<void> loadReports({String? status}) async {
    _loadingReports = true;
    _reportsError = null;
    notifyListeners();
    try {
      final res = await _api.dio.get('/api/admin/reports', queryParameters: {
        if (status != null) 'status': status,
        'page': 0,
        'size': 100,
      });
      _reports = (res.data['content'] as List)
          .map((e) => Report.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _reportsError = ApiClient.extractError(e);
    } finally {
      _loadingReports = false;
      notifyListeners();
    }
  }

  Future<Report> getReport(String id) async {
    final res = await _api.dio.get('/api/admin/reports/$id');
    return Report.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> vote(String reportId, String decision, {String? comment}) async {
    await _api.dio.post('/api/admin/reports/$reportId/vote', data: {
      'decision': decision,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
    });
    await loadReports();
  }

  // ---------- Usuarios ----------

  Future<void> loadUsers({String? query}) async {
    _loadingUsers = true;
    _usersError = null;
    notifyListeners();
    try {
      final res = await _api.dio.get('/api/admin/users', queryParameters: {
        if (query != null && query.isNotEmpty) 'q': query,
        'page': 0,
        'size': 100,
      });
      _users = (res.data['content'] as List)
          .map((e) => AdminUser.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _usersError = ApiClient.extractError(e);
    } finally {
      _loadingUsers = false;
      notifyListeners();
    }
  }

  Future<void> changeRole(String userId, String newRole) async {
    await _api.dio.patch('/api/admin/users/$userId/role', data: {
      'role': newRole,
    });
    await loadUsers();
  }

  Future<void> toggleUserStatus(String userId, bool enabled) async {
    await _api.dio.patch('/api/admin/users/$userId/status', data: {
      'enabled': enabled,
    });
    await loadUsers();
  }

  // ---------- Auditoría ----------

  Future<void> loadAudit() async {
    _loadingAudit = true;
    _auditError = null;
    notifyListeners();
    try {
      final res = await _api.dio.get('/api/admin/audit', queryParameters: {
        'page': 0,
        'size': 100,
      });
      _audit = (res.data['content'] as List)
          .map((e) => AuditLog.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _auditError = ApiClient.extractError(e);
    } finally {
      _loadingAudit = false;
      notifyListeners();
    }
  }
}