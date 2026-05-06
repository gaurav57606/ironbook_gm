class AppDateUtils {
  /// Adds exactly [months] to the [date], handling month overflow correctly.
  /// (e.g., Jan 31 + 1 month = Feb 28/29).
  static DateTime addMonths(DateTime date, int months) {
    var year = date.year;
    var month = date.month + months;
    var day = date.day;

    while (month > 12) {
      year++;
      month -= 12;
    }
    while (month < 1) {
      year--;
      month += 12;
    }

    final daysInMonth = _getDaysInMonth(year, month);
    if (day > daysInMonth) {
      day = daysInMonth;
    }

    return DateTime(year, month, day, date.hour, date.minute, date.second, date.millisecond, date.microsecond);
  }

  static int _getDaysInMonth(int year, int month) {
    if (month == 2) {
      final isLeapYear = (year % 4 == 0) && (year % 100 != 0 || year % 400 == 0);
      return isLeapYear ? 29 : 28;
    }
    const days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    return days[month - 1];
  }
}







