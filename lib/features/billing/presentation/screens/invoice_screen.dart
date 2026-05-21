import 'package:flutter/material.dart';
import 'package:ironbook_gm/core/constants/app_colors.dart';
import 'package:ironbook_gm/core/constants/app_text_styles.dart';
import 'package:ironbook_gm/core/constants/app_spacing.dart';
import 'package:ironbook_gm/core/constants/app_radius.dart';
import 'package:ironbook_gm/core/constants/app_shadows.dart';
import 'package:ironbook_gm/shared/widgets/app_section_header.dart';
import 'package:ironbook_gm/shared/widgets/app_button.dart';
import 'package:ironbook_gm/shared/widgets/app_bottom_nav.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ironbook_gm/core/providers/owner_provider.dart';
import 'package:ironbook_gm/features/billing/providers/billing_provider.dart';
import 'package:ironbook_gm/core/providers/member_provider.dart';
import 'package:ironbook_gm/core/data/local/drift/outbox_database.dart';
import 'package:ironbook_gm/shared/utils/date_utils.dart';
import 'package:collection/collection.dart';
import 'package:ironbook_gm/features/billing/services/invoice_pdf_service.dart';
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

  Future<void> _downloadInvoice(Payment payment, String memberName) async {
    setState(() => _isProcessing = true);
    try {
      final owner = ref.read(ownerProvider);
      if (owner == null) return;
      
      final file = await InvoicePdfService.generateInvoice(
        payment: payment,
        owner: owner,
        memberName: memberName,
      );
      
      await Share.shareXFiles([XFile(file.path)]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error downloading invoice: $e')),
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
    final paymentsAsync = ref.watch(allPaymentsStreamProvider);
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

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        top: true,
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
                        text: _isProcessing ? 'Processing...' : 'Share Invoice',
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
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, Payment? payment) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding, vertical: AppSpacing.m),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.elevation2,
                borderRadius: AppRadius.radiusS,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.chevron_left, size: 20, color: AppColors.text),
            ),
          ),
          AppSpacing.gapS,
          Expanded(
            child: Text(
              'Invoice Summary',
              style: AppTextStyles.h3.copyWith(fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ),
          _buildAppBarIcon(Icons.download_rounded, onTap: payment != null ? () {
            final members = ref.read(membersProvider);
            final memberName = members.firstWhereOrNull((m) => m.memberId == payment.memberId)?.name ?? 'Member';
            _downloadInvoice(payment, memberName); 
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
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.elevation2,
          borderRadius: AppRadius.radiusS,
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 16, color: onTap != null ? AppColors.text : AppColors.textMuted),
      ),
    );
  }

  Widget _buildInvoiceCard(Payment payment) {
    final members = ref.watch(membersProvider);
    final memberName = members.firstWhereOrNull((m) => m.memberId == payment.memberId)?.name ?? 'Member';
    final owner = ref.watch(ownerProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding, vertical: AppSpacing.s),
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        gradient: AppColors.glassGradient,
        borderRadius: AppRadius.radiusXXL,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
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
                  Text(owner?.gymName ?? 'IRONBOOK GM', 
                      style: AppTextStyles.h3.copyWith(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.primary)),
                  const SizedBox(height: 4),
                  Text(
                    '${owner?.address ?? "Update address in settings"}${owner?.gstin != null ? " · GSTIN ${owner!.gstin}" : ""}', 
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 10, color: AppColors.textMuted),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('OFFICIAL RECEIPT', 
                      style: AppTextStyles.sectionTitle.copyWith(fontSize: 8, fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: 1.0)),
                  const SizedBox(height: 4),
                  Text(payment.invoiceNumber, 
                      style: AppTextStyles.bodySmall.copyWith(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(height: 1, color: AppColors.border),
          ),
          _buildInvoiceRow('MEMBER NAME', memberName),
          _buildInvoiceRow('BILLING DATE', AppDateUtils.formatShort(payment.date)),
          _buildInvoiceRow('PLAN TYPE', payment.planName),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(height: 1, color: AppColors.border),
          ),
          ...payment.components.map((c) => _buildInvoiceRow(c.name.toUpperCase(), '₹${c.price.toInt()}')),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(height: 1, color: AppColors.border),
          ),
          _buildInvoiceRow('SUBTOTAL', '₹${payment.subtotal.toStringAsFixed(2)}'),
          _buildInvoiceRow('TAX (GST ${(payment.gstRate * 100).toInt()}%)', '₹${payment.gstAmount.toStringAsFixed(2)}'),
          const SizedBox(height: 12),
          _buildTotalRow('TOTAL AMOUNT PAID', '₹${payment.amount.toInt()}'),
          if (owner?.bankName != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Divider(height: 1, color: AppColors.border),
            ),
            Text(
              '${owner!.bankName} · A/C ${owner.accountNumber} · IFSC ${owner.ifsc}',
              style: AppTextStyles.bodySmall.copyWith(fontSize: 10, color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInvoiceRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.sectionTitle.copyWith(fontSize: 9, color: AppColors.textMuted, letterSpacing: 0.5)),
          Text(value, style: AppTextStyles.body.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.text)),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: AppRadius.radiusM,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.h3.copyWith(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.text)),
          Text(value, style: AppTextStyles.h2.copyWith(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primary)),
        ],
      ),
    );
  }

  Widget _buildPaymentChips(String selectedMethod) {
    final payments = ['Cash', 'UPI', 'Card', 'Bank Transfer'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: payments.map((method) {
          final isSelected = method.toLowerCase().contains(selectedMethod.toLowerCase());
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.elevation2,
              borderRadius: AppRadius.radiusM,
              border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
            ),
            child: Text(
              method,
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}









