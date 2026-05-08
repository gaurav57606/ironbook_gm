import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';

class AppEmptyState extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? subtitle;

  const AppEmptyState({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 48,
            color: AppColors.textMuted.withValues(alpha: 0.3),
          ),
          AppSpacing.gapM,
          Text(
            title,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          if (subtitle != null) ...[
            AppSpacing.gapXS,
            Text(
              subtitle!,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}
