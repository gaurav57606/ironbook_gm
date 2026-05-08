import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_shadows.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import 'package:ironbook_gm/core/providers/member_provider.dart';
import 'package:ironbook_gm/core/data/local/models/member_snapshot_model.dart';
import '../../../../shared/utils/date_formatter.dart';
import '../../../../shared/utils/clock.dart';
import 'package:go_router/go_router.dart';
import '../widgets/member_list_item.dart';

class MembersListScreen extends ConsumerWidget {
  const MembersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredMembers = ref.watch(filteredMembersProvider);
    // ⚡ Bolt: Use .select() to avoid rebuilds when member data changes but count stays same
    final allMembersCount = ref.watch(membersProvider.select((m) => m.length));

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
              child: filteredMembers.isEmpty 
                ? const AppEmptyState(
                    title: 'No members found',
                    icon: Icons.people_outline_rounded,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding, vertical: AppSpacing.s),
                    itemCount: filteredMembers.length + 1,
                    itemBuilder: (context, index) {
                      if (index == filteredMembers.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                          child: Center(
                            child: Text(
                              'Showing ${filteredMembers.length} of $allMembersCount members',
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                            ),
                          ),
                        );
                      }
                      return MemberListItem(member: filteredMembers[index]);
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.screenPadding, right: AppSpacing.screenPadding, top: AppSpacing.xxxl, bottom: AppSpacing.s),
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
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding, vertical: AppSpacing.s),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: AppRadius.radiusM,
                boxShadow: AppShadows.primary,
              ),
              child: const Row(
                children: [
                  Icon(Icons.add_rounded, size: 16, color: Colors.white),
                  AppSpacing.gapS,
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding, vertical: AppSpacing.m),
      child: Row(
        children: [
          _buildStatItem('ACTIVE', active.toString(), AppColors.active),
          AppSpacing.gapS,
          _buildStatItem('EXPIRING', expiring.toString(), AppColors.expiring),
          AppSpacing.gapS,
          _buildStatItem('TOTAL', all.length.toString(), AppColors.primary),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.m),
        decoration: BoxDecoration(
          color: AppColors.elevation2,
          borderRadius: AppRadius.radiusXL,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.sectionTitle.copyWith(color: AppColors.textMuted)),
            AppSpacing.gapXS,
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
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding, vertical: AppSpacing.s),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.elevation2,
              borderRadius: AppRadius.radiusL,
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
                contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
              ),
            ),
          ),
        ),
        _buildPillTabs(ref),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding, vertical: AppSpacing.m),
          child: Row(
            children: [
              Text('SORT BY', style: AppTextStyles.sectionTitle),
              AppSpacing.gapS,
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.elevation2,
                  borderRadius: AppRadius.radiusS,
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Text('Expiry (Soonest)', style: AppTextStyles.bodySmall.copyWith(fontSize: 10, color: AppColors.text, fontWeight: FontWeight.w600)),
                    AppSpacing.gapXS,
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
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.elevation1,
        borderRadius: AppRadius.radiusM,
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
                    AppSpacing.gapXS,
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
}









