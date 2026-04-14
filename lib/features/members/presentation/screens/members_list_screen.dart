import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/colors.dart';
import '../../../../providers/member_provider.dart';
import '../../../../data/local/models/member_snapshot_model.dart';
import '../../../../core/utils/date_formatter.dart';
import 'package:go_router/go_router.dart';

class MembersListScreen extends ConsumerWidget {
  const MembersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredMembers = ref.watch(filteredMembersProvider);
    final allMembersCount = ref.watch(membersProvider).length;

    return Column(
      children: [
        _buildAppBar(context),
        _buildSearchAndFilters(context, ref),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            children: [
              _buildMemberListContainer(context, filteredMembers),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Showing ${filteredMembers.length} of $allMembersCount members',
                  style: const TextStyle(fontSize: 9, color: AppColors.text3),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Members',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          GestureDetector(
            onTap: () => context.push('/gym/add-member'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.orange,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.add, size: 14, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'Add',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Container(
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.bg3,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              onChanged: (value) =>
                  ref.read(memberSearchQueryProvider.notifier).state = value,
              style: const TextStyle(fontSize: 11, color: AppColors.text),
              decoration: const InputDecoration(
                hintText: 'Search name or phone...',
                hintStyle: TextStyle(fontSize: 11, color: AppColors.text3),
                prefixIcon: Icon(
                  Icons.search,
                  size: 14,
                  color: AppColors.text3,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),
        _buildPillTabs(ref),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              const Text(
                'Sort by',
                style: TextStyle(fontSize: 9, color: AppColors.text2),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.bg3,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  children: [
                    Text(
                      'Expiry (soonest)',
                      style: TextStyle(fontSize: 9, color: AppColors.text),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_drop_down,
                      size: 14,
                      color: AppColors.text,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPillTabs(WidgetRef ref) {
    final all = ref.watch(membersProvider);
    final selectedTab = ref.watch(memberTabProvider);

    int activeCount = 0;
    int expiringCount = 0;
    int expiredCount = 0;
    final now = DateTime.now();

    // Performance Optimization: Calculate derived statuses in a single pass
    for (final m in all) {
      final status = m.getStatus(now);
      switch (status) {
        case MemberStatus.active:
          activeCount++;
          break;
        case MemberStatus.expiring:
          expiringCount++;
          break;
        case MemberStatus.expired:
          expiredCount++;
          break;
        case MemberStatus.pending:
          break;
      }
    }

    final tabs = [
      'All ${all.length}',
      'Active $activeCount',
      'Expiring $expiringCount',
      'Expired $expiredCount',
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.bg3,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = selectedTab == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => ref.read(memberTabProvider.notifier).state = index,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.orange : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  tabs[index],
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.text2,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMemberListContainer(
    BuildContext context,
    List<MemberSnapshot> members,
  ) {
    if (members.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: const Text(
          'No members found',
          style: TextStyle(color: AppColors.text3),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg3,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: List.generate(members.length, (index) {
          final m = members[index];
          final statusMsg = _getStatusMessage(m);
          final statusColor = _getStatusColor(m);

          return _buildMemberItem(
            context,
            m,
            m.name.isNotEmpty ? m.name.substring(0, 1).toUpperCase() : '?',
            '${m.planName ?? "N/A"} · Since ${_formatDate(m.joinDate)}',
            statusMsg,
            statusColor,
            isLast: index == members.length - 1,
          );
        }),
      ),
    );
  }

  String _getStatusMessage(MemberSnapshot m) {
    final now = DateTime.now();
    final days = m.getDaysRemaining(now);
    if (days < 0) return 'Expired';
    if (days == 0) return 'Today';
    if (days <= 7) return '$days days';
    return '${days}d';
  }

  Color _getStatusColor(MemberSnapshot m) {
    final status = m.getStatus(DateTime.now());
    switch (status) {
      case MemberStatus.active:
        return AppColors.green;
      case MemberStatus.expiring:
        return AppColors.amber;
      case MemberStatus.expired:
        return AppColors.red;
      case MemberStatus.pending:
        return AppColors.text3;
    }
  }

  String _formatDate(DateTime d) => DateFormatter.formatShort(d);

  Widget _buildMemberItem(
    BuildContext context,
    MemberSnapshot member,
    String initials,
    String subtitle,
    String status,
    Color color, {
    bool isLast = false,
  }) {
    return GestureDetector(
      onTap: () => context.push('/gym/member-details/${member.memberId}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(9),
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 9, color: AppColors.text2),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
