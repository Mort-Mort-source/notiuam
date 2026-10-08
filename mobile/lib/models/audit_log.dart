class AuditLog {
  final String id;
  final String adminId;
  final String adminDisplayName;
  final String action;
  final String? targetType;
  final String? targetId;
  final String? details;
  final DateTime createdAt;

  AuditLog({
    required this.id,
    required this.adminId,
    required this.adminDisplayName,
    required this.action,
    this.targetType,
    this.targetId,
    this.details,
    required this.createdAt,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) => AuditLog(
        id: json['id'] as String,
        adminId: json['adminId'] as String,
        adminDisplayName: json['adminDisplayName'] as String? ?? '',
        action: json['action'] as String,
        targetType: json['targetType'] as String?,
        targetId: json['targetId'] as String?,
        details: json['details'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}