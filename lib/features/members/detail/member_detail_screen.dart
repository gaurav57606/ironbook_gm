import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../providers/member_provider.dart';
import '../../../providers/payment_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../data/local/models/member_snapshot_model.dart';
import '../../../data/local/models/payment_model.dart';
import '../../../data/local/models/plan_model.dart';

class MemberDetailScreen extends ConsumerWidget {
  final String id;
  const MemberDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(membersProvider);
    final member = members.where((m) => m.memberId == id).firstOrNull;
    final allPayments = ref.watch(paymentsProvider);
    final memberPayments = allPayments.where((p) => p.memberId == id).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    if (member == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Member Details')),
        body: const Center(child: Text('Member not found')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Member Details'),
        actions: [
          IconButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edit flow coming soon'))),
            icon: const Icon(LucideIcons.edit2),
          ),
          IconButton(
            onPressed: () => _showDeleteConfirmation(context, ref, member),
            icon: const Icon(LucideIcons.trash2, color: AppColors.expired),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildProfileHeader(member),
            const SizedBox(height: 32),
            _buildInfoGrid(member),
            const SizedBox(height: 32),
            _buildActionButtons(context, ref, member),
            const SizedBox(height: 32),
            _buildPaymentHistory(memberPayments),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, MemberSnapshot member) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: const Text('Delete Member'),
        content: Text('Are you sure you want to remove ${member.name}? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(membersProvider.notifier).deleteMember(member.memberId);
              Navigator.pop(ctx);
              context.pop(); // Go back to list
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.expired)),
          ),
        ],
      ),
    );
  }

  void _showPlanSelector(BuildContext context, WidgetRef ref, MemberSnapshot member) {
    final plans = Hive.box<Plan>('plans').values.toList();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bg2,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Renewal Plan', style: AppTextStyles.cardTitle),
            const SizedBox(height: 16),
            ...plans.map((plan) => ListTile(
              leading: const Icon(LucideIcons.package, color: AppColors.primary),
              title: Text(plan.name, style: AppTextStyles.label),
              subtitle: Text('₹${plan.totalPrice.toStringAsFixed(0)} • ${plan.durationMonths} Months'),
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                await ref.read(paymentsProvider.notifier).recordMemberPayment(
                  memberId: member.memberId,
                  plan: plan,
                  method: 'Cash',
                );
                messenger.showSnackBar(SnackBar(content: Text('Membership renewed with ${plan.name}')));
                if (ctx.mounted) Navigator.pop(ctx);
              },
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(MemberSnapshot member) {
    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: AppColors.bg3,
          child: Text(
            member.name.substring(0, member.name.length > 1 ? 2 : 1).toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 16),
        Text(member.name, style: AppTextStyles.cardTitle.copyWith(fontSize: 24)),
        Text(member.phone ?? 'No phone', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
      ],
    );
  }

  Widget _buildInfoGrid(MemberSnapshot member) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.5,
      children: [
        _buildInfoItem('JOIN DATE', _formatDate(member.joinDate)),
        _buildInfoItem('EXPIRY DATE', member.expiryDate != null ? _formatDate(member.expiryDate!) : 'N/A'),
        _buildInfoItem('PLAN', member.planName ?? 'No Plan'),
        _buildInfoItem(
          'STATUS',
          member.status.name.toUpperCase(),
          color: _getStatusColor(member.status),
        ),
      ],
    );
  }

  Color _getStatusColor(MemberStatus status) {
    switch (status) {
      case MemberStatus.active:
        return AppColors.active;
      case MemberStatus.expiring:
        return AppColors.expiring;
      case MemberStatus.expired:
        return AppColors.expired;
      default:
        return AppColors.textMuted;
    }
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

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, MemberSnapshot member) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showPlanSelector(context, ref, member),
            icon: const Icon(LucideIcons.creditCard),
            label: const Text('Renew'),
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
            onPressed: () => context.push('/members/${member.memberId}/invoice'),
            icon: const Icon(LucideIcons.fileText),
            label: const Text('Latest Invoice'),
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

  Widget _buildPaymentHistory(List<Payment> payments) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Payment History', style: AppTextStyles.cardTitle),
        const SizedBox(height: 16),
        if (payments.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('No payment history found', style: TextStyle(color: AppColors.textMuted)),
          )
        else
          ...payments.map((p) => _buildPaymentItem(_formatDate(p.date), '₹${p.amount.toStringAsFixed(0)}', p.method)),
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

  String _formatDate(DateTime d) =>
      '${d.day} ${['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][d.month - 1]} ${d.year}';
}
