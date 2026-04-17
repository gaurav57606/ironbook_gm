import 'package:flutter_test/flutter_test.dart';
import 'package:ironbook_gm/core/services/csv_export_service.dart';
import 'package:ironbook_gm/data/local/models/member_snapshot_model.dart';
import 'package:ironbook_gm/data/local/models/payment_model.dart';
import 'package:mocktail/mocktail.dart';

class MockCsvExportService extends Mock implements CsvExportService {}

// A spy that overrides only saveAndShareString
class CsvExportServiceSpy extends CsvExportService {
  String? lastCsv;
  String? lastFileName;
  int callCount = 0;

  @override
  Future<void> saveAndShareString(String csvString, String fileNamePrefix) async {
    lastCsv = csvString;
    lastFileName = fileNamePrefix;
    callCount++;
  }
}

void main() {
  late CsvExportService service;

  setUp(() {
    service = CsvExportService();
  });

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

      final csv = service.generateMembersCsv(members);
      final lines = csv.split('\r\n'); // csv package uses \r\n by default
      
      expect(lines.length, 3); // Header + 1 Row + Empty line at end
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

      final csv = service.generatePaymentsCsv(payments);
      final lines = csv.split('\r\n');
      
      expect(lines.length, 3); // Header + 1 Row + Empty line at end
      expect(lines[0], contains('Invoice #,Date,Member ID'));
      expect(lines[1], contains('INV-001,2024-01-01,M1,Gold Plan,5000.00'));
    });

    test('exportAllData orchestrates both exports', () async {
      final spy = CsvExportServiceSpy();
      final members = [
        MemberSnapshot(
          memberId: 'M1',
          name: 'Ravi',
          joinDate: DateTime(2024, 1, 1),
          totalPaid: 1000,
          archived: false,
        ),
      ];
      final payments = [
        Payment(
          id: 'P1',
          memberId: 'M1',
          date: DateTime(2024, 1, 1),
          amount: 1000.0,
          method: 'Cash',
          planId: 'PL1',
          planName: 'Basic',
          components: [],
          invoiceNumber: 'INV-1',
          subtotal: 1000.0,
          gstAmount: 0,
          gstRate: 0,
          durationMonths: 1,
        ),
      ];

      await spy.exportAllData(members: members, payments: payments);

      expect(spy.callCount, 2);
      // It should have called saveAndShareString twice, last one being payments
      expect(spy.lastFileName, contains('payments'));
      expect(spy.lastCsv, contains('INV-1'));
    });

    test('exportMembers calls saveAndShareString with correct prefix', () async {
      final spy = CsvExportServiceSpy();
      await spy.exportMembers([]);

      expect(spy.callCount, 1);
      expect(spy.lastFileName, 'ironbook_members');
      expect(spy.lastCsv, contains('Member ID,Name'));
    });

    test('exportPayments calls saveAndShareString with correct prefix', () async {
      final spy = CsvExportServiceSpy();
      await spy.exportPayments([]);

      expect(spy.callCount, 1);
      expect(spy.lastFileName, 'ironbook_payments');
      expect(spy.lastCsv, contains('Invoice #,Date'));
    });
  });
}
