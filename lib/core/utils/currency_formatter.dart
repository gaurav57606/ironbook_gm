import 'package:intl/intl.dart';

class CurrencyFormatter {
  // ₹1,298 format
  static String format(double amount) =>
    '₹${NumberFormat('#,##,###').format(amount)}';
}
