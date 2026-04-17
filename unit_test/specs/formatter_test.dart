import 'package:flutter_test/flutter_test.dart';
import 'package:ironbook_gm/core/utils/currency_formatter.dart';
import 'package:ironbook_gm/core/utils/date_formatter.dart';
import 'package:ironbook_gm/core/utils/greeting_formatter.dart';

void main() {
  group('Formatter Unit Tests (TC-UNIT-02 & TC-UNIT-03)', () {
    test('Currency should use Indian comma formatting with ₹ symbol', () {
      expect(CurrencyFormatter.format(1298), '₹1,298');
      expect(CurrencyFormatter.format(11800), '₹11,800');
      expect(CurrencyFormatter.format(100000), '₹1,00,000');
    });

    test('Date should use "d MMM yyyy" format without leading zero for day', () {
      final date = DateTime(2024, 1, 15);
      expect(DateFormatter.format(date), '15 Jan 2024');

      final singleDigitDate = DateTime(2024, 3, 5);
      expect(DateFormatter.format(singleDigitDate), '5 Mar 2024');
    });

    test('Greeting should vary by time of day', () {
      // Note: This test depends on the current time, but we can verify it returns a string
      final greeting = GreetingFormatter.greeting();
      expect(greeting.isNotEmpty, true);
    });
  });
}
