import 'package:flutter/material.dart';
import '../core/theme.dart';

class ChannelOwnerBadge extends StatelessWidget {
  final String ownerRole;
  final bool compact;

  const ChannelOwnerBadge({
    super.key,
    required this.ownerRole,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (ownerRole == 'STUDENT') return const SizedBox.shrink();

    if (ownerRole == 'PROFESSOR') {
      return _badge(
        icon: Icons.school_outlined,
        label: 'Profesor',
        color: NotiuamColors.info,
      );
    }

    if (ownerRole == 'ADMIN' || ownerRole == 'SUPERADMIN') {
      return _badge(
        icon: Icons.verified_outlined,
        label: 'Oficial',
        color: NotiuamColors.orangeDark,
      );
    }

    return const SizedBox.shrink();
  }

  Widget _badge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 10 : 12, color: color),
          SizedBox(width: compact ? 3 : 4),
          Text(
            label,
            style: TextStyle(
              fontSize: compact ? 9 : 10,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}