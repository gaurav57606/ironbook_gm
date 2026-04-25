import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../../shared/widgets/status_bar_wrapper.dart';
import '../../../../core/providers/member_provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/data/local/models/member_snapshot_model.dart';
import '../../../../shared/utils/date_formatter.dart';
import '../../../../shared/utils/greeting_formatter.dart';
import 'package:go_router/go_router.dart';
import '../widgets/stats_card.dart';
import '../widgets/member_health_donut.dart';
import '../widgets/alert_banner.dart';
import '../widgets/member_row.dart';
import '../../../../core/data/sync_worker.dart';
import '../../../../core/providers/bootstrap_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(membersProvider);
    final now = DateTime.now();
    final auth = ref.watch(authProvider);
    final unsyncedCount = ref.watch(unsyncedCountProvider).valueOrNull ?? 0;
    final tier2Status = ref.watch(tier2StatusProvider);
    final syncState = ref.watch(syncWorkerStatusProvider);
    
    // ⚡ Bolt: Consolidated 5 list traversals into a single O(N) loop to compute member stats.
    // This significantly reduces redundant calculations of `getStatus(now)`.
    int activeCount = 0;
    int expiringCount = 0;
    int expiredCount = 0;
    int totalRevenue = 0;
    final expiredMemberNames = <String>[];
    final expiringMemberNames = <String>[];
    final dueMembers = <MemberSnapshot>[];

    for (final m in members) {
      totalRevenue += m.totalPaid;

      final days = m.getDaysRemaining(now);
      if (days >= 0 && days <= 3) {
        dueMembers.add(m);
      }

      MemberStatus status;
      if (m.expiryDate == null) {
        status = MemberStatus.pending;
      } else if (days < 0) {
        status = MemberStatus.expired;
      } else if (days <= 7) {
        status = MemberStatus.expiring;
      } else {
        status = MemberStatus.active;
      }

      switch (status) {
        case MemberStatus.active:
          activeCount++;
          break;
        case MemberStatus.expiring:
          expiringCount++;
          if (expiringMemberNames.length < 3) expiringMemberNames.add(m.name);
          break;
        case MemberStatus.expired:
          expiredCount++;
          if (expiredMemberNames.length < 3) expiredMemberNames.add(m.name);
          break;
        case MemberStatus.pending:
          break; // Optional: handle pending members if needed
      }
    }
    
    final expiredMembers = expiredMemberNames.join(', ');
    final expiringMembers = expiringMemberNames.join(', ');

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: StatusBarWrapper(
          child: RefreshIndicator(
            onRefresh: () async {
              // Future: cloud sync
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(auth, unsyncedCount, tier2Status, syncState)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatsGrid(members.length, activeCount, expiringCount, expiredCount),
                        const SizedBox(height: 20),
                        MemberHealthDonut(
                          active: activeCount,
                          expiring: expiringCount,
                          expired: expiredCount,
                        ),
                        const SizedBox(height: 24),
                        _buildSyncDebtBanner(unsyncedCount, syncState),
                        if (expiredCount > 0)
                          AlertBanner(
                            title: '$expiredCount memberships expired',
                            subtitle: '$expiredMembers${expiredCount > 3 ? " +${expiredCount - 3}" : ""}',
                            isError: true,
                          ),
                        if (expiringCount > 0)
                          Padding(
                            padding: EdgeInsets.only(top: expiredCount > 0 ? 8 : 0),
                            child: AlertBanner(
                              title: '$expiringCount expiring in 7 days',
                              subtitle: '$expiringMembers${expiringCount > 3 ? " +${expiringCount - 3}" : ""}',
                              isError: false,
                            ),
                          ),
                        _buildSectionHeader(context, 'DUE TODAY', 'Show all'),
                        _buildDueList(dueMembers, now),
                        const SizedBox(height: 32),
                        _buildSectionHeader(context, 'REVENUE THIS MONTH', null),
                        _buildRevenueCard(totalRevenue),
                        const SizedBox(height: 100), // Space for bottom nav or FAB
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

  Widget _buildHeader(AuthState auth, int unsyncedCount, Tier2Status tier2Status, SyncWorkerState syncState) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 20, 14, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${GreetingFormatter.greeting()},'.toUpperCase(),
                style: AppTextStyles.sectionTitle.copyWith(fontSize: 8, letterSpacing: 1.5, color: AppColors.textMuted),
              ),
              const SizedBox(height: 4),
              Text(
                auth.owner?.gymName ?? 'IRONBOOK GM',
                style: AppTextStyles.cardTitle.copyWith(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 2),
              Text(
                DateFormatter.format(DateTime.now()).toUpperCase(),
                style: AppTextStyles.bodySmall.copyWith(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 1.0),
              ),
              const SizedBox(height: 8),
              _buildSyncBadge(unsyncedCount, tier2Status, syncState),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.elevation4,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(8),
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.contain,
                errorBuilder: (c, e, s) => const Icon(Icons.fitness_center_rounded, size: 24, color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncBadge(int count, Tier2Status status, SyncWorkerState syncState) {
    if (count == 0 && status != Tier2Status.degraded && syncState.status == SyncWorkerStatus.idle) {
      if (syncState.lastSuccessAt == null) return const SizedBox.shrink();
      
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          'LAST SECURED: ${syncState.lastSuccessAt!.hour}:${syncState.lastSuccessAt!.minute.toString().padLeft(2, "0")}',
          style: AppTextStyles.sectionTitle.copyWith(fontSize: 6, letterSpacing: 0.5, color: AppColors.textMuted),
        ),
      );
    }

    final isSyncing = syncState.status == SyncWorkerStatus.syncing || count > 0;
    final isFailed = syncState.status == SyncWorkerStatus.failed;


    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TweenAnimationBuilder<double>(
          duration: const Duration(seconds: 1),
          tween: Tween(begin: 0.5, end: 1.0),
          curve: Curves.easeInOut,
          onEnd: () {}, 
          builder: (context, value, child) {
            return Opacity(
              opacity: isSyncing ? value : 1.0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isFailed ? AppColors.expired.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isFailed ? AppColors.expired.withValues(alpha: 0.2) : AppColors.primary.withValues(alpha: 0.2),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isFailed ? Icons.sync_problem_rounded : (isSyncing ? Icons.cloud_sync_rounded : Icons.cloud_done_rounded),
                      size: 10,
                      color: isFailed ? AppColors.expired : AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isFailed ? 'SYNC ERROR' : (isSyncing ? '$count ITEM(S) SECURING' : 'DATA SECURED'),
                      style: AppTextStyles.sectionTitle.copyWith(
                        fontSize: 7,
                        letterSpacing: 0.5,
                        color: isFailed ? AppColors.expired : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        if (syncState.lastSuccessAt != null && !isSyncing)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              '${syncState.lastSuccessAt!.hour}:${syncState.lastSuccessAt!.minute.toString().padLeft(2, "0")}',
              style: AppTextStyles.sectionTitle.copyWith(fontSize: 6, color: AppColors.textMuted),
            ),
          ),
      ],
    );
  }

  Widget _buildStatsGrid(int total, int active, int expiring, int expired) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.8,
        children: [
          StatsCard(value: total.toString(), label: 'Total Members', isPrimary: true),
          StatsCard(value: active.toString(), label: 'Active', valueColor: AppColors.green),
          StatsCard(value: expiring.toString(), label: 'Expiring Soon', valueColor: AppColors.amber),
          StatsCard(value: expired.toString(), label: 'Expired', valueColor: AppColors.red),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, String? action) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 32, 0, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTextStyles.sectionTitle.copyWith(fontSize: 9, letterSpacing: 2.0),
          ),
          if (action != null)
            GestureDetector(
              onTap: () => context.go('/gym'),
              child: Row(
                children: [
                  Text(
                    action.toUpperCase(),
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.primary),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 8, color: AppColors.primary),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDueList(List<MemberSnapshot> due, DateTime now) {
    if (due.isEmpty) {
      return Container(
        height: 80,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.elevation1,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Text('NO TASKS DUE TODAY', style: AppTextStyles.bodySmall.copyWith(fontSize: 9, letterSpacing: 1.0, color: AppColors.textMuted)),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.elevation1,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: List.generate(due.length, (index) {
          final m = due[index];
          final days = m.getDaysRemaining(now);
          final status = m.getStatus(now);
          final color = status == MemberStatus.expired ? AppColors.expired : (status == MemberStatus.expiring ? AppColors.expiring : AppColors.active);

          return MemberRow(
            name: m.name,
            initials: m.name.isNotEmpty ? m.name.substring(0, 1).toUpperCase() : '?',
            subtitle: '${m.planName ?? "N/A"} · ₹${m.totalPaid.toInt()}',
            daysLeft: days.toString(),
            statusColor: color,
          );
        }),
      ),
    );
  }

  Widget _buildRevenueCard(int totalRevenue) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.elevation2,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ESTIMATED REVENUE'.toUpperCase(),
                style: AppTextStyles.sectionTitle.copyWith(fontSize: 8, letterSpacing: 1.5, color: AppColors.textMuted),
              ),
              const SizedBox(height: 6),
              Text(
                '₹${(totalRevenue / 1).toInt()}', // Assuming totalPaid is already scaled or handles division properly
                style: AppTextStyles.cardTitle.copyWith(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.primary),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.trending_up_rounded, size: 12, color: AppColors.active),
                  const SizedBox(width: 4),
                  Text(
                    '12% increase from last month',
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 9, color: AppColors.active, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
          _buildMiniBars(),
        ],
      ),
    );
  }

  Widget _buildMiniBars() {
    final heights = [0.55, 0.65, 0.45, 0.8, 0.6, 0.85, 1.0];
    return SizedBox(
      height: 36,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(heights.length, (index) {
          final isLast = index == heights.length - 1;
          return Container(
            width: 6,
            height: 36 * heights[index],
            margin: const EdgeInsets.only(left: 3),
            decoration: BoxDecoration(
              color: isLast ? AppColors.orange : AppColors.bg4,
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSyncDebtBanner(int count, SyncWorkerState state) {
    if (count < 10 && state.status != SyncWorkerStatus.failed) return const SizedBox.shrink();

    final isHighDebt = count > 20;
    final isError = state.status == SyncWorkerStatus.failed;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AlertBanner(
        title: isError ? 'SYNC ENGINE ERROR' : 'PENDING SYNC DEBT',
        subtitle: isError 
            ? 'Recent changes are not secured in the cloud. Check connection.' 
            : 'Warning: $count items unsynced. Do NOT uninstall the app.',
        isError: isHighDebt || isError,
      ),
    );
  }
}









