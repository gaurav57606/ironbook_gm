import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../shared/widgets/app_section_header.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/status_bar_wrapper.dart';
import '../../../../core/providers/member_provider.dart';
import '../../../billing/providers/billing_provider.dart';
import '../../../../core/data/local/models/member_snapshot_model.dart';
import '../../../../shared/utils/date_formatter.dart';
import '../../../../shared/utils/currency_formatter.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/utils/clock.dart';
import '../widgets/payment_history_item.dart';

class MemberDetailScreen extends ConsumerWidget {
  final String memberId;
  const MemberDetailScreen({super.key, required this.memberId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final member = ref.watch(memberProvider(memberId));

    if (member == null) {
      return _buildNotFound(context);
    }

    // ⚡ Bolt: Watch only the specific fields needed for the status to minimize rebuilds
    final now = ref.watch(clockProvider.select((c) => c.now));
    final status = member.getStatus(now);
    final statusColor = _getStatusColor(status);
    final statusMsg = _getStatusMessage(member, now);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: StatusBarWrapper(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderAvatar(member, statusColor, statusMsg),
                      _buildQuickActions(context, member, ref),
                      const AppSectionHeader(title: 'SUBSCRIPTION'),
                      _buildSubscriptionCard(member, statusColor),
                      const AppSectionHeader(title: 'FINANCIALS'),
                      _buildFinancialsCard(ref, memberId),
                      const AppSectionHeader(title: 'HISTORY'),
                      _buildPaymentHistory(ref, memberId),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotFound(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_off_outlined, size: 48, color: AppColors.text3),
            const SizedBox(height: 12),
            const Text('Member not found', style: TextStyle(color: AppColors.text)),
            const SizedBox(height: 20),
            AppButton(
              text: 'Go Back',
              width: 120,
              onPressed: () => context.pop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialsCard(WidgetRef ref, String memberId) {
    // ⚡ Bolt: Use .select() to compute totals outside the main build method
    final financials = ref.watch(paymentsProvider(memberId).select((p) {
      final list = p.value ?? [];
      final total = list.fold(0.0, (sum, item) => sum + item.amount);
      return (count: list.length, total: total);
    }));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.elevation2,
        borderRadius: AppRadius.radiusXL,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            'Total Contribution', 
            CurrencyFormatter.format(financials.total), 
            valueColor: AppColors.primary, 
            valueSize: 20, 
            valueWeight: FontWeight.w800,
            labelColor: AppColors.textPrimary,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.m),
            child: Divider(color: AppColors.border, height: 1),
          ),
          _buildInfoRow('Payments Count', financials.count.toString(), valueWeight: FontWeight.w600),
        ],
      ),
    );
  }

  Widget _buildPaymentHistory(WidgetRef ref, String memberId) {
    final paymentsAsync = ref.watch(paymentsProvider(memberId));
    
    return paymentsAsync.when(
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
      error: (e, s) => const Center(child: Text('Error loading history', style: TextStyle(color: Colors.red))),
      data: (payments) {
        if (payments.isEmpty) {
          return Center(child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                Icon(Icons.history_rounded, size: 40, color: AppColors.text3.withValues(alpha: 0.3)),
                AppSpacing.gapS,
                const Text('No history recorded yet', style: TextStyle(color: AppColors.text3)),
              ],
            ),
          ));
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          child: Column(
            children: List.generate(payments.length, (index) {
              final payment = payments[index];
              return PaymentHistoryItem(
                title: 'PAYMENT RECEIVED',
                subtitle: '${DateFormatter.format(payment.date)} · Confirmed',
                amount: CurrencyFormatter.format(payment.amount),
                icon: Icons.payments_rounded,
                color: AppColors.primary,
                isLast: index == payments.length - 1,
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildHeaderAvatar(MemberSnapshot member, Color statusColor, String statusMsg) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [statusColor.withValues(alpha: 0.3), statusColor.withValues(alpha: 0.1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: AppRadius.radiusXL,
              border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 2),
            ),
            alignment: Alignment.center,
            child: Text(
              member.name.isNotEmpty ? member.name.substring(0, 1).toUpperCase() : '?',
              style: AppTextStyles.heroNumber.copyWith(fontSize: 40, color: statusColor),
            ),
          ),
          const SizedBox(height: 16),
          Text(member.name, style: AppTextStyles.cardTitle.copyWith(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.phone_rounded, size: 12, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(member.phone ?? 'No phone', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: AppRadius.radiusL,
              border: Border.all(color: statusColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 6, height: 6, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                AppSpacing.gapS,
                Text(statusMsg, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: statusColor)),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.screenPadding, right: AppSpacing.screenPadding, top: AppSpacing.m, bottom: AppSpacing.s),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.elevation2,
                borderRadius: AppRadius.radiusS,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.text),
            ),
          ),
          GestureDetector(
            onTap: () {
              // Edit member flow
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.elevation2,
                borderRadius: AppRadius.radiusS,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.edit_outlined, size: 20, color: AppColors.text),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, MemberSnapshot member, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding, vertical: AppSpacing.s),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: AppButton(
                  text: 'Generate Invoice',
                  onPressed: () => context.push('/gym/member-details/${member.memberId}/invoice'),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: AppButton(
                  text: 'Renew',
                  style: AppButtonStyle.secondary,
                  onPressed: () {
                    // Navigate to renewal flow
                  },
                ),
              ),
            ],
          ),
          AppSpacing.gapS,
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: 'Check In',
                  style: AppButtonStyle.secondary,
                  onPressed: () {
                    // Logic for attendance
                  },
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: AppButton(
                  text: 'WhatsApp',
                  style: AppButtonStyle.secondary,
                  onPressed: () {
                     // Open WhatsApp
                  },
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: AppButton(
                  text: 'Delete',
                  style: AppButtonStyle.outline,
                  onPressed: () => _showDeleteConfirmation(context, member, ref),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, MemberSnapshot member, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.elevation2,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusXL),
        title: Text('Delete Member', style: AppTextStyles.cardTitle),
        content: Text('Are you sure you want to delete ${member.name}?', style: AppTextStyles.body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
          TextButton(
            onPressed: () {
              ref.read(membersProvider.notifier).deleteMember(member.memberId);
              Navigator.pop(ctx);
              context.pop();
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }


  Widget _buildSubscriptionCard(MemberSnapshot member, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.elevation2,
        borderRadius: AppRadius.radiusXL,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildInfoRow('Current Plan', member.planName ?? 'N/A', valueSize: 14, labelWeight: FontWeight.w700),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.m),
            child: Divider(color: AppColors.border, height: 1),
          ),
          _buildInfoRow('Joined on', DateFormatter.format(member.joinDate), suffix: _buildLockedEdit()),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.m),
            child: Divider(color: AppColors.border, height: 1),
          ),
          _buildInfoRow(
            'Expires on',
            member.expiryDate != null ? DateFormatter.format(member.expiryDate!) : 'N/A',
            valueColor: color,
            valueWeight: FontWeight.w700,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor, double valueSize = 12, Color? labelColor, FontWeight? labelWeight, FontWeight? valueWeight, Widget? suffix}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: labelColor ?? AppColors.textSecondary, fontWeight: labelWeight)),
        Row(
          children: [
            Text(value, style: TextStyle(fontSize: valueSize, fontWeight: valueWeight ?? FontWeight.w500, color: valueColor ?? AppColors.textPrimary)),
            if (suffix != null) suffix,
          ],
        ),
      ],
    );
  }

  Widget _buildLockedEdit() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: AppRadius.radiusS,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_rounded, size: 10, color: AppColors.primary),
          SizedBox(width: 4),
          Text('LOCKED', style: TextStyle(fontSize: 8, color: AppColors.primary, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Color _getStatusColor(MemberStatus status) {
    switch (status) {
      case MemberStatus.active: return AppColors.green;
      case MemberStatus.expiring: return AppColors.amber;
      case MemberStatus.expired: return AppColors.red;
      case MemberStatus.pending: return AppColors.textSecondary;
    }
  }

  String _getStatusMessage(MemberSnapshot m, DateTime now) {
    final days = m.getDaysRemaining(now);
    if (days < 0) return 'Membership Expired';
    if (days == 0) return 'Expires Today';
    if (days <= 7) return 'Expires in $days days';
    return 'Active Status';
  }
}
