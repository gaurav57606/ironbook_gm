import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:ironbook_gm/core/services/csv_export_service.dart';
import 'package:ironbook_gm/core/data/local/models/member_snapshot_model.dart';
import 'package:ironbook_gm/core/data/local/models/payment_model.dart';
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
    test('generateMembersCsv with empty list produces only header', () {
      final csv = service.generateMembersCsv([]);
      final lines = const LineSplitter().convert(csv).where((l) => l.isNotEmpty).toList();

      expect(lines.length, 1); // Only Header
      expect(lines[0], 'Member ID,Name,Phone,Join Date,Plan Name,Expiry Date,Total Paid (₹),Status,Last Check-In,Archived');
    });

    test('generateMembersCsv handles null optional fields with fallbacks', () {
      final members = [
        MemberSnapshot(
          memberId: 'M_NULL',
          name: 'Null Test',
          joinDate: DateTime(2024, 1, 1),
          phone: null,
          planName: null,
          expiryDate: null,
          lastCheckIn: null,
          totalPaid: 0,
          archived: false,
        ),
      ];

      final csv = service.generateMembersCsv(members);
      final lines = const LineSplitter().convert(csv).where((l) => l.isNotEmpty).toList();
      final fields = lines[1].split(',');

      // 'Member ID', 'Name', 'Phone', 'Join Date', 'Plan Name', 'Expiry Date', 'Total Paid (₹)', 'Status', 'Last Check-In', 'Archived'
      expect(fields[0], 'M_NULL');
      expect(fields[1], 'Null Test');
      expect(fields[2], ''); // Phone fallback
      expect(fields[4], 'None'); // Plan Name fallback
      expect(fields[5], 'N/A'); // Expiry Date fallback
      expect(fields[6], '0.00'); // Total Paid
      expect(fields[8], 'Never'); // Last Check-In fallback
      expect(fields[9], 'No'); // Archived
    });

    test('generateMembersCsv formats archived status and currency correctly', () {
      final members = [
        MemberSnapshot(
          memberId: 'M_ARCHIVED',
          name: 'Archived User',
          joinDate: DateTime(2024, 1, 1),
          totalPaid: 123456, // ₹1234.56
          archived: true,
        ),
      ];

      final csv = service.generateMembersCsv(members);
      final lines = const LineSplitter().convert(csv).where((l) => l.isNotEmpty).toList();
      final fields = lines[1].split(',');

      expect(fields[6], '1234.56');
      expect(fields[9], 'Yes');
    });

    test('generateMembersCsv handles multiple members correctly', () {
      final members = [
        MemberSnapshot(memberId: 'M1', name: 'User 1', joinDate: DateTime(2024, 1, 1)),
        MemberSnapshot(memberId: 'M2', name: 'User 2', joinDate: DateTime(2024, 1, 1)),
        MemberSnapshot(memberId: 'M3', name: 'User 3', joinDate: DateTime(2024, 1, 1)),
      ];

      final csv = service.generateMembersCsv(members);
      final lines = const LineSplitter().convert(csv).where((l) => l.isNotEmpty).toList();

      expect(lines.length, 4); // Header + 3 Rows
      expect(lines[1], contains('M1,User 1'));
      expect(lines[2], contains('M2,User 2'));
      expect(lines[3], contains('M3,User 3'));
    });

    test('generateMembersCsv produces correct header and row count (original test)', () {
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
      final lines = const LineSplitter().convert(csv).where((l) => l.isNotEmpty).toList();
      
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

      final csv = service.generatePaymentsCsv(payments);
      final lines = const LineSplitter().convert(csv).where((l) => l.isNotEmpty).toList();
      
      expect(lines.length, 2); // Header + 1 Row
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
