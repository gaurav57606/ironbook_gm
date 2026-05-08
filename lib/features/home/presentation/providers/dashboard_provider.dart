import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/member_provider.dart';
import '../../../../core/providers/payment_provider.dart';
import '../../../../core/data/local/models/member_snapshot_model.dart';
import '../../../../shared/utils/clock.dart';

class DashboardMemberStats {
  final int activeCount;
  final int expiringCount;
  final int expiredCount;
  final String expiredMembers;
  final String expiringMembers;
  final List<MemberSnapshot> dueMembers;

  DashboardMemberStats({
    required this.activeCount,
    required this.expiringCount,
    required this.expiredCount,
    required this.expiredMembers,
    required this.expiringMembers,
    required this.dueMembers,
  });
}

class DashboardRevenueStats {
  final double currentRevenue;
  final double trend;
  final List<double> dailyRevenue;

  DashboardRevenueStats({
    required this.currentRevenue,
    required this.trend,
    required this.dailyRevenue,
  });
}

final dashboardMemberStatsProvider = Provider<DashboardMemberStats>((ref) {
  final members = ref.watch(membersProvider);
  final now = ref.watch(clockProvider).now;

  int activeCount = 0;
  int expiringCount = 0;
  int expiredCount = 0;
  final expiredMemberNames = <String>[];
  final expiringMemberNames = <String>[];
  final dueMembers = <MemberSnapshot>[];

  for (final m in members) {
    final status = m.getStatus(now);
    final days = m.getDaysRemaining(now);

    if (days >= 0 && days <= 3) {
      dueMembers.add(m);
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
        break;
    }
  }

  return DashboardMemberStats(
    activeCount: activeCount,
    expiringCount: expiringCount,
    expiredCount: expiredCount,
    expiredMembers: expiredMemberNames.join(', '),
    expiringMembers: expiringMemberNames.join(', '),
    dueMembers: dueMembers,
  );
});

final dashboardRevenueProvider = Provider<DashboardRevenueStats>((ref) {
  final payments = ref.watch(paymentsProvider);
  final now = ref.watch(clockProvider).now;

  final currentMonth = now.month;
  final currentYear = now.year;
  final lastMonth = now.month == 1 ? 12 : now.month - 1;
  final lastMonthYear = now.month == 1 ? now.year - 1 : now.year;

  double currentRevenue = 0;
  double lastRevenue = 0;
  final dailyRevenue = List.filled(7, 0.0);

  for (final p in payments) {
    if (p.date.month == currentMonth && p.date.year == currentYear) {
      currentRevenue += p.amount;
    } else if (p.date.month == lastMonth && p.date.year == lastMonthYear) {
      lastRevenue += p.amount;
    }

    final diffDays = now.difference(p.date).inDays;
    if (diffDays >= 0 && diffDays < 7) {
      dailyRevenue[6 - diffDays] += p.amount;
    }
  }

  final double trend = lastRevenue > 0
      ? ((currentRevenue - lastRevenue) / lastRevenue) * 100
      : 0;

  return DashboardRevenueStats(
    currentRevenue: currentRevenue,
    trend: trend,
    dailyRevenue: dailyRevenue,
  );
});
