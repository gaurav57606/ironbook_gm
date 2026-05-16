import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_shadows.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import 'package:ironbook_gm/core/providers/member_provider.dart';
import 'package:ironbook_gm/core/data/local/models/member_snapshot_model.dart';
import '../../../../shared/utils/clock.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/sync_status_indicator.dart';
import '../widgets/member_list_item.dart';

class MembersListScreen extends ConsumerWidget {
  const MembersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              _buildQuickStats(context),
              _buildSearchAndFilters(context),
              Expanded(
                child: Consumer(
                  builder: (context, ref, _) {
                    final filteredMembers = ref.watch(filteredMembersProvider);
                    final allMembersCount = ref.watch(membersProvider.select((m) => m.length));
                    
                    if (filteredMembers.isEmpty) {
                      return const AppEmptyState(
                        title: 'No members found',
                        icon: Icons.people_outline_rounded,
                      );
                    }
                    
                    return ListView.builder(
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
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: MemberListItem(memberId: filteredMembers[index].memberId),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, AppSpacing.l, AppSpacing.screenPadding, AppSpacing.m),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Members', style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.w900)),
              Text('Gym Membership Management', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
            ],
          ),
          const SyncStatusIndicator(),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final stats = ref.watch(memberStatsProvider);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding, vertical: AppSpacing.m),
          child: Row(
            children: [
              _buildStatItem('ACTIVE', stats.activeCount.toString(), AppColors.active),
              AppSpacing.gapS,
              _buildStatItem('EXPIRING', stats.expiringCount.toString(), AppColors.expiring),
              AppSpacing.gapS,
              _buildStatItem('TOTAL', stats.totalCount.toString(), AppColors.primary),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.m, horizontal: AppSpacing.s),
        decoration: BoxDecoration(
          color: AppColors.elevation2,
          borderRadius: AppRadius.radiusXL,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.sectionTitle.copyWith(color: AppColors.textMuted, fontSize: 8)),
            const SizedBox(height: 4),
            Text(value, style: AppTextStyles.h3.copyWith(color: color, fontSize: 20, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding, vertical: AppSpacing.s),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.elevation2,
              borderRadius: AppRadius.radiusL,
              border: Border.all(color: AppColors.border),
            ),
            child: Consumer(
              builder: (context, ref, _) {
                return TextField(
                  onChanged: (value) => ref.read(memberSearchQueryProvider.notifier).state = value,
                  style: AppTextStyles.body,
                  decoration: InputDecoration(
                    hintText: 'Search by name or phone...',
                    hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textMuted),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                );
              },
            ),
          ),
        ),
        _buildPillTabs(context),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding, vertical: AppSpacing.m),
          child: Row(
            children: [
              Consumer(
                builder: (context, ref, _) {
                  final sort = ref.watch(memberSortProvider);
                  final labels = {
                    MemberSortOption.expiryAsc: 'Expiry (Soonest)',
                    MemberSortOption.expiryDesc: 'Expiry (Latest)',
                    MemberSortOption.nameAz: 'Name (A–Z)',
                    MemberSortOption.nameZa: 'Name (Z–A)',
                    MemberSortOption.joinNewest: 'Joined (Newest)',
                  };
                  return GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: AppColors.elevation1,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (_) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Text('SORT BY',
                                style: AppTextStyles.sectionTitle.copyWith(
                                  color: AppColors.textMuted, letterSpacing: 1.2)),
                            ),
                            const Divider(height: 1),
                            ...MemberSortOption.values.map((opt) => ListTile(
                              tileColor: AppColors.elevation1,
                              title: Text(labels[opt]!, style: AppTextStyles.bodyMedium),
                              trailing: sort == opt
                                ? const Icon(Icons.check_rounded, color: AppColors.primary, size: 18)
                                : null,
                              onTap: () {
                                ref.read(memberSortProvider.notifier).state = opt;
                                Navigator.pop(context);
                              },
                            )),
                            const SizedBox(height: 16),
                          ],
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Text('SORT BY', style: AppTextStyles.sectionTitle.copyWith(letterSpacing: 1.0)),
                        AppSpacing.gapS,
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.elevation2,
                            borderRadius: AppRadius.radiusM,
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Text(
                                labels[sort]!,
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontSize: 10,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              AppSpacing.gapXS,
                              const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.primary),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPillTabs(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final stats = ref.watch(memberStatsProvider);
        final selectedTab = ref.watch(memberTabProvider);
        
        final tabs = [
          {'label': 'All', 'count': stats.totalCount},
          {'label': 'Active', 'count': stats.activeCount},
          {'label': 'Expiring', 'count': stats.expiringCount},
          {'label': 'Expired', 'count': stats.expiredCount},
        ];
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          height: 44,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.elevation1,
            borderRadius: AppRadius.radiusL,
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
                    decoration: BoxDecoration(
                      gradient: isSelected ? AppColors.primaryGradient : null,
                      borderRadius: AppRadius.radiusM,
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ] : [],
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          tab['label'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${tab['count']}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            color: isSelected ? Colors.white.withValues(alpha: 0.7) : AppColors.textMuted,
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
      },
    );
  }
}









