class AnalyticsSummary {
  final int totalMembers;
  final double totalRevenue;
  final double growthPercent;
  final double revenueGrowthPercent;
  final List<double> weeklyRevenue;
  final List<double> weeklyAttendance;
  final List<PlanPerformance> topPlans;

  AnalyticsSummary({
    required this.totalMembers,
    required this.totalRevenue,
    required this.growthPercent,
    required this.revenueGrowthPercent,
    required this.weeklyRevenue,
    required this.weeklyAttendance,
    required this.topPlans,
  });

  factory AnalyticsSummary.empty() => AnalyticsSummary(
    totalMembers: 0,
    totalRevenue: 0,
    growthPercent: 0,
    revenueGrowthPercent: 0,
    weeklyRevenue: List.filled(7, 0),
    weeklyAttendance: List.filled(7, 0),
    topPlans: [],
  );
}

class PlanPerformance {
  final String name;
  final double percentage; // 0.0 to 1.0 based on popularity

  PlanPerformance({required this.name, required this.percentage});
}
