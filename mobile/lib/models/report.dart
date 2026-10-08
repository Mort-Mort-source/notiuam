class Report {
  final String id;
  final String targetType;      // 'POST' | 'CHANNEL'
  final String targetId;
  final String targetPreview;
  final String? targetDetails;
  final String reporterDisplayName;
  final String reason;
  final String? details;
  final String status;          // 'PENDING' | 'RESOLVED_KEEP' | 'RESOLVED_DELETE'
  final int voteCount;
  final int keepVotes;
  final int deleteVotes;
  final bool votedByMe;
  final String? myVote;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? resolvedByDisplayName;

  Report({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.targetPreview,
    this.targetDetails,
    required this.reporterDisplayName,
    required this.reason,
    this.details,
    required this.status,
    required this.voteCount,
    required this.keepVotes,
    required this.deleteVotes,
    required this.votedByMe,
    this.myVote,
    required this.createdAt,
    this.resolvedAt,
    this.resolvedByDisplayName,
  });

  factory Report.fromJson(Map<String, dynamic> json) => Report(
        id: json['id'] as String,
        targetType: json['targetType'] as String,
        targetId: json['targetId'] as String,
        targetPreview: json['targetPreview'] as String? ?? '',
        targetDetails: json['targetDetails'] as String?,
        reporterDisplayName: json['reporterDisplayName'] as String? ?? '',
        reason: json['reason'] as String,
        details: json['details'] as String?,
        status: json['status'] as String,
        voteCount: (json['voteCount'] as num?)?.toInt() ?? 0,
        keepVotes: (json['keepVotes'] as num?)?.toInt() ?? 0,
        deleteVotes: (json['deleteVotes'] as num?)?.toInt() ?? 0,
        votedByMe: json['votedByMe'] as bool? ?? false,
        myVote: json['myVote'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        resolvedAt: json['resolvedAt'] != null
            ? DateTime.parse(json['resolvedAt'] as String)
            : null,
        resolvedByDisplayName: json['resolvedByDisplayName'] as String?,
      );

  String get reasonLabel {
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

  String get statusLabel {
    switch (status) {
      case 'PENDING':
        return 'Pendiente';
      case 'RESOLVED_KEEP':
        return 'Resuelto: se conserva';
      case 'RESOLVED_DELETE':
        return 'Resuelto: eliminado';
      default:
        return status;
    }
  }
}