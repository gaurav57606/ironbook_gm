import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Icon(
                icon,
                size: 80,
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            )
            .animate(
              autoPlay: !const bool.fromEnvironment('FLUTTER_TEST'),
              onPlay: (c) => !const bool.fromEnvironment('FLUTTER_TEST') ? c.repeat(reverse: true) : null,
            )
            .scale(duration: 2.seconds, begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), curve: Curves.easeInOut)
            .fadeIn(duration: 1.seconds),
            
            AppSpacing.gapL,
            Text(
              title.toUpperCase(),
              textAlign: TextAlign.center,
              style: AppTextStyles.h3.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: AppColors.text,
              ),
            ).animate(autoPlay: !const bool.fromEnvironment('FLUTTER_TEST')).fadeIn(delay: 200.ms).slideY(begin: 0.2),
            
            if (subtitle != null) ...[
              AppSpacing.gapS,
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMuted,
                    height: 1.5,
                  ),
                ),
              ).animate(autoPlay: !const bool.fromEnvironment('FLUTTER_TEST')).fadeIn(delay: 400.ms),
            ],
          ],
        ),
      ),
    );
  }
}
