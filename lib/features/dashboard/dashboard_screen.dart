import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../providers/member_provider.dart';
import '../../data/local/models/member_snapshot_model.dart';
import '../../data/sync_worker.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncWorkerProvider).performSync();
    });
  }

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(membersProvider);
    final activeCount = members.where((m) => m.status == MemberStatus.active).length;
    final expiringCount = members.where((m) => m.status == MemberStatus.expiring).length;
    final expiredCount = members.where((m) => m.status == MemberStatus.expired).length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: ref.watch(unsyncedCountProvider).when(
              data: (count) => count > 0 
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.orange.withOpacity(0.15), AppColors.orange.withOpacity(0.05)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.sync_problem_rounded, color: AppColors.orange, size: 24),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$count Unsynced Changes',
                                style: AppTextStyles.label.copyWith(
                                  color: AppColors.orange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                count > 10 
                                  ? 'CRITICAL: Do not uninstall the app. Data loss will occur.'
                                  : 'Tap to sync your local changes to the cloud.',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.orange.withValues(alpha: 0.8),
                                  fontSize: 12,
                                  fontWeight: count > 10 ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => ref.read(syncWorkerProvider).performSync(),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.orange,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            backgroundColor: AppColors.orange.withValues(alpha: 0.1),
                            shape: RoundedRectangleMask(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('SYNC NOW'),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuickStats(activeCount, expiringCount, expiredCount),
                  const SizedBox(height: 32),
                  Text('Recent Members', style: AppTextStyles.cardTitle),
                  const SizedBox(height: 16),
                  if (members.isEmpty)
                    Center(child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Text('No members yet.', style: AppTextStyles.bodySmall),
                    ))
                  else
                    ...members.take(10).map((m) => _buildMemberCard(context, m)),
                  const SizedBox(height: 80), 
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Quick Add', style: AppTextStyles.label.copyWith(color: Colors.white)),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 140,
      backgroundColor: AppColors.bg,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Text('IRONBOOK GM', style: AppTextStyles.cardTitle.copyWith(fontSize: 18, letterSpacing: 1.2)),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.bg, AppColors.bg3],
            ),
          ),
        ),
      ),
      actions: [
        ref.watch(unsyncedCountProvider).when(
          data: (count) => count > 0 
            ? Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Center(
                  child: Tooltip(
                    message: '$count changes unsynced',
                    child: InkWell(
                      onTap: () => ref.read(syncWorkerProvider).performSync(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.orange.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.cloud_upload_outlined, size: 14, color: AppColors.orange),
                            const SizedBox(width: 4),
                            Text('$count', style: AppTextStyles.label.copyWith(color: AppColors.orange, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink(),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        IconButton(
          onPressed: () => context.push('/settings'),
          icon: const Icon(Icons.settings_outlined, color: AppColors.textMuted),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildQuickStats(int active, int expiring, int expired) {
    return Row(
      children: [
        _buildStatItem(active.toString(), 'ACTIVE', AppColors.active),
        const SizedBox(width: 12),
        _buildStatItem(expiring.toString(), 'EXPIRING', AppColors.expiring),
        const SizedBox(width: 12),
        _buildStatItem(expired.toString(), 'EXPIRED', AppColors.expired),
      ],
    );
  }

  Widget _buildStatItem(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bg3,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.bg4, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: AppTextStyles.heroNumber.copyWith(color: color, fontSize: 28)),
            const SizedBox(height: 4),
            Text(label, style: AppTextStyles.label.copyWith(fontSize: 10, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberCard(BuildContext context, MemberSnapshot member) {
    final statusColor = member.status == MemberStatus.active 
        ? AppColors.active 
        : (member.status == MemberStatus.expiring ? AppColors.expiring : AppColors.expired);
    
    final statusText = member.status == MemberStatus.active
        ? 'Active'
        : (member.status == MemberStatus.expiring 
            ? 'Expiring in ${member.daysRemaining} days' 
            : 'Expired ${member.daysRemaining.abs()} days ago');

    return InkWell(
      onTap: () => context.push('/members/${member.memberId}'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bg2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.bg4, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.bg3,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.person_outline, color: AppColors.textMuted),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(member.name, style: AppTextStyles.cardTitle.copyWith(fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(statusText, style: AppTextStyles.bodySmall.copyWith(color: statusColor, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
