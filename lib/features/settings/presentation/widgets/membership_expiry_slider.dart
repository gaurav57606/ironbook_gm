import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class MembershipExpirySlider extends StatelessWidget {
  final int expiryReminderDays;
  final ValueChanged<double> onChanged;

  const MembershipExpirySlider({
    super.key,
    required this.expiryReminderDays,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Membership Expiry Notice',
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$expiryReminderDays DAYS',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Notify gym owner and members before their plan expires.',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.border,
              thumbColor: AppColors.textPrimary,
              overlayColor: AppColors.primary.withValues(alpha: 0.1),
              valueIndicatorColor: AppColors.primary,
              valueIndicatorTextStyle: const TextStyle(color: Colors.white),
            ),
            child: Slider(
              value: expiryReminderDays.toDouble(),
              min: 1,
              max: 15,
              divisions: 14,
              label: expiryReminderDays.toString(),
              onChanged: onChanged,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1 DAY',
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 9)),
              Text('15 DAYS',
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }
}
