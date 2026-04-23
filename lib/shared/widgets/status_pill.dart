import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import 'package:ironbook_gm/core/data/local/models/member_snapshot_model.dart';

class StatusPill extends StatelessWidget {
  final MemberStatus status;
  final String? label;

  const StatusPill({
    super.key,
    required this.status,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    final text = label ?? _getLabel();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor() {
    switch (status) {
      case MemberStatus.active: return AppColors.green;
      case MemberStatus.expiring: return AppColors.amber;
      case MemberStatus.expired: return AppColors.red;
      case MemberStatus.pending: return AppColors.text3;
    }
  }

  String _getLabel() {
    switch (status) {
      case MemberStatus.active: return 'Active';
      case MemberStatus.expiring: return 'Expiring';
      case MemberStatus.expired: return 'Expired';
      case MemberStatus.pending: return 'Pending';
    }
  }
}








