import 'package:flutter/material.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_shadows.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/app_section_header.dart';
import '../../../../../shared/widgets/app_button.dart';
import '../../../../../shared/widgets/app_bottom_nav.dart';
import '../../../../../shared/widgets/status_bar_wrapper.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/owner_provider.dart';
import '../../providers/billing_provider.dart';
import '../../../../core/providers/member_provider.dart';
import '../../../../core/data/local/drift/outbox_database.dart';
import '../../../../shared/utils/date_formatter.dart';
import 'package:collection/collection.dart';
import '../../services/invoice_pdf_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';

class InvoiceScreen extends ConsumerStatefulWidget {
  final String? memberId;
  const InvoiceScreen({super.key, this.memberId});

  @override
  ConsumerState<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends ConsumerState<InvoiceScreen> {
  @override
  void initState() {
    super.initState();
    // Maintain device hygiene by cleaning up old temporary invoices
    InvoicePdfService.cleanup();
  }

  bool _isProcessing = false;

  Future<void> _shareInvoice(Payment payment, String memberName) async {
    setState(() => _isProcessing = true);
    try {
      final owner = ref.read(ownerProvider);
      if (owner == null) return;
      
      final file = await InvoicePdfService.generateInvoice(
        payment: payment,
        owner: owner,
        memberName: memberName,
      );
      
      await Share.shareXFiles([XFile(file.path)], text: 'Invoice from ${owner.gymName}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing invoice: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _printInvoice(Payment payment, String memberName) async {
    setState(() => _isProcessing = true);
    try {
      final owner = ref.read(ownerProvider);
      if (owner == null) return;
      
      final file = await InvoicePdfService.generateInvoice(
        payment: payment,
        owner: owner,
        memberName: memberName,
      );
      
      await Printing.layoutPdf(onLayout: (_) => file.readAsBytes());
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentsAsync = ref.watch(allPaymentsProvider);
    final memberId = widget.memberId;
    
    Payment? payment;
    if (paymentsAsync is AsyncData<List<Payment>>) {
      final payments = paymentsAsync.value;
      if (memberId != null) {
        payment = payments.where((p) => p.memberId == memberId).firstOrNull;
      } else if (payments.isNotEmpty) {
        payment = payments.first;
      }
    }

    return StatusBarWrapper(
      child: Column(
        children: [
          _buildAppBar(context, payment),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 20),
              children: [
                if (payment == null)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Text('No recent invoices found.', style: TextStyle(color: AppColors.text2)),
                  ))
                else ...[
                  _buildInvoiceCard(payment),
                  const AppSectionHeader(title: 'Payment Method'),
                  _buildPaymentChips(payment.method),
                  AppSpacing.gapM,
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                    child: AppButton(
                      text: _isProcessing ? 'Processing...' : 'Share via WhatsApp',
                      icon: _isProcessing 
                        ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.share, size: 13, color: Colors.white),
                      onPressed: _isProcessing ? null : () {
                        final members = ref.read(membersProvider);
                        final memberName = members.firstWhereOrNull((m) => m.memberId == payment!.memberId)?.name ?? 'Member';
                        _shareInvoice(payment!, memberName);
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          AppBottomNavBar(
            currentIndex: 2,
            onTap: (index) {
              if (index == 2) return;
              if (index == 0) context.go('/dashboard');
              if (index == 1) context.go('/members');
              if (index == 3) context.push('/settings');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, Payment? payment) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding, vertical: AppSpacing.s),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.elevation2,
                borderRadius: AppRadius.radiusS,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.chevron_left, size: 18, color: AppColors.text),
            ),
          ),
          AppSpacing.gapS,
          const Expanded(
            child: Text(
              'Invoice',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text),
            ),
          ),
          _buildAppBarIcon(Icons.download_rounded, onTap: payment != null ? () {
            final members = ref.read(membersProvider);
            final memberName = members.firstWhereOrNull((m) => m.memberId == payment.memberId)?.name ?? 'Member';
            _printInvoice(payment, memberName); 
          } : null),
          AppSpacing.gapS,
          _buildAppBarIcon(Icons.print_rounded, onTap: payment != null ? () {
            final members = ref.read(membersProvider);
            final memberName = members.firstWhereOrNull((m) => m.memberId == payment.memberId)?.name ?? 'Member';
            _printInvoice(payment, memberName);
          } : null),
        ],
      ),
    );
  }

  Widget _buildAppBarIcon(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.elevation2,
          borderRadius: AppRadius.radiusS,
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 14, color: onTap != null ? AppColors.text : AppColors.text2),
      ),
    );
  }

  Widget _buildInvoiceCard(Payment payment) {
    // Fetch member name (we'd ideally have a memberProvider but for now we can infer from snapshot if available)
    // Or just trust the event history. For simplicity, we'll try to get it from members list.
    final members = ref.watch(membersProvider);
    final memberName = members.firstWhereOrNull((m) => m.memberId == payment.memberId)?.name ?? 'Member';

    final owner = ref.watch(ownerProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding, vertical: AppSpacing.s),
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1a1206), Color(0xFF2a1d0a)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.radiusL,
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.2)),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(owner?.gymName ?? 'IRONBOOK GM', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.orange)),
                  const SizedBox(height: 2),
                  Text(
                    '${owner?.address ?? "Update address in settings"}${owner?.gstin != null ? " · GSTIN ${owner!.gstin}" : ""}', 
                    style: const TextStyle(fontSize: 9, color: AppColors.text2),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('INVOICE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.orange)),
                  const SizedBox(height: 1),
                  Text(payment.invoiceNumber, style: const TextStyle(fontSize: 9, color: AppColors.text2)),
                ],
              ),
            ],
          ),
          const Divider(height: 20, color: AppColors.border),
          _buildInvoiceRow('Member', memberName),
          _buildInvoiceRow('Date', DateFormatter.formatShort(payment.date)),
          _buildInvoiceRow('Plan', payment.planName),
          const Divider(height: 20, color: AppColors.border),
          ...payment.components.map((c) => _buildInvoiceRow(c.name, '₹${c.price.toInt()}')),
          const Divider(height: 20, color: AppColors.border),
          _buildInvoiceRow('Subtotal', '₹${payment.subtotal.toStringAsFixed(2)}'),
          _buildInvoiceRow('GST @ ${(payment.gstRate * 100).toInt()}%', '₹${payment.gstAmount.toStringAsFixed(2)}'),
          _buildTotalRow('Total Paid', '₹${payment.amount.toInt()}'),
          if (owner?.bankName != null) ...[
            const Divider(height: 20, color: AppColors.border),
            Text(
              '${owner!.bankName} · A/C ${owner.accountNumber} · IFSC ${owner.ifsc}',
              style: const TextStyle(fontSize: 9, color: AppColors.text2),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInvoiceRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 9, color: AppColors.text2)),
          Text(value, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.text)),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.text)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.orange)),
        ],
      ),
    );
  }


  Widget _buildPaymentChips(String selectedMethod) {
    final payments = ['Cash', 'UPI', 'Card', 'Bank'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Wrap(
        spacing: 5,
        children: payments.map((method) {
          final isSelected = method == selectedMethod;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.orange.withValues(alpha: 0.1) : AppColors.elevation2,
              borderRadius: AppRadius.radiusS,
              border: Border.all(color: isSelected ? AppColors.orange : AppColors.border),
            ),
            child: Text(
              method,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.orange : AppColors.text2,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}









