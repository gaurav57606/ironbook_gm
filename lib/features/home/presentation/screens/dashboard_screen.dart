import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/colors.dart';
import '../../../../providers/member_provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../data/local/models/member_snapshot_model.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/greeting_formatter.dart';
import 'package:go_router/go_router.dart';
import '../widgets/stats_card.dart';
import '../widgets/member_health_donut.dart';
import '../widgets/alert_banner.dart';
import '../widgets/member_row.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(membersProvider);
    final now = DateTime.now();
    final auth = ref.watch(authProvider);
    
    final activeCount = members.where((m) => m.getStatus(now) == MemberStatus.active).length;
    final expiringCount = members.where((m) => m.getStatus(now) == MemberStatus.expiring).length;
    final expiredCount = members.where((m) => m.getStatus(now) == MemberStatus.expired).length;
    
    final expiredMembers = members.where((m) => m.getStatus(now) == MemberStatus.expired).take(3).map((m) => m.name).join(', ');
    final expiringMembers = members.where((m) => m.getStatus(now) == MemberStatus.expiring).take(3).map((m) => m.name).join(', ');

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              // Future implementation: sync with cloud
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(auth),
                  _buildStatsGrid(members.length, activeCount, expiringCount, expiredCount),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: MemberHealthDonut(
                      active: activeCount,
                      expiring: expiringCount,
                      expired: expiredCount,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (expiredCount > 0)
                    AlertBanner(
                      title: '$expiredCount memberships expired',
                      subtitle: '$expiredMembers${expiredCount > 3 ? " +${expiredCount - 3}" : ""}',
                      isError: true,
                    ),
                  if (expiringCount > 0)
                    AlertBanner(
                      title: '$expiringCount expiring in 7 days',
                      subtitle: '$expiringMembers${expiringCount > 3 ? " +${expiringCount - 3}" : ""}',
                      isError: false,
                    ),
                  _buildSectionHeader(context, 'Due Today', 'See all'),
                  _buildDueList(members, now),
                  _buildSectionHeader(context, 'This Month', null),
                  _buildRevenueCard(members),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(AuthState auth) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            GreetingFormatter.greeting(),
            style: const TextStyle(fontSize: 11, color: AppColors.text2),
          ),
          Text(
            auth.owner?.gymName ?? 'Raj\'s Fitness',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text),
          ),
          Text(
            DateFormatter.format(DateTime.now()),
            style: const TextStyle(fontSize: 10, color: AppColors.text3),
          ),
        ],
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: AppColors.text2,
              letterSpacing: 0.5,
            ),
          ),
          if (action != null)
            GestureDetector(
              onTap: () => context.go('/members'),
              child: Text(
                action,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDueList(List<MemberSnapshot> members, DateTime now) {
    final due = members.where((m) {
      final days = m.getDaysRemaining(now);
      return days >= 0 && days <= 3;
    }).toList();

    if (due.isEmpty) {
      return Container(
        height: 60,
        alignment: Alignment.center,
        child: const Text('Nothing due today', style: TextStyle(fontSize: 10, color: AppColors.text3)),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.bg3,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: List.generate(due.length, (index) {
          final m = due[index];
          final days = m.getDaysRemaining(now);
          final status = m.getStatus(now);
          final color = status == MemberStatus.expired ? AppColors.red : (status == MemberStatus.expiring ? AppColors.amber : AppColors.green);

          return MemberRow(
            name: m.name,
            initials: m.name.isNotEmpty ? m.name.substring(0, 1).toUpperCase() : '?',
            subtitle: '${m.planName ?? "N/A"} · ${CurrencyFormatter.format(m.totalPaid.toDouble())}',
            daysLeft: days.toString(),
            statusColor: color,
          );
        }),
      ),
    );
  }

  Widget _buildRevenueCard(List<MemberSnapshot> members) {
    final totalRevenue = members.fold<int>(0, (sum, m) => sum + m.totalPaid);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg3,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Revenue'.toUpperCase(),
                style: const TextStyle(
                  fontSize: 9,
                  color: AppColors.text2,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                CurrencyFormatter.format(totalRevenue / 100.0), // Assuming totalPaid is in paise
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                '↑ 12% vs last month',
                style: TextStyle(
                  fontSize: 9,
                  color: AppColors.green,
                ),
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
}
