import 'package:flutter_test/flutter_test.dart';
import 'package:ironbook_gm/core/utils/subscription_duration_helper.dart';

void main() {
  group('SubscriptionDurationHelper', () {
    test('fixed_28: 1 month = 28 days', () {
      final start = DateTime(2025, 5, 9);
      final end = SubscriptionDurationHelper.calculateEndDate(
        startDate: start, durationMonths: 1, mode: SubscriptionMode.fixed28,
      );
      expect(end, DateTime(2025, 6, 6));
    });

    test('fixed_30: 1 month = 30 days', () {
      final start = DateTime(2025, 5, 9);
      final end = SubscriptionDurationHelper.calculateEndDate(
        startDate: start, durationMonths: 1, mode: SubscriptionMode.fixed30,
      );
      expect(end, DateTime(2025, 6, 8));
    });

    test('calendar_month: paid 9th May → expires 9th June', () {
      final start = DateTime(2025, 5, 9);
      final end = SubscriptionDurationHelper.calculateEndDate(
        startDate: start, durationMonths: 1, mode: SubscriptionMode.calendarMonth,
      );
      expect(end, DateTime(2025, 6, 9));
    });

    test('calendar_month: handles month-end (Jan 31 → Feb 28)', () {
      final start = DateTime(2025, 1, 31);
      final end = SubscriptionDurationHelper.calculateEndDate(
        startDate: start, durationMonths: 1, mode: SubscriptionMode.calendarMonth,
      );
      expect(end, DateTime(2025, 2, 28));
    });

    test('calendar_month: 3-month plan from October 15', () {
      final start = DateTime(2025, 10, 15);
      final end = SubscriptionDurationHelper.calculateEndDate(
        startDate: start, durationMonths: 3, mode: SubscriptionMode.calendarMonth,
      );
      expect(end, DateTime(2026, 1, 15));
    });
  });
}
