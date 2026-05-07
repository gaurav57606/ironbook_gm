import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../../../core/data/local/drift/outbox_database.dart';
import '../providers/billing_provider.dart';
import '../../../core/data/local/models/owner_profile_model.dart';

class InvoicePdfService {
  static Future<File> generateInvoice({
    required Payment payment,
    required OwnerProfile owner,
    required String memberName,
  }) async {
    final pdf = pw.Document();
    final dateStr = DateFormat('dd MMM yyyy').format(payment.date);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(40),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          owner.gymName.toUpperCase(),
                          style: pw.TextStyle(
                            fontSize: 26,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.orange900,
                          ),
                        ),
                        pw.SizedBox(height: 6),
                        pw.Text(owner.address, style: const pw.TextStyle(fontSize: 9)),
                        pw.Text('Phone: ${owner.phone}', style: const pw.TextStyle(fontSize: 9)),
                        if (owner.gstin != null && owner.gstin!.isNotEmpty)
                          pw.Text('GSTIN: ${owner.gstin}', style: const pw.TextStyle(fontSize: 9)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'INVOICE',
                          style: pw.TextStyle(
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey800,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text('No: ${payment.invoiceNumber}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                        pw.Text('Date: $dateStr', style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 30),
                pw.Divider(thickness: 1, color: PdfColors.grey400),
                pw.SizedBox(height: 20),

                // Bill To
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('BILL TO', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                          pw.SizedBox(height: 4),
                          pw.Text(memberName, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text('PLAN DETAILS', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                          pw.SizedBox(height: 4),
                          pw.Text(payment.planName, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                          pw.Text('${payment.durationMonths} Month(s) Membership', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 40),

                // Table Header
                pw.Container(
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey800,
                    borderRadius: pw.BorderRadius.vertical(top: pw.Radius.circular(4)),
                  ),
                  padding: const pw.EdgeInsets.all(12),
                  child: pw.Row(
                    children: [
                      pw.Expanded(child: pw.Text('DESCRIPTION', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10))),
                      pw.Container(width: 80, child: pw.Text('AMOUNT', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10), textAlign: pw.TextAlign.right)),
                    ],
                  ),
                ),

                // Main Plan Item
                _buildItemRow(payment.planName, payment.subtotal),

                // Components Items
                ...payment.components.map((c) => _buildItemRow(c.name, c.price)),

                pw.Divider(thickness: 0.5, color: PdfColors.grey400),

                // Summary
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.SizedBox(height: 20),
                        _buildTotalRow('Subtotal', payment.subtotal.toStringAsFixed(2)),
                        _buildTotalRow('GST (${(payment.gstRate * 100).toInt()}%)', payment.gstAmount.toStringAsFixed(2)),
                        pw.SizedBox(height: 10),
                        pw.Container(
                          width: 180,
                          padding: const pw.EdgeInsets.all(12),
                          decoration: const pw.BoxDecoration(
                            color: PdfColors.grey100,
                            borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                          ),
                          child: pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('TOTAL PAID', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                              pw.Text('INR ${payment.amount.toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.orange900)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                pw.Spacer(),

                // Footer / Bank Details
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey50,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('PAYMENT INFORMATION', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                          pw.SizedBox(height: 6),
                          pw.Text('Method: ${payment.method}', style: const pw.TextStyle(fontSize: 8)),
                          if (owner.bankName != null && owner.bankName!.isNotEmpty) ...[
                            pw.SizedBox(height: 4),
                            pw.Text('Bank: ${owner.bankName}', style: const pw.TextStyle(fontSize: 8)),
                            pw.Text('A/C: ${owner.accountNumber}', style: const pw.TextStyle(fontSize: 8)),
                            pw.Text('IFSC: ${owner.ifsc}', style: const pw.TextStyle(fontSize: 8)),
                          ],
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text('Thank you for choosing ${owner.gymName}!', style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700)),
                          pw.SizedBox(height: 6),
                          pw.Text('This is a computer generated invoice.', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey500)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final fileName = "invoice_${payment.invoiceNumber}_${DateTime.now().millisecondsSinceEpoch}.pdf";
    final file = File("${output.path}/$fileName");
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static pw.Widget _buildItemRow(String description, double amount) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: pw.Row(
        children: [
          pw.Expanded(child: pw.Text(description, style: const pw.TextStyle(fontSize: 10))),
          pw.Container(width: 80, child: pw.Text('INR ${amount.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.right)),
        ],
      ),
    );
  }

  static pw.Widget _buildTotalRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text('$label: ', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.Container(width: 80, child: pw.Text('INR $value', style: const pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.right)),
        ],
      ),
    );
  }

  /// Clean up temporary files older than 1 hour to prevent storage leaks.
  static Future<void> cleanup() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final entities = await tempDir.list().toList();
      final now = DateTime.now();
      
      for (var entity in entities) {
        if (entity is File && entity.path.contains('invoice_') && entity.path.endsWith('.pdf')) {
          final stat = await entity.stat();
          if (now.difference(stat.modified).inHours >= 1) {
            await entity.delete();
          }
        }
      }
    } catch (e) {
      // Silently fail cleanup
    }
  }
}
