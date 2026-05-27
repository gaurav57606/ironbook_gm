import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../shared/widgets/app_section_header.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../core/providers/member_provider.dart';
import '../../../billing/providers/billing_provider.dart';
import '../../../../core/data/local/models/member_snapshot_model.dart';
import '../../../../shared/utils/date_utils.dart';
import '../../../../shared/utils/currency_formatter.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/utils/clock.dart';
import '../widgets/payment_history_item.dart';
import '../widgets/renewal_dialog.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/providers/owner_provider.dart';
import 'package:ironbook_gm/features/members/data/subscriptions_repository.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ironbook_gm/core/services/photo_service.dart';
import 'package:ironbook_gm/shared/widgets/member_photo_avatar.dart';
import 'package:ironbook_gm/shared/utils/app_snack_bar.dart';
import 'package:ironbook_gm/core/data/local/drift/outbox_database.dart';

extension on ISubscriptionsRepository {
  Stream<List<MemberSubscription>> watchMemberSubscriptions(String memberId) {
    return watchMemberSubscriptionHistory(memberId);
  }
}

final memberSubscriptionsProvider = StreamProvider.family<List<MemberSubscription>, String>((ref, memberId) {
  final repo = ref.watch(subscriptionsRepositoryProvider);
  return repo.watchMemberSubscriptions(memberId);
});

class MemberDetailScreen extends ConsumerStatefulWidget {
  final String memberId;
  const MemberDetailScreen({super.key, required this.memberId});

  @override
  ConsumerState<MemberDetailScreen> createState() => _MemberDetailScreenState();
}

