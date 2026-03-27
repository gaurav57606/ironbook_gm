import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';

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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg3,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            height: 72,
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
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                    const Text(
                      'ACTIVE',
                      style: TextStyle(
                        fontSize: 7,
                        fontWeight: FontWeight.w400,
                        color: AppColors.text2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Member Health',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 7),
                _buildLegendItem(AppColors.green, 'Active', active),
                _buildLegendItem(AppColors.amber, 'Expiring', expiring),
                _buildLegendItem(AppColors.red, 'Expired', expired),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, int value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              color: AppColors.text2,
            ),
          ),
          const Spacer(),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
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
      ..color = AppColors.border
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, paintBase);

    if (total == 0) return;

    final activeAngle = 2 * math.pi * (active / total);
    final expiringAngle = 2 * math.pi * (expiring / total);
    final expiredAngle = 2 * math.pi * (expired / total);

    var startAngle = -math.pi / 2;

    final paintActive = Paint()
      ..color = AppColors.green
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final paintExpiring = Paint()
      ..color = AppColors.amber
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final paintExpired = Paint()
      ..color = AppColors.red
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
