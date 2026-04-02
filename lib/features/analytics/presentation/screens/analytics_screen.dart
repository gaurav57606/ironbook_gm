import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/widgets/status_bar_wrapper.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StatusBarWrapper(
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomRight,
              end: Alignment.topLeft,
              colors: [
                AppColors.orange.withValues(alpha: 0.05),
                AppColors.bg,
                AppColors.bg,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Gym Analytics',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.bg2,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Text('March 2026', style: TextStyle(color: AppColors.text3, fontSize: 10, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 4),
                            const Icon(Icons.calendar_today_rounded, color: AppColors.orange, size: 10),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      _buildMainStats(),
                      const SizedBox(height: 24),
                      _buildGraphPlaceholder('Revenue Trends'),
                      const SizedBox(height: 16),
                      _buildGraphPlaceholder('Member Attendance'),
                      const SizedBox(height: 24),
                      const Text('Top Performing Plans', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 16),
                      _buildPlanRank('Elite Coaching', 0.8),
                      _buildPlanRank('Standard Gym', 0.6),
                      _buildPlanRank('Yoga Specialized', 0.3),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainStats() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Total Members', '1,248', '+12%', Icons.people_rounded)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('Total Revenue', r'$142k', '+8%', Icons.account_balance_wallet_rounded)),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String growth, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: AppColors.orange, size: 20),
              Text(growth, style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(color: AppColors.text3, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildGraphPlaceholder(String title) {
    return Container(
      height: 160,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (index) {
              final height = 40.0 + (index * 10) % 60;
              return Container(
                width: 12,
                height: height,
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.3 + (index * 0.1)),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanRank(String plan, double percent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.bg2,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.star_rounded, color: AppColors.orange, size: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plan, style: const TextStyle(color: Colors.white, fontSize: 14)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: percent,
                    minHeight: 2,
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.orange),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text('${(percent * 100).toInt()}%', style: const TextStyle(color: AppColors.text3, fontSize: 10)),
        ],
      ),
    );
  }
}
