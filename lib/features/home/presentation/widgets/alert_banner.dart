import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';

class AlertBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isError;

  const AlertBanner({
    super.key,
    required this.title,
    required this.subtitle,
    this.isError = true,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = isError ? AppColors.red : AppColors.amber;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.text2,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 14, color: AppColors.text3),
        ],
      ),
    );
  }
}
