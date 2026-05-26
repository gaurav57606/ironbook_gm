import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import 'dart:io';

class GymProfileCard extends StatelessWidget {
  final String? gymName;
  final String? logoPath;

  const GymProfileCard({super.key, required this.gymName, this.logoPath});

  @override
  Widget build(BuildContext context) {
    final String initial = (gymName ?? 'R').substring(0, 1).toUpperCase();
    final bool hasValidLogo = logoPath != null && File(logoPath!).existsSync();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding, vertical: 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.radiusXXL,
        child: InkWell(
          onTap: () => context.push('/settings/gym-profile'),
          borderRadius: AppRadius.radiusXXL,
          splashColor: AppColors.primary.withValues(alpha: 0.06),
          highlightColor: AppColors.primary.withValues(alpha: 0.03),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.l),
            decoration: BoxDecoration(
              gradient: AppColors.glassGradient,
              borderRadius: AppRadius.radiusXXL,
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: hasValidLogo ? null : AppColors.primaryGradient,
                    borderRadius: AppRadius.radiusXL,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  alignment: Alignment.center,
                  child: hasValidLogo
                      ? Image.file(
                          File(logoPath!),
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                        )
                      : Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        gymName ?? 'Raj\'s Fitness',
                        style: AppTextStyles.h3.copyWith(fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: AppRadius.radiusS,
                        ),
                        child: Text(
                          'PRO EDITION • PREMIUM',
                          style: AppTextStyles.sectionTitle.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 24, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
