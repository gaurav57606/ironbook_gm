import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_radius.dart';

enum AppButtonStyle { primary, secondary, outline }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonStyle style;
  final double? width;
  final Widget? icon;
  final bool isLoading;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.style = AppButtonStyle.primary,
    this.width,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPrimary = style == AppButtonStyle.primary;
    final bool isOutline = style == AppButtonStyle.outline;
    final bool isSecondary = style == AppButtonStyle.secondary;

    return SizedBox(
      width: width ?? double.infinity,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppRadius.radiusL,
          gradient: isPrimary ? AppColors.primaryGradient : null,
          color: isSecondary ? AppColors.elevation2 : (isOutline ? Colors.transparent : null),
          border: isOutline ? Border.all(color: AppColors.primary, width: 1.5) : (isSecondary ? Border.all(color: AppColors.border) : null),
          boxShadow: isPrimary ? [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ] : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: (onPressed == null || isLoading) ? null : onPressed,
            borderRadius: AppRadius.radiusL,
            splashColor: Colors.white.withValues(alpha: 0.1),
            highlightColor: Colors.white.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: AppSpacing.l),
              child: Opacity(
                opacity: onPressed == null || isLoading ? 0.6 : 1.0,
                child: Center(
                  child: isLoading 
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[
                            icon!,
                            AppSpacing.gapS,
                          ],
                          Text(
                            text,
                            style: AppTextStyles.buttonLarge.copyWith(
                              color: isPrimary ? Colors.white : (isOutline ? AppColors.primary : AppColors.text),
                            ),
                          ),
                        ],
                      ),
                ),
              ),
            ),
          ),
        ),
      ),
    ).animate(
      autoPlay: !const bool.fromEnvironment('FLUTTER_TEST'),
      target: (onPressed == null || isLoading) ? 0 : 1,
    )
     .scale(
       begin: const Offset(1, 1), 
       end: const Offset(1, 1), 
       duration: 100.ms
     ); // Basic structure, we'll rely on InkWell for feedback for now but add a small scale on tap if possible.
     // Actually, flutter_animate doesn't have a "onTap" trigger easily without a state.
     // I'll keep it simple but improved.
  }
}








