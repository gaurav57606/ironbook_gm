import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../providers/member_provider.dart';
import '../../../../data/local/models/member_snapshot_model.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/clock.dart';
import 'package:go_router/go_router.dart';

class MembersListScreen extends ConsumerWidget {
  const MembersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredMembers = ref.watch(filteredMembersProvider);
    final allMembersCount = ref.watch(membersProvider).length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: Column(
          children: [
            _buildAppBar(context),
            _buildQuickStats(context, ref),
            _buildSearchAndFilters(context, ref),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                children: [
                  _buildMemberListContainer(context, filteredMembers, ref),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'Showing ${filteredMembers.length} of $allMembersCount members',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 14, right: 14, top: 44, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Members',
            style: AppTextStyles.cardTitle.copyWith(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          GestureDetector(
             onTap: () => context.push('/gym/add-member'),
             child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.add_rounded, size: 16, color: Colors.white),
                  SizedBox(width: 6),
                  Text('New Member', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, WidgetRef ref) {
    final all = ref.watch(membersProvider);
    final now = ref.watch(clockProvider).now;
    
    // ⚡ Bolt: Consolidated multiple list traversals to compute stats in one pass
    int active = 0;
    int expiring = 0;
    for (final m in all) {
      final status = m.getStatus(now);
      if (status == MemberStatus.active) {
        active++;
      } else if (status == MemberStatus.expiring) {
        expiring++;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          _buildStatItem('ACTIVE', active.toString(), AppColors.active),
          const SizedBox(width: 10),
          _buildStatItem('EXPIRING', expiring.toString(), AppColors.expiring),
          const SizedBox(width: 10),
          _buildStatItem('TOTAL', all.length.toString(), AppColors.primary),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.elevation2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.sectionTitle.copyWith(color: AppColors.textMuted, fontSize: 8)),
            const SizedBox(height: 4),
            Text(value, style: AppTextStyles.cardTitle.copyWith(color: color, fontSize: 18)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.elevation2,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              onChanged: (value) => ref.read(memberSearchQueryProvider.notifier).state = value,
              style: AppTextStyles.body,
              decoration: InputDecoration(
                hintText: 'Search by name or phone...',
                hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textMuted),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        _buildPillTabs(ref),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Text('SORT BY', style: AppTextStyles.sectionTitle.copyWith(fontSize: 8)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.elevation2,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Text('Expiry (Soonest)', style: AppTextStyles.bodySmall.copyWith(fontSize: 10, color: AppColors.text, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.textMuted),
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
    final now = ref.watch(clockProvider).now;
    
    // ⚡ Bolt: Consolidated multiple list traversals to compute stats in one pass
    int activeCount = 0;
    int expiringCount = 0;
    int expiredCount = 0;

    for (final m in all) {
      final status = m.getStatus(now);
      if (status == MemberStatus.active) {
        activeCount++;
      } else if (status == MemberStatus.expiring) {
        expiringCount++;
      } else if (status == MemberStatus.expired) {
        expiredCount++;
      }
    }

    final tabs = [
      {'label': 'All', 'count': all.length},
      {'label': 'Active', 'count': activeCount},
      {'label': 'Expiring', 'count': expiringCount},
      {'label': 'Expired', 'count': expiredCount},
    ];
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.elevation1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = selectedTab == index;
          final tab = tabs[index];
          return Expanded(
            child: GestureDetector(
              onTap: () => ref.read(memberTabProvider.notifier).state = index,
              child: Container(
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.primaryGradient : null,
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      tab['label'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${tab['count']})',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w400,
                        color: isSelected ? Colors.white.withValues(alpha: 0.8) : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMemberListContainer(BuildContext context, List<MemberSnapshot> members, WidgetRef ref) {
    if (members.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline_rounded, size: 48, color: AppColors.textMuted.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text('No members found', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
          ],
        ),
      );
    }

    return Column(
      children: List.generate(members.length, (index) {
        final m = members[index];
        final now = ref.watch(clockProvider).now;
        final statusMsg = _getStatusMessage(m, now);
        final statusColor = _getStatusColor(m, now);
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildMemberItem(
            context,
            m,
            m.name.isNotEmpty ? m.name.substring(0, 1).toUpperCase() : '?',
            '${m.planName ?? "N/A"} · Since ${_formatDate(m.joinDate)}',
            statusMsg,
            statusColor,
          ),
        );
      }),
    );
  }

  String _getStatusMessage(MemberSnapshot m, DateTime now) {
    final days = m.getDaysRemaining(now);
    if (days < 0) return 'Expired';
    if (days == 0) return 'Today';
    if (days <= 7) return '$days days';
    return '${days}d';
  }

  Color _getStatusColor(MemberSnapshot m, DateTime now) {
    final status = m.getStatus(now);
    switch (status) {
      case MemberStatus.active: return AppColors.green;
      case MemberStatus.expiring: return AppColors.amber;
      case MemberStatus.expired: return AppColors.red;
      case MemberStatus.pending: return AppColors.text3;
    }
  }

  String _formatDate(DateTime d) => DateFormatter.formatShort(d);

  Widget _buildMemberItem(BuildContext context, MemberSnapshot member, String initials, String subtitle, String status, Color color) {
    return GestureDetector(
      onTap: () => context.push('/gym/member-details/${member.memberId}'),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.elevation2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: AppTextStyles.cardTitle.copyWith(fontSize: 16, color: color),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(member.name, style: AppTextStyles.memberName.copyWith(fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.bodySmall.copyWith(fontSize: 10, color: AppColors.textMuted)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Container(width: 5, height: 5, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(
                    status,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color),
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
