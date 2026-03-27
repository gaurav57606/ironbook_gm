import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import '../data/local/models/member_snapshot_model.dart';
import '../data/local/models/plan_model.dart';
import '../data/local/models/payment_model.dart';
import '../data/local/models/owner_profile_model.dart';

class InvoiceService {
  static Future<void> generateAndShare({
    required MemberSnapshot member,
    required Plan plan,
    required Payment payment,
    required OwnerProfile owner,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(owner.gymName,
                style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                pw.Text('INVOICE', style: pw.TextStyle(fontSize: 14,
                  color: PdfColor.fromHex('#FF6B2B'))),
                pw.Text('#${payment.invoiceNumber}'),
              ]),
            ],
          ),
          pw.Text(owner.address),
          pw.Text('GSTIN: ${owner.gstin ?? "N/A"}'),
          pw.Divider(),

          // Member info
          _buildRow('Member', member.name),
          _buildRow('Phone', member.phone ?? 'N/A'),
          _buildRow('Date', _formatDate(payment.date)),
          _buildRow('Period', '${_formatDate(payment.date)} - ${_formatDate(member.expiryDate ?? payment.date.add(const Duration(days: 30)))}'),
          pw.Divider(),

          // Line items
          ...payment.components.map((c) => _buildRow(c.name, 'Rs.${c.price.toStringAsFixed(2)}')),
          pw.Divider(),
          _buildRow('Subtotal', 'Rs.${payment.subtotal.toStringAsFixed(2)}'),
          _buildRow('GST @ ${payment.gstRate}%', 'Rs.${payment.gstAmount.toStringAsFixed(2)}'),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Total Due', style: pw.TextStyle(fontSize: 16,
                fontWeight: pw.FontWeight.bold)),
              pw.Text('Rs.${payment.amount.toStringAsFixed(2)}',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#FF6B2B'))),
            ],
          ),
          pw.Divider(),
          pw.Text('Bank: ${owner.bankName ?? "N/A"} - A/C ${owner.accountNumber ?? "N/A"} - IFSC ${owner.ifsc ?? "N/A"}'),
        ],
      ),
    ));

    if (kIsWeb) {
      // PDF sharing/saving on web needs different approach (e.g. printing package or blob download)
      // For now, we'll just return as it's a mobile-first app
      return;
    }

    // Save & share
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/${payment.invoiceNumber}.pdf');
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Invoice ${payment.invoiceNumber} for ${member.name} - ${payment.amount.toStringAsFixed(0)}',
    );
  }

  static pw.Widget _buildRow(String label, String value) =>
    pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [pw.Text(label), pw.Text(value)]);

  static String _formatDate(DateTime d) =>
    '${d.day} ${['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][d.month-1]} ${d.year}';
}
