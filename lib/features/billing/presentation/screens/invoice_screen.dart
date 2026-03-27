import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../core/widgets/status_bar_wrapper.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/payment_provider.dart';
import '../../../../providers/member_provider.dart';
import '../../../../data/local/models/payment_model.dart';
import '../../../../core/utils/date_formatter.dart';

class InvoiceScreen extends ConsumerStatefulWidget {
  final String? memberId;
  const InvoiceScreen({super.key, this.memberId});

  @override
  ConsumerState<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends ConsumerState<InvoiceScreen> {
  @override
  Widget build(BuildContext context) {
    final payments = ref.watch(paymentProvider);
    final memberId = widget.memberId;
    
    Payment? payment;
    if (memberId != null) {
      payment = ref.read(paymentProvider.notifier).getLatestForMember(memberId);
    } else if (payments.isNotEmpty) {
      payment = payments.first;
    }

    return StatusBarWrapper(
      child: Column(
        children: [
          _buildAppBar(context),
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
                  _buildSectionHeader('Payment Method'),
                  _buildPaymentChips(payment.method),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: AppButton(
                      text: 'Share via WhatsApp',
                      icon: const Icon(Icons.share, size: 13, color: Colors.white),
                      onPressed: () {},
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

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.bg3,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.chevron_left, size: 18, color: AppColors.text),
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Invoice',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text),
            ),
          ),
          _buildAppBarIcon(Icons.download_rounded),
          const SizedBox(width: 6),
          _buildAppBarIcon(Icons.print_rounded),
        ],
      ),
    );
  }

  Widget _buildAppBarIcon(IconData icon) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: AppColors.bg3,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Icon(icon, size: 14, color: AppColors.text),
    );
  }

  Widget _buildInvoiceCard(Payment payment) {
    // Fetch member name (we'd ideally have a memberProvider but for now we can infer from snapshot if available)
    // Or just trust the event history. For simplicity, we'll try to get it from members list.
    final members = ref.read(membersProvider);
    final memberName = members.where((m) => m.memberId == payment.memberId).firstOrNull?.name ?? 'Member';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1a1206), Color(0xFF2a1d0a)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Raj\'s Fitness', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.orange)),
                  SizedBox(height: 2),
                  Text('Sector 14, Gurugram · GSTIN 07ABC...', style: TextStyle(fontSize: 9, color: AppColors.text2)),
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
          const Divider(height: 20, color: AppColors.border),
          const Text(
            'HDFC · A/C 1234567890 · IFSC HDFC0001234',
            style: TextStyle(fontSize: 9, color: AppColors.text2),
          ),
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: AppColors.text2,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildPaymentChips(String selectedMethod) {
    final payments = ['Cash', 'UPI', 'Card', 'Bank'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Wrap(
        spacing: 5,
        children: payments.map((method) {
          final isSelected = method == selectedMethod;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.orange.withValues(alpha: 0.1) : AppColors.bg3,
              borderRadius: BorderRadius.circular(8),
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
