import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class MemberHealthDonut extends StatelessWidget {
  final int active;
  final int expiring;
  final int expired;

  const MemberHealthDonut({
    super.key,
    required this.active,
    required this.expiring,
    required this.expired,
  });

  @override
  Widget build(BuildContext context) {
    final total = active + expiring + expired;
    final activePct = total > 0 ? (active / total * 100).toInt() : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.elevation1,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CustomPaint(
              painter: DonutPainter(
                active: active,
                expiring: expiring,
                expired: expired,
                total: total,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$activePct%',
                      style: AppTextStyles.heroNumber.copyWith(
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'HEALTH',
                      style: AppTextStyles.sectionTitle.copyWith(
                        fontSize: 6,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HEALTH OVERVIEW',
                  style: AppTextStyles.sectionTitle.copyWith(fontSize: 8, letterSpacing: 1.5),
                ),
                const SizedBox(height: 12),
                _buildLegendItem(AppColors.active, 'Active', active),
                _buildLegendItem(AppColors.expiring, 'Expiring', expiring),
                _buildLegendItem(AppColors.expired, 'Expired', expired),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, int value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 4,
                )
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
          const Spacer(),
          Text(
            value.toString(),
            style: AppTextStyles.body.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class DonutPainter extends CustomPainter {
  final int active;
  final int expiring;
  final int expired;
  final int total;

  DonutPainter({
    required this.active,
    required this.expiring,
    required this.expired,
    required this.total,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5;
    const strokeWidth = 10.0;

    final paintBase = Paint()
      ..color = AppColors.border.withValues(alpha: 0.3)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, paintBase);

    if (total == 0) return;

    final activeAngle = 2 * math.pi * (active / total);
    final expiringAngle = 2 * math.pi * (expiring / total);
    final expiredAngle = 2 * math.pi * (expired / total);

    var startAngle = -math.pi / 2;

    final paintActive = Paint()
      ..color = AppColors.active
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final paintExpiring = Paint()
      ..color = AppColors.expiring
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final paintExpired = Paint()
      ..color = AppColors.expired
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw arcs
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, activeAngle, false, paintActive);
    startAngle += activeAngle;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, expiringAngle, false, paintExpiring);
    startAngle += expiringAngle;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, expiredAngle, false, paintExpired);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
