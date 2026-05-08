import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_shadows.dart';

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
          boxShadow: isPrimary ? AppShadows.primary : [],
        ),
        child: Opacity(
          opacity: onPressed == null || isLoading ? 0.6 : 1.0,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isLoading ? null : onPressed,
            borderRadius: AppRadius.radiusL,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.m, horizontal: AppSpacing.l),
              child: Center(
                child: isLoading 
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
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
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isPrimary ? Colors.white : (isOutline ? AppColors.primary : AppColors.text),
                            letterSpacing: 0.2,
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
    );
  }
}








