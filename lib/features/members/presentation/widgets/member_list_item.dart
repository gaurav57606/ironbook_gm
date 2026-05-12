import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/providers/member_provider.dart';
import '../../../../core/data/local/models/member_snapshot_model.dart';
import '../../../../shared/utils/date_utils.dart';
import '../../../../shared/utils/clock.dart';

class MemberListItem extends ConsumerWidget {
  final String memberId;
  const MemberListItem({super.key, required this.memberId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final member = ref.watch(memberByIdProvider(memberId));
    if (member == null) return const SizedBox.shrink();

    final now = ref.watch(clockProvider).now;
    final status = member.getStatus(now);
    final statusColor = _getStatusColor(status);
    final statusMsg = _getStatusMessage(member, now);
    final initials =
        member.name.isNotEmpty ? member.name.substring(0, 1).toUpperCase() : '?';

    return GestureDetector(
      onTap: () => context.push('/members/member-details/${member.memberId}'),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.m),
        decoration: BoxDecoration(
          color: AppColors.elevation2,
          borderRadius: AppRadius.radiusXL,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppColors.glassGradient,
                borderRadius: AppRadius.radiusL,
                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: AppTextStyles.h3.copyWith(
                  fontSize: 18, 
                  color: statusColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(member.name,
                      style: AppTextStyles.memberName.copyWith(fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(
                    '${member.planName ?? "N/A"} · Joined ${AppDateUtils.formatShort(member.joinDate)}',
                    style: AppTextStyles.bodySmall
                        .copyWith(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.08),
                borderRadius: AppRadius.radiusS,
                border: Border.all(color: statusColor.withValues(alpha: 0.15)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: statusColor, 
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withValues(alpha: 0.4),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    statusMsg.toUpperCase(),
                    style: AppTextStyles.sectionTitle.copyWith(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: statusColor,
                      letterSpacing: 0.5,
                    ),
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
    if (days == 0) return 'Due Today';
    if (days <= 7) return '$days Days Left';
    return '${days}d Left';
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
        return AppColors.textSecondary;
      case MemberStatus.archived:
        return AppColors.textMuted;
    }
  }
}
