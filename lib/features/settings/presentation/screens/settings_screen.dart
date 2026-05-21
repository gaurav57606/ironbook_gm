import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import 'package:ironbook_gm/core/sync/recovery_service.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/data/sync_worker.dart';
import '../../../../core/providers/member_provider.dart';
import '../../../../core/providers/owner_provider.dart';
import '../../../../core/services/csv_export_service.dart';
import '../../../../core/providers/payment_provider.dart';
import '../widgets/settings_group.dart';
import '../widgets/sync_banner.dart';
import '../widgets/gym_profile_card.dart';
import '../../../../shared/widgets/sync_status_indicator.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isSyncing = false;
  bool _isRecovering = false;

  @override
  Widget build(BuildContext context) {
    final ownerName = ref.watch(ownerProvider.select((o) => o?.ownerName ?? 'Owner'));
    final gymName = ref.watch(ownerProvider.select((o) => o?.gymName ?? 'Raj\'s Fitness'));
    final isPinSetup = ref.watch(authProvider.select((s) => s.isPinSetup));
    final unsyncedCount = ref.watch(unsyncedCountProvider).value ?? 0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
            _buildAppBar(unsyncedCount),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                children: [
                  if (unsyncedCount > 0) SyncBanner(count: unsyncedCount),
                  GymProfileCard(gymName: gymName),
                  _buildAccountSection(ownerName, isPinSetup),
                  _buildGymSettingsSection(gymName),
                  _buildDataSyncSection(),
                  _buildSupportSection(),
                  _buildTroubleshootingSection(),
                  AppSpacing.gapXL,
                  _buildLogoutButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildAppBar(int unsyncedCount) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.screenPadding,
        right: AppSpacing.screenPadding,
        top: AppSpacing.xl,
        bottom: AppSpacing.m,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Settings',
                  style: AppTextStyles.h2.copyWith(fontSize: 28, fontWeight: FontWeight.w900),
                ),
                Text(
                  'Manage your workspace & profile',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => context.push('/notifications'),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.elevation2,
              padding: const EdgeInsets.all(10),
            ),
            icon: Stack(
              children: [
                const Icon(Icons.notifications_none_rounded, color: AppColors.text, size: 22),
                if (unsyncedCount > 0)
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.bg, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const SyncStatusIndicator(),
        ],
      ),
    );
  }

  Widget _buildAccountSection(String ownerName, bool isPinSetup) {
    return SettingsGroup(
      title: 'Security & Access',
      children: [
        SettingsRow(
          icon: Icons.person_outline_rounded,
          label: 'Owner Profile',
          value: ownerName,
          onTap: () => context.push('/settings/profile'),
        ),
        SettingsRow(
          icon: Icons.lock_outline_rounded,
          label: 'Passcode & Biometrics',
          value: isPinSetup ? 'Active' : 'Setup Required',
          onTap: () => context.push('/settings/security'),
        ),
        SettingsRow(
          icon: Icons.notifications_none_rounded,
          label: 'Alert Preferences',
          onTap: () => context.push('/settings/notifications'),
        ),
        SettingsRow(
          icon: Icons.business_center_outlined,
          label: 'Transfer Ownership',
          value: 'Commercial Handover',
          onTap: () => context.push('/settings/transfer'),
          showDivider: false,
        ),
      ],
    );
  }

  Widget _buildGymSettingsSection(String gymName) {
    return SettingsGroup(
      title: 'Business Configuration',
      children: [
        SettingsRow(
          icon: Icons.store_outlined,
          label: 'Gym Branding',
          value: gymName,
          onTap: () => context.push('/settings/gym-profile'),
        ),
        SettingsRow(
          icon: Icons.layers_outlined,
          label: 'Membership Plans',
          value: 'Pricing & Tiers',
          onTap: () => context.push('/settings/plans'),
        ),
        SettingsRow(
          icon: Icons.receipt_long_outlined,
          label: 'Billing Engine',
          value: 'Taxes & Invoicing',
          onTap: () => context.push('/settings/tax-billing'),
          showDivider: false,
        ),
      ],
    );
  }

  Widget _buildDataSyncSection() {
    return SettingsGroup(
      title: 'Infrastructure & Data',
      children: [
        SettingsRow(
          icon: Icons.backup_outlined,
          label: 'Cloud Synchronization',
          value: _isSyncing ? 'Syncing...' : 'Push local changes',
          onTap: _isSyncing ? null : () async {
            setState(() => _isSyncing = true);
            final messenger = ScaffoldMessenger.of(context);
            try {
              await ref.read(syncWorkerProvider).performSync();
              if (context.mounted) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Sync completed successfully.')),
                );
              }
            } catch (e) {
              if (context.mounted) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Sync failed: ${e.toString()}')),
                );
              }
            } finally {
              if (mounted) setState(() => _isSyncing = false);
            }
          },
        ),
        SettingsRow(
          icon: Icons.restore_outlined,
          label: 'Global Data Restore',
          value: _isRecovering ? 'Recovering...' : 'Re-fetch cloud database',
          onTap: _isRecovering ? null : () async {
            setState(() => _isRecovering = true);
            final messenger = ScaffoldMessenger.of(context);
            try {
              await ref.read(recoveryServiceProvider).recoverAll();
              if (context.mounted) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Recovery completed successfully.')),
                );
              }
            } catch (e) {
              if (context.mounted) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Recovery failed: ${e.toString()}')),
                );
              }
            } finally {
              if (mounted) setState(() => _isRecovering = false);
            }
          },
        ),
        SettingsRow(
          icon: Icons.table_view_outlined,
          label: 'Export Records',
          value: 'Members & Payments',
          onTap: () async {
             // Handle both exports or open sub-menu
             _showExportSheet();
          },
        ),
        SettingsRow(
          icon: Icons.vpn_key_outlined,
          label: 'Encrypted Backups',
          value: 'Local .igmb archives',
          onTap: () => context.push('/settings/backup'),
          showDivider: false,
        ),
      ],
    );
  }

  void _showExportSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.elevation2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text('EXPORT DATA', style: AppTextStyles.sectionTitle.copyWith(color: AppColors.primary)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.people_alt_outlined, color: AppColors.text),
              title: const Text('Member List (CSV)', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w700)),
              onTap: () async {
                Navigator.pop(context);
                final members = ref.read(membersProvider);
                await ref.read(csvExportServiceProvider).exportMembers(members);
              },
            ),
            ListTile(
              leading: const Icon(Icons.payment_outlined, color: AppColors.text),
              title: const Text('Payment History (CSV)', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w700)),
              onTap: () async {
                Navigator.pop(context);
                final payments = ref.read(paymentsProvider);
                await ref.read(csvExportServiceProvider).exportPayments(payments);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportSection() {
    return SettingsGroup(
      title: 'Documentation',
      children: [
        SettingsRow(icon: Icons.help_center_outlined, label: 'Technical Support', onTap: () => context.push('/settings/help')),
        SettingsRow(icon: Icons.verified_user_outlined, label: 'Legal & Privacy', onTap: () => context.push('/settings/privacy')),
        SettingsRow(
          icon: Icons.info_outline_rounded,
          label: 'Version Control',
          value: 'v2.4.0 Production Build',
          onTap: () => context.push('/settings/about'),
          showDivider: false,
        ),
      ],
    );
  }

  Widget _buildTroubleshootingSection() {
    return SettingsGroup(
      title: 'Advanced Utilities',
      children: [
        SettingsRow(
          icon: Icons.refresh_rounded,
          label: 'Rebuild Cache',
          value: 'Verify local integrity',
          onTap: () async {
            final messenger = ScaffoldMessenger.of(context);
            messenger.showSnackBar(const SnackBar(content: Text('Rebuilding local cache...')));
            await ref.read(membersProvider.notifier).rebuildCache();
            if (context.mounted) {
              messenger.showSnackBar(const SnackBar(content: Text('Integrity check completed.')));
            }
          },
          showDivider: false,
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppRadius.radiusXL,
          gradient: LinearGradient(
            colors: [
              AppColors.expired.withValues(alpha: 0.05),
              AppColors.expired.withValues(alpha: 0.1),
            ],
          ),
          border: Border.all(color: AppColors.expired.withValues(alpha: 0.2)),
        ),
        child: InkWell(
          onTap: _handleLogout,
          borderRadius: AppRadius.radiusXL,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.logout_rounded, color: AppColors.expired, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'SIGN OUT FROM IRONBOOK',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.expired,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    final unsyncedCount = ref.read(unsyncedCountProvider).value ?? 0;
    if (unsyncedCount > 0) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.elevation2,
          title: Text('Unsynced Changes', style: AppTextStyles.cardTitle),
          content: Text(
            'You have $unsyncedCount unsynced changes. Logging out will permanently WIPE all local data that hasn\'t been pushed to the cloud.\n\nAre you absolutely sure?',
            style: AppTextStyles.bodySmall,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('CANCEL', style: AppTextStyles.label),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('LOGOUT & WIPE', style: AppTextStyles.label.copyWith(color: AppColors.expired)),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    await ref.read(authProvider.notifier).logout();
    if (!mounted) return;
    context.go('/login');
  }
}
