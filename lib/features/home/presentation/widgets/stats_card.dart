import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_radius.dart';

class StatsCard extends StatelessWidget {
  final String value;
  final String label;
  final bool isPrimary;
  final Color? valueColor;
  final VoidCallback? onTap;

  const StatsCard({
    super.key,
    required this.value,
    required this.label,
    this.isPrimary = false,
    this.valueColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.radiusXL,
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.m),
          decoration: BoxDecoration(
            color: isPrimary ? null : AppColors.elevation2,
            gradient: isPrimary ? AppColors.primaryGradient : null,
            borderRadius: AppRadius.radiusXL,
            border: isPrimary ? null : Border.all(color: AppColors.border),
            boxShadow: isPrimary ? [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              )
            ] : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: AppTextStyles.h2.copyWith(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: isPrimary ? Colors.white : (valueColor ?? AppColors.text),
                  height: 1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label.toUpperCase(),
                style: AppTextStyles.sectionTitle.copyWith(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: isPrimary ? Colors.white.withValues(alpha: 0.8) : AppColors.textMuted,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}









