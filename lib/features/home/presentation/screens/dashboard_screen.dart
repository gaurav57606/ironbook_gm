import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../shared/widgets/app_section_header.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../widgets/sync_status_badge.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ⚡ Bolt: Use .select() to only rebuild when the specific field changes
    final membersLength = ref.watch(membersProvider.select((m) => m.length));
    final gymName = ref.watch(ownerProvider.select((o) => o?.gymName ?? 'IRONBOOK GM'));
    
    // ⚡ Bolt: Moved frequently updating sync state to isolated SyncStatusBadge widget
    // Removing these watches from the top-level DashboardScreen prevents 
    // the entire screen (including charts) from rebuilding every second during sync.
    final memberStats = ref.watch(dashboardMemberStatsProvider);
    final revenueStats = ref.watch(dashboardRevenueProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: StatusBarWrapper(
          child: RefreshIndicator(
            onRefresh: () async {
              await ref.read(syncWorkerProvider).performSync();
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                    child: _buildHeader(gymName)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatsGrid(
                            membersLength,
                            memberStats.activeCount,
                            memberStats.expiringCount,
                            memberStats.expiredCount),
                        AppSpacing.gapXL,
                        MemberHealthDonut(
                          active: memberStats.activeCount,
                          expiring: memberStats.expiringCount,
                          expired: memberStats.expiredCount,
                        ),
                        AppSpacing.gapXL,
                        const SyncStatusBadge(), // Rebuilds isolated here
                        AppSpacing.gapL,
                        if (memberStats.expiredCount > 0)
                          AlertBanner(
                            title:
                                '${memberStats.expiredCount} memberships expired',
                            subtitle:
                                '${memberStats.expiredMembers}${memberStats.expiredCount > 3 ? " +${memberStats.expiredCount - 3}" : ""}',
                            isError: true,
                          ),
                        if (memberStats.expiringCount > 0)
                          Padding(
                            padding: EdgeInsets.only(
                                top: memberStats.expiredCount > 0 ? AppSpacing.s : 0),
                            child: AlertBanner(
                              title:
                                  '${memberStats.expiringCount} expiring in 7 days',
                              subtitle:
                                  '${memberStats.expiringMembers}${memberStats.expiringCount > 3 ? " +${memberStats.expiringCount - 3}" : ""}',
                              isError: false,
                            ),
                          ),
                        AppSectionHeader(
                          title: 'DUE TODAY',
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sectionGap),
                          trailing: GestureDetector(
                            onTap: () => context.go('/gym'),
                            child: Row(
                              children: [
                                Text(
                                  'SHOW ALL',
                                  style: AppTextStyles.bodySmall.copyWith(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary),
                                ),
                                AppSpacing.gapXS,
                                const Icon(Icons.arrow_forward_ios_rounded,
                                    size: 8, color: AppColors.primary),
                              ],
                            ),
                          ),
                        ),
                        _buildDueList(memberStats.dueMembers),
                        const AppSectionHeader(
                          title: 'REVENUE THIS MONTH',
                          padding: EdgeInsets.symmetric(vertical: AppSpacing.sectionGap),
                        ),
                        _buildRevenueCard(revenueStats.currentRevenue.toInt(),
                            revenueStats.trend, revenueStats.dailyRevenue),
                        const NutritionSummaryCard(),
                        const SizedBox(
                            height: 100), // Space for bottom nav or FAB
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String gymName) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, AppSpacing.xl, AppSpacing.screenPadding, AppSpacing.sectionGap),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${GreetingFormatter.greeting()},'.toUpperCase(),
                style: AppTextStyles.sectionTitle.copyWith(color: AppColors.textMuted),
              ),
              AppSpacing.gapXS,
              Text(
                gymName,
                style: AppTextStyles.cardTitle
                    .copyWith(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 2),
              Text(
                DateFormatter.format(DateTime.now()).toUpperCase(),
                style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    letterSpacing: 1.0),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: AppRadius.radiusL,
            ),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.elevation4,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(AppSpacing.s),
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.contain,
                errorBuilder: (c, e, s) => const Icon(
                    Icons.fitness_center_rounded,
                    size: 24,
                    color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildStatsGrid(int total, int active, int expiring, int expired) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.s,
        crossAxisSpacing: AppSpacing.s,
        childAspectRatio: 1.8,
        children: [
          StatsCard(
              value: total.toString(), label: 'Total Members', isPrimary: true),
          StatsCard(
              value: active.toString(),
              label: 'Active',
              valueColor: AppColors.green),
          StatsCard(
              value: expiring.toString(),
              label: 'Expiring Soon',
              valueColor: AppColors.amber),
          StatsCard(
              value: expired.toString(),
              label: 'Expired',
              valueColor: AppColors.red),
        ],
      ),
    );
  }


  Widget _buildDueList(List<MemberSnapshot> due) {
    if (due.isEmpty) {
      return Container(
        height: 80,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.elevation1,
          borderRadius: AppRadius.radiusXL,
          border: Border.all(color: AppColors.border),
        ),
        child: Text('NO TASKS DUE TODAY',
            style: AppTextStyles.tiny.copyWith(letterSpacing: 1.0, color: AppColors.textMuted)),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.elevation1,
        borderRadius: AppRadius.radiusXXL,
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: List.generate(due.length, (index) {
          final m = due[index];
          final days = m.daysRemaining;
          final status = m.status;
          final color = status == MemberStatus.expired
              ? AppColors.expired
              : (status == MemberStatus.expiring
                  ? AppColors.expiring
                  : AppColors.active);

          return MemberRow(
            name: m.name,
            initials:
                m.name.isNotEmpty ? m.name.substring(0, 1).toUpperCase() : '?',
            subtitle: '${m.planName ?? "N/A"} · ₹${m.totalPaid.toInt()}',
            daysLeft: days.toString(),
            statusColor: color,
          );
        }),
      ),
    );
  }

  Widget _buildRevenueCard(
      int totalRevenue, double trend, List<double> dailyRevenue) {
    final isPositive = trend >= 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.elevation2,
        borderRadius: AppRadius.radiusXXL,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'COLLECTED REVENUE'.toUpperCase(),
                style: AppTextStyles.sectionTitle.copyWith(color: AppColors.textMuted),
              ),
              AppSpacing.gapS,
              Text(
                '₹$totalRevenue',
                style: AppTextStyles.cardTitle
                    .copyWith(fontSize: 24, color: AppColors.primary),
              ),
              AppSpacing.gapXS,
              Row(
                children: [
                  Icon(
                    isPositive
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    size: 12,
                    color: isPositive ? AppColors.green : AppColors.red,
                  ),
                  AppSpacing.gapXS,
                  Text(
                    '${trend.abs().toStringAsFixed(1)}% ${isPositive ? "increase" : "decrease"}',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 9,
                      color: isPositive ? AppColors.green : AppColors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          _buildMiniBars(dailyRevenue),
        ],
      ),
    );
  }

  Widget _buildMiniBars(List<double> dailyRevenue) {
    final maxRev = dailyRevenue.reduce((a, b) => a > b ? a : b);
    final normalized = dailyRevenue
        .map((r) => maxRev > 0 ? (r / maxRev).clamp(0.1, 1.0) : 0.1)
        .toList();

    return SizedBox(
      height: 36,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(normalized.length, (index) {
          final isLast = index == normalized.length - 1;
          return Container(
            width: 6,
            height: 36 * normalized[index],
            margin: const EdgeInsets.only(left: 3),
            decoration: BoxDecoration(
              color: isLast ? AppColors.orange : AppColors.bg4,
              borderRadius: AppRadius.radiusXS,
            ),
          );
        }),
      ),
    );
  }

  }
}
