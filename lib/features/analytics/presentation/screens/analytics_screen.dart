import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ironbook_gm/core/constants/app_colors.dart';
import '../../data/repositories/analytics_repository.dart';
import '../../data/models/analytics_summary.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/sync_status_indicator.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(analyticsSummaryProvider);

    return Scaffold(
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
              _buildHeader(context),
              Expanded(
                child: summaryAsync.when(
                  data: (summary) => _buildContent(summary),
                  loading: () => const Center(child: CircularProgressIndicator(color: AppColors.orange)),
                  error: (e, st) => Center(child: Text('Error loading analytics: $e', style: const TextStyle(color: Colors.red))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.screenPadding,
        right: AppSpacing.screenPadding,
        top: AppSpacing.xl,
        bottom: AppSpacing.m,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gym Analytics',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  DateFormat('MMMM yyyy').format(DateTime.now()).toUpperCase(),
                  style: AppTextStyles.sectionTitle.copyWith(color: AppColors.textMuted, fontSize: 10),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => context.push('/notifications'),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.elevation2,
              padding: const EdgeInsets.all(8),
            ),
            icon: Stack(
              children: [
                const Icon(Icons.notifications_none_rounded, color: AppColors.text3, size: 20),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.orange,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.bg, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const SyncStatusIndicator(),
        ],
      ),
    );
  }

  Widget _buildContent(AnalyticsSummary summary) {
    final currencyFormat = NumberFormat.compactCurrency(symbol: '₹', decimalDigits: 0);
    
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard('Total Members', summary.totalMembers.toString(), '+${summary.growthPercent}%', Icons.people_rounded)),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard('Total Revenue', currencyFormat.format(summary.totalRevenue), '+${summary.revenueGrowthPercent}%', Icons.account_balance_wallet_rounded)),
          ],
        ),
        const SizedBox(height: 24),
        _buildRevenueGraph('Revenue Trends (7d)', summary.weeklyRevenue),
        const SizedBox(height: 16),
        _buildAttendanceGraph('Check-ins (7d)', summary.weeklyAttendance),
        const SizedBox(height: 24),
        const Text('Top Performing Plans', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        if (summary.topPlans.isEmpty)
          const Text('No plan data yet.', style: TextStyle(color: AppColors.text3, fontSize: 12))
        else
          ...summary.topPlans.map((plan) => _buildPlanRank(plan.name, plan.percentage)),
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

  Widget _buildRevenueGraph(String title, List<double> data) {
    return _buildGraph(title, data, isCurrency: true);
  }

  Widget _buildAttendanceGraph(String title, List<double> data) {
    return _buildGraph(title, data, isCurrency: false);
  }

  Widget _buildGraph(String title, List<double> data, {bool isCurrency = false}) {
    final maxVal = data.isEmpty ? 1.0 : data.reduce((a, b) => a > b ? a : b);
    
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
            children: List.generate(data.length, (index) {
              final val = data[index];
              final height = maxVal == 0 ? 2.0 : (val / maxVal) * 80.0 + 2.0;
              return Column(
                children: [
                  Container(
                    width: 14,
                    height: height,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          AppColors.orange.withValues(alpha: 0.1),
                          AppColors.orange.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
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









