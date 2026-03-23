import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/member_provider.dart';
import '../../../providers/payment_provider.dart';
import '../../../providers/owner_provider.dart';
import '../../../services/invoice_service.dart';
import '../../../data/local/models/plan_model.dart';

class InvoiceScreen extends ConsumerWidget {
  final String id; // This is the memberId
  const InvoiceScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(membersProvider);
    final member = members.where((m) => m.memberId == id).firstOrNull;
    final payment = ref.watch(latestPaymentForMemberProvider(id));
    final owner = ref.watch(ownerProvider);

    if (member == null || payment == null || owner == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Invoice')),
        body: const Center(child: Text('Invoice data not found')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Invoice'),
        actions: [
          IconButton(
            onPressed: () => _shareInvoice(member, payment, owner),
            icon: const Icon(LucideIcons.share2),
          ),
          IconButton(
            onPressed: () => _shareInvoice(member, payment, owner),
            icon: const Icon(LucideIcons.download),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4), // Paper-like feel
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(owner, payment),
              const Divider(height: 48, thickness: 1),
              _buildCustomerInfo(member, payment),
              const SizedBox(height: 32),
              _buildItemsTable(payment),
              const SizedBox(height: 32),
              _buildTotals(payment),
              const SizedBox(height: 64),
              _buildBankDetails(owner),
              const SizedBox(height: 32),
              Center(
                child: Text('THANK YOU!',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _shareInvoice(member, payment, owner) async {
    // Note: We need the Plan object if we want to provide it to the service, 
    // but InvoiceService only uses it for the Period calculation in the current version.
    // We'll pass a mock/derived plan or update the service.
    // For now, let's assume the service works with what's in Payment.
    await InvoiceService.generateAndShare(
      member: member,
      plan: Plan(id: payment.planId, name: payment.planName, durationMonths: payment.durationMonths, components: []),
      payment: payment,
      owner: owner,
    );
  }

  Widget _buildHeader(owner, payment) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(owner.gymName.toUpperCase(), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
            Text(owner.ownerName, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            SizedBox(
              width: 150,
              child: Text(owner.address, style: TextStyle(color: Colors.grey[500], fontSize: 10), maxLines: 2),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text('INVOICE', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 24)),
            Text(payment.invoiceNumber, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomerInfo(member, payment) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('BILL TO', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
            Text(member.name, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            Text(member.phone, style: const TextStyle(color: Colors.black, fontSize: 12)),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text('DATE', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
            Text(_formatDate(payment.date), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildItemsTable(payment) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey))),
          child: const Row(
            children: [
              Expanded(child: Text('DESCRIPTION', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold))),
              Text('AMOUNT', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...payment.components.map((c) => Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.name, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Text('₹${c.price.toStringAsFixed(2)}', style: const TextStyle(color: Colors.black)),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildTotals(payment) {
    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: 180,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal', style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text('₹${payment.subtotal.toStringAsFixed(2)}', style: const TextStyle(color: Colors.black, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('GST (${payment.gstRate.toStringAsFixed(0)}%)', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Text('₹${payment.gstAmount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.black, fontSize: 12)),
              ],
            ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('TOTAL', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                Text('₹${payment.amount.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Method', style: TextStyle(color: Colors.grey, fontSize: 10)),
                Text(payment.method, style: const TextStyle(color: Colors.grey, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankDetails(owner) {
    if (owner.bankName == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('BANK DETAILS', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('${owner.bankName} - A/C ${owner.accountNumber}', style: const TextStyle(color: Colors.black, fontSize: 11)),
        Text('IFSC: ${owner.ifsc}', style: const TextStyle(color: Colors.black, fontSize: 11)),
      ],
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day} ${['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][d.month - 1]} ${d.year}';
}
