import 'dart:math';

enum SubscriptionMode {
  fixed28,
  fixed30,
  calendarMonth;

  static SubscriptionMode fromString(String value) {
    switch (value) {
      case 'fixed_28': return SubscriptionMode.fixed28;
      case 'fixed_30': return SubscriptionMode.fixed30;
      case 'calendar_month':
      default: return SubscriptionMode.calendarMonth;
    }
  }

  String toDbString() {
    switch (this) {
      case SubscriptionMode.fixed28: return 'fixed_28';
      case SubscriptionMode.fixed30: return 'fixed_30';
      case SubscriptionMode.calendarMonth: return 'calendar_month';
    }
  }
}

class SubscriptionDurationHelper {
  /// Returns the expiry date given a start date, plan duration in months,
  /// and the gym's subscription mode setting.
  static DateTime calculateEndDate({
    required DateTime startDate,
    required int durationMonths,
    required SubscriptionMode mode,
  }) {
    switch (mode) {
      case SubscriptionMode.fixed28:
        return startDate.add(Duration(days: 28 * durationMonths));
      case SubscriptionMode.fixed30:
        return startDate.add(Duration(days: 30 * durationMonths));
      case SubscriptionMode.calendarMonth:
        return _addCalendarMonths(startDate, durationMonths);
    }
  }

  static DateTime _addCalendarMonths(DateTime date, int months) {
    int totalMonths = date.month + months;
    int newYear = date.year + ((totalMonths - 1) ~/ 12);
    int newMonth = ((totalMonths - 1) % 12) + 1;
    int newDay = min(date.day, _daysInMonth(newYear, newMonth));
    return DateTime(newYear, newMonth, newDay, date.hour, date.minute, date.second);
  }

  static int _daysInMonth(int year, int month) {
    // Day 0 of next month = last day of this month
    return DateTime(year, month + 1, 0).day;
  }
}
