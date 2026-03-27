import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';

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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPrimary ? null : AppColors.bg3,
        gradient: isPrimary
            ? const LinearGradient(
                colors: [AppColors.orangeD, AppColors.orange],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: BorderRadius.circular(14),
        border: isPrimary ? null : Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isPrimary ? Colors.white : (valueColor ?? AppColors.text),
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: isPrimary ? Colors.white.withValues(alpha: 0.7) : AppColors.text2,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}
