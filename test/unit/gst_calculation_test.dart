import 'package:flutter_test/flutter_test.dart';

// We extract the logic from MemberNotifier to test it in isolation
int calculateGstPaise(int subtotalPaise, double gstRate) {
  return (subtotalPaise * gstRate) ~/ 100;
}

void main() {
  group('GST Calculation Logic (TC-UNIT-02)', () {
    test('Should calculate 18% GST correctly for round numbers', () {
      const subtotal = 100000; // 1000.00 Rs
      const gstRate = 18.0;
      final gst = calculateGstPaise(subtotal, gstRate);
      
      expect(gst, 18000); // 180.00 Rs
      expect(subtotal + gst, 118000); // 1180.00 Rs
    });

    test('Should handle fractional GST rates (e.g. 18.5%)', () {
      const subtotal = 100000; // 1000.00 Rs
      const gstRate = 18.5;
      final gst = calculateGstPaise(subtotal, gstRate);
      
      expect(gst, 18500); // 185.00 Rs
    });

    test('Should handle paise level precision correctly', () {
      const subtotal = 100050; // 1000.50 Rs
      const gstRate = 18.0;
      final gst = calculateGstPaise(subtotal, gstRate);
      
      // 100050 * 0.18 = 18009.0
      expect(gst, 18009); // 180.09 Rs
    });

    test('Should truncate sub-paise remainders (Standard Financial Truncation)', () {
      const subtotal = 100049; // 1000.49 Rs
      const gstRate = 18.0;
      final gst = calculateGstPaise(subtotal, gstRate);
      
      // 100049 * 0.18 = 18008.82
      // Logic uses ~/ 100 which truncates to 18008
      expect(gst, 18008);
    });

    test('Should handle zero subtotal', () {
      expect(calculateGstPaise(0, 18.0), 0);
    });

    test('Should handle zero GST rate', () {
      expect(calculateGstPaise(100000, 0.0), 0);
    });
  });
}
