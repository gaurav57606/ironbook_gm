import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/data/local/models/member_snapshot_model.dart';
import '../../../../shared/utils/clock.dart';
import '../../../../shared/utils/date_formatter.dart';

class MemberListItem extends ConsumerWidget {
  final MemberSnapshot member;
  const MemberListItem({super.key, required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider).now;
    final status = member.getStatus(now);
    final statusColor = _getStatusColor(status);
    final statusMsg = _getStatusMessage(member, now);
    final initials =
        member.name.isNotEmpty ? member.name.substring(0, 1).toUpperCase() : '?';

    return GestureDetector(
      onTap: () => context.push('/gym/member-details/${member.memberId}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.elevation2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    statusColor.withValues(alpha: 0.2),
                    statusColor.withValues(alpha: 0.1)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: statusColor.withValues(alpha: 0.2)),
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: AppTextStyles.cardTitle
                    .copyWith(fontSize: 16, color: statusColor),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(member.name,
                      style: AppTextStyles.memberName.copyWith(fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(
                    '${member.planName ?? "N/A"} · Since ${DateFormatter.formatShort(member.joinDate)}',
                    style: AppTextStyles.bodySmall
                        .copyWith(fontSize: 10, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                          color: statusColor, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(
                    statusMsg,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: statusColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusMessage(MemberSnapshot m, DateTime now) {
    final days = m.getDaysRemaining(now);
    if (days < 0) return 'Expired';
    if (days == 0) return 'Today';
    if (days <= 7) return '$days days';
    return '${days}d';
  }

  Color _getStatusColor(MemberStatus status) {
    switch (status) {
      case MemberStatus.active:
        return AppColors.green;
      case MemberStatus.expiring:
        return AppColors.amber;
      case MemberStatus.expired:
        return AppColors.red;
      case MemberStatus.pending:
        return AppColors.text3;
    }
  }
}
