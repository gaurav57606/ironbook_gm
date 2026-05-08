import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class SyncBanner extends StatelessWidget {
  final int count;

  const SyncBanner({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    final isCritical = count > 10;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (isCritical ? AppColors.expired : AppColors.expiring).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (isCritical ? AppColors.expired : AppColors.expiring).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            isCritical ? Icons.warning_amber_rounded : Icons.sync_problem_rounded,
            color: isCritical ? AppColors.expired : AppColors.expiring,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCritical ? 'CRITICAL: DO NOT UNINSTALL' : 'Sync Pending',
                  style: AppTextStyles.label.copyWith(
                    fontSize: 12,
                    color: isCritical ? AppColors.expired : AppColors.expiring,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isCritical
                    ? 'You have $count unsynced changes. Uninstalling will result in PERMANENT data loss.'
                    : '$count changes local-only. Backup to cloud for safety.',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 10,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
