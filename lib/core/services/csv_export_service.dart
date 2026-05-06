import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:ironbook_gm/core/data/local/models/member_snapshot_model.dart';
import 'package:ironbook_gm/core/data/local/models/payment_model.dart';

final csvExportServiceProvider = Provider((ref) => CsvExportService());

class CsvExportService {
  Future<void> exportMembers(List<MemberSnapshot> members) async {
    final csvString = generateMembersCsv(members);
    await saveAndShareString(csvString, 'ironbook_members');
  }

  String generateMembersCsv(List<MemberSnapshot> members) {
    final List<List<dynamic>> rows = [];
    rows.add([
      'Member ID', 'Name', 'Phone', 'Join Date', 'Plan Name',
      'Expiry Date', 'Total Paid (₹)', 'Status', 'Last Check-In', 'Archived',
    ]);

    final dateFormat = DateFormat('yyyy-MM-dd');
    final dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm');
    final now = DateTime.now();

    for (final m in members) {
      rows.add([
        m.memberId,
        m.name,
        m.phone ?? '',
        dateFormat.format(m.joinDate),
        m.planName ?? 'None',
        m.expiryDate != null ? dateFormat.format(m.expiryDate!) : 'N/A',
        (m.totalPaid / 100).toStringAsFixed(2),
        m.getStatus(now).name,
        m.lastCheckIn != null ? dateTimeFormat.format(m.lastCheckIn!) : 'Never',
        m.archived ? 'Yes' : 'No',
      ]);
    }
    return const ListToCsvConverter().convert(rows);
  }

  Future<void> exportPayments(List<Payment> payments) async {
    final csvString = generatePaymentsCsv(payments);
    await saveAndShareString(csvString, 'ironbook_payments');
  }

  String generatePaymentsCsv(List<Payment> payments) {
    final List<List<dynamic>> rows = [];
    rows.add([
      'Invoice #', 'Date', 'Member ID', 'Plan', 'Amount (₹)',
      'Subtotal', 'GST', 'Method', 'Reference',
    ]);

    final dateFormat = DateFormat('yyyy-MM-dd');

    for (final p in payments) {
      rows.add([
        p.invoiceNumber,
        dateFormat.format(p.date),
        p.memberId,
        p.planName,
        p.amount.toStringAsFixed(2),
        p.subtotal.toStringAsFixed(2),
        p.gstAmount.toStringAsFixed(2),
        p.method,
        p.reference ?? '',
      ]);
    }
    return const ListToCsvConverter().convert(rows);
  }

  Future<void> exportAllData({
    required List<MemberSnapshot> members,
    required List<Payment> payments,
  }) async {
    // This could also be a ZIP of CSVs, but for now we share them sequentially 
    // or just call both. For DPDP compliance, a unified export is best.
    await exportMembers(members);
    await exportPayments(payments);
  }

  @visibleForTesting
  Future<void> saveAndShareString(String csvString, String fileNamePrefix) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/${fileNamePrefix}_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csvString);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'IronBook GM Data Export',
    );
  }
}









