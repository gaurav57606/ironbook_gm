import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../../shared/widgets/status_bar_wrapper.dart';
import '../../../../core/providers/owner_provider.dart';
import '../../../../core/data/local/models/owner_profile_model.dart';
import '../../../../core/providers/member_provider.dart';
import '../../../../core/providers/payment_provider.dart';
import '../../../../core/providers/sync_status_provider.dart';
import '../../../../core/data/local/models/member_snapshot_model.dart';

class CharacterCreationScreen extends ConsumerWidget {
  const CharacterCreationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final owner = ref.watch(ownerProvider);
    final members = ref.watch(membersProvider);
    final payments = ref.watch(paymentsProvider);
    final syncStatus = ref.watch(syncStatusProvider);

    // ⚡ Bolt: Cache DateTime.now() outside the loop and use getStatus()
    // to avoid O(N) DateTime object allocations during screen builds.
    final now = DateTime.now();
    int activeMembers = 0;
    for (final m in members) {
      if (m.getStatus(now) == MemberStatus.active) {
        activeMembers++;
      }
    }

    // Dynamic Metric Calculation
    final totalMembers = members.length;
    final endurance = totalMembers > 0 ? (activeMembers / totalMembers) : 0.5;

    final totalRevenue = payments.fold(0.0, (sum, p) => sum + p.amount);
    final strength = (totalRevenue / 50000).clamp(
      0.1,
      1.0,
    ); // 50k as baseline for 100% strength

    final unsynced = syncStatus.unsyncedCount;
    final dexterity = (1.0 - (unsynced / 50)).clamp(
      0.1,
      1.0,
    ); // 50 items as baseline for 0% dexterity

    return StatusBarWrapper(
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withValues(alpha: 0.15),
                AppColors.bg,
                AppColors.bg,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Gym Leader Profile',
                        style: AppTextStyles.h1.copyWith(fontSize: 24),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.bg2,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(
                          Icons.shield_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      _buildCharacterSlot(
                        context,
                        'Iron Warrior',
                        'Level ${owner?.level ?? 1} Gym Leader',
                        Icons.shield_rounded,
                        owner?.selectedCharacterId == 'warrior',
                        onTap: () => _updateCharacter(ref, 'warrior'),
                      ),
                      const SizedBox(height: 16),
                      _buildCharacterSlot(
                        context,
                        'Agility Master',
                        owner?.level != null && owner!.level >= 5
                            ? 'Unlocked'
                            : 'Unlocks at Level 5',
                        Icons.bolt_rounded,
                        owner?.selectedCharacterId == 'agility',
                        locked: (owner?.level ?? 1) < 5,
                        onTap: () => _updateCharacter(ref, 'agility'),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          const Icon(
                            Icons.analytics_rounded,
                            color: AppColors.textMuted,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'ENTERPRISE VITALITY',
                            style: AppTextStyles.sectionTitle.copyWith(
                              letterSpacing: 2.0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildMetricRow(
                        'STRENGTH (REVENUE)',
                        strength,
                        AppColors.primary,
                      ),
                      _buildMetricRow(
                        'ENDURANCE (RETENTION)',
                        endurance,
                        Colors.blue,
                      ),
                      _buildMetricRow(
                        'DEXTERITY (INTEGRITY)',
                        dexterity,
                        Colors.green,
                      ),

                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              color: AppColors.primary,
                              size: 24,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Stats are calculated from real business metrics. Improve your sync health and revenue to increase your levels.',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _updateCharacter(WidgetRef ref, String id) {
    final current = ref.read(ownerProvider);
    if (current == null) return;

    // In a real app, we'd check level requirements here too
    if (id == 'agility' && current.level < 5) return;

    ref
        .read(ownerProvider.notifier)
        .updateOwner(
          OwnerProfile(
            gymName: current.gymName,
            ownerName: current.ownerName,
            phone: current.phone,
            address: current.address,
            gstin: current.gstin,
            bankName: current.bankName,
            accountNumber: current.accountNumber,
            ifsc: current.ifsc,
            upiId: current.upiId,
            level: current.level,
            exp: current.exp,
            strength: current.strength,
            endurance: current.endurance,
            dexterity: current.dexterity,
            selectedCharacterId: id,
          ),
        );
  }

  Widget _buildCharacterSlot(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    bool active, {
    bool locked = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.bg2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? AppColors.primary.withValues(alpha: 0.5)
                : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: active
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: active ? AppColors.primary : AppColors.textMuted,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.h3.copyWith(
                      color: active ? Colors.white : AppColors.textMuted,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            if (locked)
              const Icon(
                Icons.lock_outline_rounded,
                color: AppColors.textMuted,
                size: 20,
              )
            else if (active)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTextStyles.sectionTitle.copyWith(
                  fontSize: 10,
                  color: Colors.white,
                ),
              ),
              Text(
                '${(value * 100).toInt()}%',
                style: AppTextStyles.sectionTitle.copyWith(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              Container(
                height: 4,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              FractionallySizedBox(
                widthFactor: value,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
