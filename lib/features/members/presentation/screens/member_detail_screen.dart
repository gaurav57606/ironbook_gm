import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../../shared/widgets/app_button.dart';
import '../../../../../shared/widgets/status_bar_wrapper.dart';
import '../../../../core/providers/member_provider.dart';
import '../../../../core/data/local/models/member_snapshot_model.dart';
import '../../../../shared/utils/date_formatter.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../core/data/repositories/event_repository.dart';
import '../../../../core/data/local/models/domain_event_model.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/utils/clock.dart';

class MemberDetailScreen extends ConsumerStatefulWidget {
  final String memberId;
  const MemberDetailScreen({super.key, required this.memberId});

  @override
  ConsumerState<MemberDetailScreen> createState() => _MemberDetailScreenState();
}

class _MemberDetailScreenState extends ConsumerState<MemberDetailScreen> {
  List<DomainEvent> _history = [];
  bool _isLoadingHistory = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final repo = ref.read(eventRepositoryProvider);
      final events = await repo.getByEntityId(widget.memberId);
      if (mounted) {
        setState(() {
          _history = events.reversed.toList();
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(membersProvider);
    
    final member = members.firstWhereOrNull((m) => m.memberId == widget.memberId);

    if (member == null) {
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

    final status = member.getStatus(DateTime.now());
    final statusColor = _getStatusColor(status);
    final statusMsg = _getStatusMessage(member);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: StatusBarWrapper(
          child: Column(
            children: [
              _buildAppBar(context, member, statusColor, statusMsg),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderAvatar(member, statusColor, statusMsg),
                      _buildQuickActions(context, member),
                      _buildSectionHeader('SUBSCRIPTION'),
                      _buildSubscriptionCard(member, statusColor, statusMsg),
                      _buildSectionHeader('FINANCIALS'),
                      _buildFinancialsCard(member),
                      _buildSectionHeader('HISTORY'),
                      _buildPaymentHistory(),
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
              borderRadius: BorderRadius.circular(32),
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 6, height: 6, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(statusMsg, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: statusColor)),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, MemberSnapshot member, Color color, String status) {
    return Padding(
      padding: const EdgeInsets.only(left: 14, right: 14, top: 12, bottom: 8),
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
                borderRadius: BorderRadius.circular(12),
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
                borderRadius: BorderRadius.circular(12),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: 'Check In',
                  style: AppButtonStyle.secondary,
                  onPressed: () => ref.read(membersProvider.notifier).recordAttendance(member.memberId),
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
                  onPressed: () => _showDeleteConfirmation(context, member),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, MemberSnapshot member) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.elevation2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 24, 14, 12),
      child: Text(
        title,
        style: AppTextStyles.sectionTitle.copyWith(fontSize: 10, letterSpacing: 2.0),
      ),
    );
  }

  Widget _buildSubscriptionCard(MemberSnapshot member, Color color, String status) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.elevation2,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildInfoRow('Current Plan', member.planName ?? 'N/A', valueSize: 14, labelWeight: FontWeight.w700),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: AppColors.border, height: 1),
          ),
          _buildInfoRow('Joined on', DateFormatter.format(member.joinDate), suffix: _buildLockedEdit()),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
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

  Widget _buildFinancialsCard(MemberSnapshot member) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.elevation2,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            'Total Contribution', 
            CurrencyFormatter.format(member.totalPaid / 100.0), 
            valueColor: AppColors.primary, 
            valueSize: 20, 
            valueWeight: FontWeight.w800,
            labelColor: AppColors.textPrimary,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: AppColors.border, height: 1),
          ),
          _buildInfoRow('Payments Count', member.paymentIds.length.toString(), valueWeight: FontWeight.w600),
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

  Widget _buildPaymentHistory() {
    if (_isLoadingHistory) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(40),
        child: CircularProgressIndicator(),
      ));
    }

    if (_history.isEmpty) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.history_rounded, size: 40, color: AppColors.textMuted.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text('No history recorded yet', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
          ],
        ),
      ));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        children: List.generate(_history.length, (index) {
          final event = _history[index];
          final isLast = index == _history.length - 1;
          
          final eventTypeStr = event.eventType.name.toUpperCase();
          String title = eventTypeStr.replaceAll('_', ' ');
          String amountSpan = '';
          if (event.payload['amount'] != null) {
            amountSpan = CurrencyFormatter.format((event.payload['amount'] as int) / 100.0);
          }

          final bool isPayment = eventTypeStr.contains('PAYMENT');
          final bool isCreation = eventTypeStr.contains('CREATED');

          return _buildTimelineItem(
            title,
            '${DateFormatter.format(event.deviceTimestamp)} · ${isPayment ? "Confirmed" : "System Notification"}',
            amountSpan,
            icon: isPayment ? Icons.payments_rounded : (isCreation ? Icons.person_add_rounded : Icons.info_outline_rounded),
            color: isPayment ? AppColors.primary : (isCreation ? AppColors.green : AppColors.textMuted),
            isLast: isLast,
          );
        }),
      ),
    );
  }

  Widget _buildTimelineItem(String title, String subtitle, String amount, {required IconData icon, required Color color, bool isLast = false}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1.5,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: AppColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(title, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700, fontSize: 13)),
                      if (amount.isNotEmpty)
                        Text(amount, style: AppTextStyles.cardTitle.copyWith(fontSize: 14, color: AppColors.primary)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 10)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedEdit() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
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

  String _getStatusMessage(MemberSnapshot m) {
    final now = ref.watch(clockProvider).now;
    final days = m.getDaysRemaining(now);
    if (days < 0) return 'Membership Expired';
    if (days == 0) return 'Expires Today';
    if (days <= 7) return 'Expires in $days days';
    return 'Active Status';
  }
}









