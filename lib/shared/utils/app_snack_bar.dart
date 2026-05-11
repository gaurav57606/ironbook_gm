import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_radius.dart';

class AppSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    bool isError = false,
    bool isSuccess = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    Color backgroundColor = AppColors.bg2;
    Color borderColor = AppColors.border;
    IconData icon = Icons.info_outline_rounded;
    Color iconColor = AppColors.textSecondary;

    if (isError) {
      backgroundColor = const Color(0xFF1A0A0A);
      borderColor = AppColors.red.withValues(alpha: 0.3);
      icon = Icons.error_outline_rounded;
      iconColor = AppColors.red;
    } else if (isSuccess) {
      backgroundColor = const Color(0xFF0A1A0A);
      borderColor = AppColors.green.withValues(alpha: 0.3);
      icon = Icons.check_circle_outline_rounded;
      iconColor = AppColors.green;
    }

    messenger.showSnackBar(
      SnackBar(
        duration: duration,
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.all(16),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: AppRadius.radiusL,
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void showSuccess(BuildContext context, String message) {
    show(context, message: message, isSuccess: true);
  }

  static void showError(BuildContext context, String message) {
    show(context, message: message, isError: true);
  }
}
