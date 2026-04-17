import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class StatsCard extends StatelessWidget {
  final String value;
  final String label;
  final bool isPrimary;
  final Color? valueColor;

  const StatsCard({
    super.key,
    required this.value,
    required this.label,
    this.isPrimary = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPrimary ? null : AppColors.elevation1,
        gradient: isPrimary ? AppColors.primaryGradient : null,
        borderRadius: BorderRadius.circular(20),
        border: isPrimary ? null : Border.all(color: AppColors.border),
        boxShadow: isPrimary ? [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ] : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: AppTextStyles.heroNumber.copyWith(
              fontSize: 28,
              color: isPrimary ? Colors.white : (valueColor ?? AppColors.textPrimary),
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label.toUpperCase(),
            style: AppTextStyles.sectionTitle.copyWith(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: isPrimary ? Colors.white.withValues(alpha: 0.7) : AppColors.textMuted,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
