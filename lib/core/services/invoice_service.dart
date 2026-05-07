import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:ironbook_gm/core/data/repositories/sequence_repository.dart';
import 'package:ironbook_gm/shared/utils/clock.dart';
import 'package:ironbook_gm/core/data/local/models/member_snapshot_model.dart';
import 'package:ironbook_gm/core/data/local/models/plan_model.dart';
import 'package:ironbook_gm/core/data/local/models/payment_model.dart';
import 'package:ironbook_gm/core/data/local/models/owner_profile_model.dart';

abstract class IInvoiceService {
  Future<String> next();
  Future<void> reset(int year);
}

class InvoiceService implements IInvoiceService {
  final ISequenceRepository _sequenceRepo;
  final IClock _clock;

  InvoiceService(this._sequenceRepo, this._clock);

  @override
  Future<String> next() async {
    final now = _clock.now;
    final prefix = 'INV-${now.year}-';
    return await _sequenceRepo.getNextInvoiceNumber(prefix);
  }

  @override
  Future<void> reset(int year) async {
    final prefix = 'INV-$year-';
    await _sequenceRepo.reset(prefix);
  }

  static Future<void> generateAndShare({
    required MemberSnapshot member,
    required Plan plan,
    required Payment payment,
    required OwnerProfile owner,
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
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.orange900,
                          ),
                        ),
                        pw.SizedBox(height: 4),
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
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey800,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text('No: ${payment.invoiceNumber}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        pw.Text('Date: $dateStr', style: const pw.TextStyle(fontSize: 9)),
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
                          pw.Text('BILL TO', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                          pw.SizedBox(height: 4),
                          pw.Text(member.name, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                          if (member.phone != null)
                             pw.Text(member.phone!, style: const pw.TextStyle(fontSize: 9)),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text('PLAN DETAILS', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                          pw.SizedBox(height: 4),
                          pw.Text(payment.planName, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                          pw.Text('${payment.durationMonths} Month(s) Membership', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 30),

                // Table Header
                pw.Container(
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey800,
                    borderRadius: pw.BorderRadius.vertical(top: pw.Radius.circular(4)),
                  ),
                  padding: const pw.EdgeInsets.all(10),
                  child: pw.Row(
                    children: [
                      pw.Expanded(child: pw.Text('DESCRIPTION', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9))),
                      pw.Container(width: 80, child: pw.Text('AMOUNT', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9), textAlign: pw.TextAlign.right)),
                    ],
                  ),
                ),

                // Items
                _buildItemRow(payment.planName, payment.subtotal),
                ...payment.components.map((c) => _buildItemRow(c.name, c.price)),

                pw.Divider(thickness: 0.5, color: PdfColors.grey400),

                // Summary
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.SizedBox(height: 10),
                        _buildTotalRow('Subtotal', payment.subtotal.toStringAsFixed(2)),
                        _buildTotalRow('GST (${(payment.gstRate * 100).toInt()}%)', payment.gstAmount.toStringAsFixed(2)),
                        pw.SizedBox(height: 10),
                        pw.Container(
                          width: 160,
                          padding: const pw.EdgeInsets.all(10),
                          decoration: const pw.BoxDecoration(
                            color: PdfColors.grey100,
                            borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                          ),
                          child: pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('TOTAL PAID', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                              pw.Text('INR ${payment.amount.toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.orange900)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                pw.Spacer(),

                // Footer
                pw.Container(
                  padding: const pw.EdgeInsets.all(15),
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
                          pw.Text('PAYMENT INFORMATION', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                          pw.SizedBox(height: 4),
                          pw.Text('Method: ${payment.method}', style: const pw.TextStyle(fontSize: 8)),
                          if (payment.reference != null)
                             pw.Text('Ref: ${payment.reference}', style: const pw.TextStyle(fontSize: 8)),
                          if (owner.bankName != null && owner.bankName!.isNotEmpty) ...[
                            pw.SizedBox(height: 2),
                            pw.Text('Bank: ${owner.bankName}', style: const pw.TextStyle(fontSize: 7)),
                            pw.Text('A/C: ${owner.accountNumber}', style: const pw.TextStyle(fontSize: 7)),
                            pw.Text('IFSC: ${owner.ifsc}', style: const pw.TextStyle(fontSize: 7)),
                          ],
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text('Thank you for choosing ${owner.gymName}!', style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700)),
                          pw.SizedBox(height: 4),
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

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'invoice_${payment.invoiceNumber}.pdf',
    );
  }

  static pw.Widget _buildItemRow(String description, double amount) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: pw.Row(
        children: [
          pw.Expanded(child: pw.Text(description, style: const pw.TextStyle(fontSize: 9))),
          pw.Container(width: 80, child: pw.Text('INR ${amount.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.right)),
        ],
      ),
    );
  }

  static pw.Widget _buildTotalRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text('$label: ', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
          pw.Container(width: 80, child: pw.Text('INR $value', style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.right)),
        ],
      ),
    );
  }
}

final invoiceServiceProvider = Provider<IInvoiceService>((ref) {
  final sequenceRepo = ref.watch(sequenceRepositoryProvider);
  final clock = ref.watch(clockProvider);
  return InvoiceService(sequenceRepo, clock);
});
