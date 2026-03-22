import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class MemberDetailScreen extends ConsumerWidget {
  final String id;
  const MemberDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Member Details'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(LucideIcons.edit2)),
          IconButton(onPressed: () {}, icon: const Icon(LucideIcons.trash2, color: AppColors.expired)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 32),
            _buildInfoGrid(),
            const SizedBox(height: 32),
            _buildActionButtons(context),
            const SizedBox(height: 32),
            _buildPaymentHistory(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: AppColors.bg3,
          child: const Icon(LucideIcons.user, size: 40, color: AppColors.textMuted),
        ),
        const SizedBox(height: 16),
        Text('Rajesh Kumar', style: AppTextStyles.cardTitle.copyWith(fontSize: 24)),
        Text('+91 98765 43210', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
      ],
    );
  }

  Widget _buildInfoGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.5,
      children: [
        _buildInfoItem('JOIN DATE', '12 Mar 2026'),
        _buildInfoItem('EXPIRY DATE', '12 Apr 2026'),
        _buildInfoItem('PLAN', 'Monthly Standard'),
        _buildInfoItem('STATUS', 'ACTIVE', color: AppColors.active),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value, {Color? color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg3,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.label.copyWith(color: color ?? AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(LucideIcons.creditCard),
            label: const Text('Add Payment'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.push('/members/invoice/123'),
            icon: const Icon(LucideIcons.fileText),
            label: const Text('Invoices'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Payment History', style: AppTextStyles.cardTitle),
        const SizedBox(height: 16),
        _buildPaymentItem('12 Mar 2026', '₹2,500', 'GPay'),
        _buildPaymentItem('12 Feb 2026', '₹2,500', 'Cash'),
      ],
    );
  }

  Widget _buildPaymentItem(String date, String amount, String method) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(date, style: AppTextStyles.label),
              Text(method, style: AppTextStyles.bodySmall.copyWith(fontSize: 10)),
            ],
          ),
          Text(amount, style: AppTextStyles.cardTitle.copyWith(color: AppColors.active)),
        ],
      ),
    );
  }
}
