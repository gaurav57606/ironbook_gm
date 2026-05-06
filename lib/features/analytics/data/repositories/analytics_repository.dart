import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/data/repositories/event_repository.dart';
import '../../../../core/data/local/models/domain_event_model.dart';
import '../models/analytics_summary.dart';

class AnalyticsRepository {
  final IEventRepository _eventRepo;

  AnalyticsRepository(this._eventRepo);

  Future<AnalyticsSummary> getSummary() async {
    final events = await _eventRepo.getAll();
    
    int totalMembers = 0;
    double totalRevenue = 0;
    Map<String, int> planUsage = {};
    List<double> weeklyRevenue = List.filled(7, 0);
    List<double> weeklyAttendance = List.filled(7, 0);

    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    for (final event in events) {
      switch (event.eventType) {
        case EventType.memberCreated:
          totalMembers++;
          break;
        case EventType.paymentRecorded:
        case EventType.paymentAdded:
          final amount = (event.payload['amount'] as num?)?.toDouble() ?? 0.0;
          totalRevenue += amount;
          
          if (event.deviceTimestamp.isAfter(sevenDaysAgo)) {
            final dayIndex = now.difference(event.deviceTimestamp).inDays;
            if (dayIndex >= 0 && dayIndex < 7) {
              weeklyRevenue[6 - dayIndex] += amount;
            }
          }
          break;
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
      growthPercent: 12.5, // Mocked growth for now, would need historical comparison
      revenueGrowthPercent: 8.2, // Mocked
      weeklyRevenue: weeklyRevenue,
      weeklyAttendance: weeklyAttendance,
      topPlans: topPlans,
    );
  }
}

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  final eventRepo = ref.watch(eventRepositoryProvider);
  return AnalyticsRepository(eventRepo);
});

final analyticsSummaryProvider = FutureProvider<AnalyticsSummary>((ref) {
  return ref.watch(analyticsRepositoryProvider).getSummary();
});
