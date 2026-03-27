import 'package:intl/intl.dart';

class DateFormatter {
  // "15 Jan 2024" format
  static String format(DateTime d) => DateFormat('d MMM yyyy').format(d);

  // "Jan 2024" format
  static String formatShort(DateTime d) => DateFormat('MMM yyyy').format(d);
}
