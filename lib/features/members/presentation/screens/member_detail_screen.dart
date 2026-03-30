import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/status_bar_wrapper.dart';
import '../../../../providers/member_provider.dart';
import '../../../../data/local/models/member_snapshot_model.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../data/repositories/event_repository.dart';
import '../../../../data/local/models/domain_event_model.dart';
import 'package:go_router/go_router.dart';

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

  void _loadHistory() {
    try {
      final repo = ref.read(eventRepositoryProvider);
      final events = repo.getByEntityId(widget.memberId);
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
    
    // Find member or return null
    final member = members.where((m) => m.memberId == widget.memberId).firstOrNull;

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

    return StatusBarWrapper(
      child: Column(
        children: [
          _buildAppBar(context, member, statusColor, statusMsg),
          _buildQuickActions(context, member),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Subscription'),
                  _buildSubscriptionCard(member, statusColor, statusMsg),
                  _buildSectionHeader('Plan Info'),
                  _buildPlanCard(member),
                  _buildSectionHeader('Payment History'),
                  _buildPaymentHistory(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, MemberSnapshot member, Color color, String status) {
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
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              member.name.isNotEmpty ? member.name.substring(0, 1).toUpperCase() : '?',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
                Text(member.phone ?? 'No phone', style: const TextStyle(fontSize: 10, color: AppColors.text2)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(width: 4, height: 4, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text(status, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, MemberSnapshot member) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: AppButton(
              text: 'Generate Invoice',
              onPressed: () => context.push('/invoice'),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: AppButton(
              text: 'Renew',
              style: AppButtonStyle.secondary,
              onPressed: () {
                // Future: Navigate to renewal flow
              },
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: AppButton(
              text: 'WhatsApp',
              style: AppButtonStyle.secondary,
              onPressed: () {
                 // Future: Open WhatsApp with member.phone
              },
            ),
          ),
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

  Widget _buildSubscriptionCard(MemberSnapshot member, Color color, String status) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.bg3,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildInfoRow('Plan', member.planName ?? 'N/A'),
          const Divider(height: 20),
          _buildInfoRow('Join Date', DateFormatter.format(member.joinDate), suffix: _buildLockedEdit()),
          const Divider(height: 20),
          _buildInfoRow(
            'Expiry',
            member.expiryDate != null ? DateFormatter.format(member.expiryDate!) : 'N/A',
            valueColor: color,
          ),
          const Divider(height: 20),
          _buildInfoRow('Status', status, valueColor: color),
        ],
      ),
    );
  }

  Widget _buildLockedEdit() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      margin: const EdgeInsets.only(left: 6),
      decoration: BoxDecoration(
        color: AppColors.orange.withOpacity(0.15),
        borderRadius: BorderRadius.circular(3),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock, size: 8, color: AppColors.orange),
          SizedBox(width: 2),
          Text('Edit', style: TextStyle(fontSize: 9, color: AppColors.orange, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildPlanCard(MemberSnapshot member) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.bg3,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildInfoRow('Total Contribution', CurrencyFormatter.format(member.totalPaid / 100.0), valueColor: AppColors.orange, valueSize: 13, labelColor: AppColors.text, labelWeight: FontWeight.w700),
          const Divider(height: 20),
          _buildInfoRow('Payments Count', member.paymentIds.length.toString()),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor, double valueSize = 10, Color? labelColor, FontWeight? labelWeight, Widget? suffix}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: labelColor ?? AppColors.text2, fontWeight: labelWeight)),
        Row(
          children: [
            Text(value, style: TextStyle(fontSize: valueSize, fontWeight: FontWeight.w600, color: valueColor ?? AppColors.text)),
            if (suffix != null) suffix,
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentHistory() {
    if (_isLoadingHistory) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(20),
        child: CircularProgressIndicator(),
      ));
    }

    if (_history.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(20),
        child: Text('No history found', style: TextStyle(fontSize: 10, color: AppColors.text3)),
      ));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        children: List.generate(_history.length, (index) {
          final event = _history[index];
          final isLast = index == _history.length - 1;
          
          String title = event.eventType.replaceAll('_', ' ');
          String amountSpan = '';
          if (event.payload['amount'] != null) {
            amountSpan = CurrencyFormatter.format((event.payload['amount'] as int) / 100.0);
          }

          return _buildTimelineItem(
            title,
            '${DateFormatter.format(event.deviceTimestamp)} · ${event.eventType.contains('PAYMENT') ? "Paid" : "Action"}',
            amountSpan,
            isOrange: event.eventType.contains('PAYMENT'),
            isGreen: event.eventType.contains('CREATED'),
            isLast: isLast,
          );
        }),
      ),
    );
  }

  Widget _buildTimelineItem(String title, String subtitle, String amount, {bool isOrange = false, bool isGreen = false, bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(color: isOrange ? AppColors.orange : (isGreen ? AppColors.green : AppColors.text3), shape: BoxShape.circle),
            ),
            if (!isLast)
              Container(
                width: 1,
                height: 40,
                color: AppColors.border,
              ),
          ],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.text)),
                const SizedBox(height: 1),
                Text(subtitle, style: const TextStyle(fontSize: 9, color: AppColors.text2)),
                if (amount.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(amount, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.orange)),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(MemberStatus status) {
    switch (status) {
      case MemberStatus.active: return AppColors.green;
      case MemberStatus.expiring: return AppColors.amber;
      case MemberStatus.expired: return AppColors.red;
      case MemberStatus.pending: return AppColors.text3;
    }
  }

  String _getStatusMessage(MemberSnapshot m) {
    final now = DateTime.now();
    final days = m.getDaysRemaining(now);
    if (days < 0) return 'Expired';
    if (days == 0) return 'Today';
    if (days <= 7) return '$days days';
    return '${days}d';
  }
}