class _MemberDetailScreenState extends ConsumerState<MemberDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final member = ref.watch(memberProvider(widget.memberId));

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
      body: SafeArea(
        top: true,
        child: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.backgroundGradient,
          ),
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
                      _buildQuickActions(context, member),
                      const AppSectionHeader(title: 'SUBSCRIPTION'),
                      _buildSubscriptionCard(member, statusColor, now),
                      _SubscriptionHistorySection(memberId: widget.memberId),
                      const AppSectionHeader(title: 'MEMBERSHIP HISTORY'),
                      _buildSubscriptionHistory(widget.memberId),
                      const AppSectionHeader(title: 'FINANCIALS'),
                      _buildFinancialsCard(widget.memberId),
                      const AppSectionHeader(title: 'PAYMENT HISTORY'),
                      _buildPaymentHistory(widget.memberId),
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

  Widget _buildFinancialsCard(String memberId) {
    // ⚡ Bolt: Use .select() to compute totals outside the main build method
    final financials = ref.watch(memberPaymentsProvider(memberId).select((p) {
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

  Widget _buildPaymentHistory(String memberId) {
    final paymentsAsync = ref.watch(memberPaymentsProvider(memberId));
    
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
                subtitle: '${AppDateUtils.format(payment.date)} · Confirmed',
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

  Widget _buildSubscriptionHistory(String memberId) {
    final historyAsync = ref.watch(memberSubscriptionHistoryProvider(memberId));

    return historyAsync.when(
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
      error: (e, s) => const Center(child: Text('Error loading subscription history', style: TextStyle(color: Colors.red))),
      data: (history) {
        if (history.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(Icons.history_toggle_off_rounded, size: 40, color: AppColors.text3.withValues(alpha: 0.3)),
                  AppSpacing.gapS,
                  const Text('No membership history recorded yet', style: TextStyle(color: AppColors.text3)),
                ],
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          child: Column(
            children: List.generate(history.length, (index) {
              final sub = history[index];

              // Format date
              final startStr = AppDateUtils.format(sub.startDate);
              final endStr = AppDateUtils.format(sub.endDate);

              // Status styling
              final Color statusColor;
              final String statusText;
              switch (sub.status.toLowerCase()) {
                case 'active':
                  statusColor = AppColors.green;
                  statusText = 'Active';
                  break;
                case 'expired':
                  statusColor = AppColors.textMuted;
                  statusText = 'Expired';
                  break;
                case 'paused':
                  statusColor = AppColors.amber;
                  statusText = 'Paused';
                  break;
                default:
                  statusColor = AppColors.textMuted;
                  statusText = sub.status;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(AppSpacing.m),
                decoration: BoxDecoration(
                  color: AppColors.elevation2,
                  borderRadius: AppRadius.radiusL,
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          sub.planName ?? 'Standard Plan',
                          style: AppTextStyles.cardTitle.copyWith(fontSize: 14),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: AppRadius.radiusS,
                            border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            statusText.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: statusColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.gapS,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$startStr  →  $endStr',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(sub.amountPaid),
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ),
        );
      },
    );
  }

  void _removeMemberPhoto(BuildContext context, WidgetRef ref, MemberSnapshot member) async {
    if (member.photoUrl == null) return;
    final tempUrl = member.photoUrl;
    await ref.read(membersProvider.notifier).updateMember(
      memberId: member.memberId,
      name: member.name,
      phone: member.phone ?? '',
      photoUrl: '', // empty string indicates photo cleared
    );
    await photoService.deletePhoto(tempUrl);
    if (context.mounted) {
      AppSnackBar.showSuccess(context, 'Photo removed');
    }
  }

  Widget _buildHeaderAvatar(MemberSnapshot member, Color statusColor, String statusMsg) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 20),
          Stack(
            children: [
              MemberPhotoAvatar(
                memberName: member.name,
                photoUrl: member.photoUrl,
                size: 100,
                onTap: () async {
                  final ImageSource? source = await showModalBottomSheet<ImageSource>(
                    context: context,
                    backgroundColor: AppColors.elevation2,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (context) => SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                            title: const Text('Take Photo', style: TextStyle(color: Colors.white)),
                            onTap: () => Navigator.pop(context, ImageSource.camera),
                          ),
                          ListTile(
                            leading: const Icon(Icons.photo_library, color: AppColors.primary),
                            title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white)),
                            onTap: () => Navigator.pop(context, ImageSource.gallery),
                          ),
                          if (member.photoUrl != null && member.photoUrl!.isNotEmpty)
                            ListTile(
                              leading: const Icon(Icons.delete, color: AppColors.red),
                              title: const Text('Remove Photo', style: TextStyle(color: AppColors.red)),
                              onTap: () {
                                Navigator.pop(context);
                                _removeMemberPhoto(context, ref, member);
                              },
                            ),
                        ],
                      ),
                    ),
                  );

                  if (source == null) return;

                  final url = await photoService.pickAndUpload(
                    memberId: member.memberId,
                    source: source,
                    existingUrl: member.photoUrl,
                  );

                  if (url != null) {
                    await ref.read(membersProvider.notifier).updateMember(
                      memberId: member.memberId,
                      name: member.name,
                      phone: member.phone ?? '',
                      photoUrl: url,
                    );
                    if (context.mounted) {
                      AppSnackBar.showSuccess(context, 'Photo updated successfully');
                    }
                  } else {
                    if (context.mounted) {
                      AppSnackBar.showError(context, 'Failed to upload photo');
                    }
                  }
                },
              ),
              Positioned(
                bottom: -4,
                right: -4,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.elevation2,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, size: 16, color: AppColors.primary),
                  ),
                ),
              ),
            ],
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
            onTap: () => context.push('/members/member-edit/${widget.memberId}'),
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

  Widget _buildQuickActions(BuildContext context, MemberSnapshot member) {
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
                  onPressed: () => context.push('/members/member-details/${member.memberId}/invoice'),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: AppButton(
                  text: 'Renew',
                  style: AppButtonStyle.secondary,
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => RenewalDialog(member: member),
                    );
                  },
                ),
              ),
            ],
          ),
          AppSpacing.gapS,
          Row(
            children: [
              Expanded(
                child: _buildIconAction(
                  icon: Icons.how_to_reg_outlined,
                  label: 'Check In',
                  color: AppColors.textPrimary,
                  onTap: () {
                    // Logic for attendance
                  },
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildIconAction(
                  icon: Icons.chat_outlined,
                  label: 'WhatsApp',
                  color: AppColors.textPrimary,
                  onTap: () async {
                    final phone = member.phone;
                    if (phone == null || phone.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No phone number saved for this member')),
                      );
                      return;
                    }
                    final clean = phone.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
                    final dialCode = clean.startsWith('91') ? clean : '91$clean';
                    final gymName = ref.read(ownerProvider)?.gymName ?? 'your gym';
                    final expiry = member.expiryDate != null
                        ? 'Your membership expires on ${AppDateUtils.format(member.expiryDate!)}.'
                        : '';
                    final msg = Uri.encodeComponent(
                      'Hi ${member.name}, this is a reminder from $gymName. $expiry Please renew to continue! 💪',
                    );
                    final url = Uri.parse('https://wa.me/$dialCode?text=$msg');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('WhatsApp is not installed')),
                        );
                      }
                    }
                  },
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildIconAction(
                  icon: Icons.delete_outline_rounded,
                  label: 'Delete',
                  color: AppColors.error,
                  onTap: () => _showDeleteConfirmation(context, member),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.elevation2,
            borderRadius: AppRadius.radiusM,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, MemberSnapshot member) {
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


  Widget _buildSubscriptionCard(MemberSnapshot member, Color color, DateTime now) {
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
          _buildInfoRow('Joined on', AppDateUtils.format(member.joinDate), suffix: _buildLockedEdit()),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.m),
            child: Divider(color: AppColors.border, height: 1),
          ),
          _buildInfoRow(
            'Expires on',
            member.expiryDate != null ? AppDateUtils.format(member.expiryDate!) : 'N/A',
            valueColor: color,
            valueWeight: FontWeight.w700,
          ),
          Builder(
            builder: (context) {
              final days = member.getDaysRemaining(now);
              final isExpired = days < 0;
              final isExpiringSoon = !isExpired && days <= 7;

              final label = isExpired
                  ? '${days.abs()} days overdue'
                  : days == 0
                      ? 'Expires today'
                      : '$days days remaining';

              final color = isExpired
                  ? AppColors.red
                  : isExpiringSoon
                      ? AppColors.amber
                      : AppColors.green;

              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: AppRadius.radiusS,
                    border: Border.all(color: color.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isExpired
                            ? Icons.cancel_outlined
                            : isExpiringSoon
                                ? Icons.timer_outlined
                                : Icons.check_circle_outline_rounded,
                        color: color,
                        size: 15,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
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
      case MemberStatus.archived: return AppColors.textMuted;
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

class _SubscriptionHistorySection extends ConsumerWidget {
  final String memberId;
  const _SubscriptionHistorySection({required this.memberId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subsAsync = ref.watch(memberSubscriptionsProvider(memberId));
    return subsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (subs) {
        if (subs.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('Subscription History',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
            ...subs.map((s) => ListTile(
              dense: true,
              leading: Icon(
                s.status == 'active' ? Icons.check_circle : Icons.history,
                color: s.status == 'active' ? Colors.green : Colors.grey,
                size: 18,
              ),
              title: Text(s.planName ?? 'Unknown Plan'),
              subtitle: Text(
                '${_fmt(s.startDate)} → ${_fmt(s.endDate)}',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: Text(
                '₹${s.amountPaid.toInt()}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            )),
          ],
        );
      },
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
