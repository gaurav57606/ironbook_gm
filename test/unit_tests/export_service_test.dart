import 'package:flutter_test/flutter_test.dart';
import 'package:ironbook_gm/core/services/csv_export_service.dart';
import 'package:ironbook_gm/data/local/models/member_snapshot_model.dart';
import 'package:ironbook_gm/data/local/models/payment_model.dart';

void main() {
  group('CsvExportService Tests', () {
    test('generateMembersCsv produces correct header and row count', () {
      final members = [
        MemberSnapshot(
          memberId: 'M1',
          name: 'Ravi Kumar',
          joinDate: DateTime(2024, 1, 1),
          totalPaid: 500000, // ₹5000.00
          archived: false,
        ),
      ];

      final csv = CsvExportService.generateMembersCsv(members);
      final lines = csv.split('\n');
      
      expect(lines.length, 2); // Header + 1 Row
      expect(lines[0], contains('Member ID,Name,Phone,Join Date'));
      expect(lines[1], contains('M1,Ravi Kumar'));
      expect(lines[1], contains('5000.00'));
    });

    test('generatePaymentsCsv produces correct header and row count', () {
      final payments = [
        Payment(
          id: 'P1',
          memberId: 'M1',
          date: DateTime(2024, 1, 1),
          amount: 5000.0,
          method: 'UPI',
          planId: 'PLAN1',
          planName: 'Gold Plan',
          components: [],
          invoiceNumber: 'INV-001',
          subtotal: 4237.29,
          gstAmount: 762.71,
          gstRate: 0.18,
          durationMonths: 1,
        ),
      ];

      final csv = CsvExportService.generatePaymentsCsv(payments);
      final lines = csv.split('\n');
      
      expect(lines.length, 2); // Header + 1 Row
      expect(lines[0], contains('Invoice #,Date,Member ID'));
      expect(lines[1], contains('INV-001,2024-01-01,M1,Gold Plan,5000.00'));
    });
  });
}
