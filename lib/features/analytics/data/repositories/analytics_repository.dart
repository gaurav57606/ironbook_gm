import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/data/repositories/event_repository.dart';
import '../../../../core/data/repositories/member_repository.dart';
import '../../../../core/data/repositories/payment_repository.dart';
import '../../../../core/data/local/models/domain_event_model.dart';
import '../models/analytics_summary.dart';
import '../../../../core/providers/member_provider.dart';
import '../../../../core/providers/payment_provider.dart';

class AnalyticsRepository {
  final IMemberRepository _memberRepo;
  final IPaymentRepository _paymentRepo;
  final IEventRepository _eventRepo;

  AnalyticsRepository(this._memberRepo, this._paymentRepo, this._eventRepo);

  Future<AnalyticsSummary> getSummary() async {
    final now = DateTime.now();
    
    // 1. Optimized Data Fetching (O(1) or O(indexed))
    final totalMembers = await _memberRepo.countActiveMembers();
    final totalRevenue = await _paymentRepo.getTotalRevenue();
    final weeklyRevenue = await _paymentRepo.getWeeklyRevenue(now);
    
    // 2. Specialized Plan Usage (We still use events for this as it's more accurate for historical assignment, 
    // but we could optimize this later by adding a plan_id to Members table if needed).
    final events = await _eventRepo.getEventsSince(now.subtract(const Duration(days: 60)));
    
    Map<String, int> planUsage = {};
    List<double> weeklyAttendance = List.filled(7, 0);
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    for (final event in events) {
      switch (event.eventType) {
        case EventType.planAssigned:
          final planName = event.payload['planName'] as String?;
          if (planName != null) {
            planUsage[planName] = (planUsage[planName] ?? 0) + 1;
          }
          break;
        case EventType.checkInRecorded:
          if (event.deviceTimestamp.isAfter(sevenDaysAgo)) {
            final dayIndex = now.difference(event.deviceTimestamp).inDays;
            if (dayIndex >= 0 && dayIndex < 7) {
              weeklyAttendance[6 - dayIndex] += 1;
            }
          }
          break;
        default:
          break;
      }
    }

    // ── Real Month-over-Month Revenue and Member Growth ──
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final lastMonthEnd = DateTime(now.year, now.month, 0, 23, 59, 59);
    final thisMonthStart = DateTime(now.year, now.month, 1);

    final lastMonthRevenue = await _paymentRepo.getRevenueBetween(lastMonthStart, lastMonthEnd);
    final thisMonthRevenue = await _paymentRepo.getRevenueBetween(thisMonthStart, now);

    final revenueGrowth = lastMonthRevenue == 0
        ? 0.0
        : ((thisMonthRevenue - lastMonthRevenue) / lastMonthRevenue * 100);

    final lastMonthMembers = await _memberRepo.countMembersJoinedBetween(lastMonthStart, lastMonthEnd);
    final thisMonthMembers = await _memberRepo.countMembersJoinedBetween(thisMonthStart, now);

    final memberGrowth = lastMonthMembers == 0
        ? 0.0
        : ((thisMonthMembers - lastMonthMembers) / lastMonthMembers * 100);

    final double revenueGrowthPercent = revenueGrowth;
    final double growthPercent = memberGrowth;

    // Calculate Top Plans
    final List<PlanPerformance> topPlans = [];
    if (planUsage.isNotEmpty) {
      final sortedPlans = planUsage.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      final maxUsage = sortedPlans.first.value.toDouble();
      for (var i = 0; i < sortedPlans.length && i < 3; i++) {
        topPlans.add(PlanPerformance(
          name: sortedPlans[i].key,
          percentage: sortedPlans[i].value / maxUsage,
        ));
      }
    }

    return AnalyticsSummary(
      totalMembers: totalMembers,
      totalRevenue: totalRevenue,
      growthPercent:
          double.parse(growthPercent.toStringAsFixed(1)),
      revenueGrowthPercent:
          double.parse(revenueGrowthPercent.toStringAsFixed(1)), 
      weeklyRevenue: weeklyRevenue,
      weeklyAttendance: weeklyAttendance,
      topPlans: topPlans,
    );
  }
}

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  final memberRepo = ref.watch(memberRepositoryProvider);
  final paymentRepo = ref.watch(paymentRepositoryProvider);
  final eventRepo = ref.watch(eventRepositoryProvider);
  return AnalyticsRepository(memberRepo, paymentRepo, eventRepo);
});

final analyticsSummaryProvider =
    FutureProvider.autoDispose<AnalyticsSummary>((ref) {
  // Watch live providers so analytics refresh whenever data changes
  ref.watch(membersProvider);     // re-compute when member list changes
  ref.watch(paymentsProvider);    // re-compute when payments change
  return ref.watch(analyticsRepositoryProvider).getSummary();
});
