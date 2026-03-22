import 'package:intl/intl.dart';

class Fmt {
  // ₹1,298 format
  static String currency(double amount) =>
    '₹${NumberFormat('#,##,###').format(amount)}';

  // "15 Jan 2024" format
  static String date(DateTime d) => DateFormat('d MMM yyyy').format(d);

  // "Good morning 👋" greeting
  static String greeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good morning 👋';
    if (hour >= 12 && hour < 17) return 'Good afternoon ☀️';
    if (hour >= 17 && hour < 22) return 'Good evening 🌙';
    return 'Still grinding? 💪';
  }

  // Invoice number
  static String invoiceNumber(int sequence) =>
    'INV-${DateTime.now().year}-${sequence.toString().padLeft(4, '0')}';
}
