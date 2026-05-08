import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import 'package:ironbook_gm/core/sync/recovery_service.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../../shared/widgets/status_bar_wrapper.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/data/sync_worker.dart';
import '../../../../core/providers/member_provider.dart';
import '../../../../core/providers/owner_provider.dart';
import '../../../../core/services/csv_export_service.dart';
import '../../../../core/providers/payment_provider.dart';
import '../widgets/settings_group.dart';
import '../widgets/sync_banner.dart';
import '../widgets/gym_profile_card.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final ownerName = ref.watch(ownerProvider.select((o) => o?.ownerName ?? 'Owner'));
    final gymName = ref.watch(ownerProvider.select((o) => o?.gymName ?? 'Raj\'s Fitness'));
    final isPinSetup = ref.watch(authProvider.select((s) => s.isPinSetup));
    final unsyncedCount = ref.watch(unsyncedCountProvider).value ?? 0;

    return StatusBarWrapper(
      child: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: Column(
          children: [
            _buildAppBar(),
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
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding, vertical: AppSpacing.m),
      child: Row(
        children: [
          Text(
            'Settings',
            style: AppTextStyles.h2.copyWith(fontSize: 24, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection(String ownerName, bool isPinSetup) {
    return SettingsGroup(
      title: 'Account & Security',
      children: [
        SettingsRow(
          icon: Icons.person_outline_rounded,
          label: 'My Profile',
          value: ownerName,
          onTap: () => context.push('/settings/profile'),
        ),
        SettingsRow(
          icon: Icons.lock_outline_rounded,
          label: 'Security & PIN',
          value: isPinSetup ? 'Set' : 'Not Set',
          onTap: () => context.push('/settings/security'),
        ),
        SettingsRow(
          icon: Icons.notifications_none_rounded,
          label: 'Notifications',
          onTap: () => context.push('/settings/notifications'),
        ),
        SettingsRow(
          icon: Icons.transfer_within_a_station_rounded,
          label: 'Transfer Ownership',
          value: 'Business Handover',
          onTap: () => context.push('/settings/transfer'),
          showDivider: false,
        ),
      ],
    );
  }

  Widget _buildGymSettingsSection(String gymName) {
    return SettingsGroup(
      title: 'Gym Settings',
      children: [
        SettingsRow(
          icon: Icons.fitness_center_rounded,
          label: 'Gym Profile',
          value: gymName,
          onTap: () => context.push('/settings/gym-profile'),
        ),
        SettingsRow(
          icon: Icons.layers_outlined,
          label: 'Subscription Plans',
          value: 'Configure Plans',
          onTap: () => context.push('/settings/plans'),
        ),
        SettingsRow(
          icon: Icons.receipt_long_outlined,
          label: 'Tax & Billing',
          value: 'GST 18%',
          onTap: () => context.push('/settings/tax-billing'),
          showDivider: false,
        ),
      ],
    );
  }

  Widget _buildDataSyncSection() {
    return SettingsGroup(
      title: 'Data & Sync',
      children: [
        SettingsRow(
          icon: Icons.cloud_upload_outlined,
          label: 'Backup to Cloud',
          value: 'Push pending changes',
          onTap: () async {
            final messenger = ScaffoldMessenger.of(context);
            messenger.showSnackBar(const SnackBar(content: Text('Starting cloud sync...')));
            await ref.read(syncWorkerProvider).performSync();
            if (context.mounted) {
              messenger.showSnackBar(const SnackBar(content: Text('Sync completed.')));
            }
          },
        ),
        SettingsRow(
          icon: Icons.cloud_download_outlined,
          label: 'Restore from Cloud',
          value: 'Download all data',
          onTap: () async {
            final messenger = ScaffoldMessenger.of(context);
            messenger.showSnackBar(const SnackBar(content: Text('Recovering events from Firestore...')));
            await ref.read(recoveryServiceProvider).recoverAll();
            messenger.showSnackBar(const SnackBar(content: Text('Recovery completed.')));
          },
        ),
        SettingsRow(
          icon: Icons.file_download_outlined,
          label: 'Export Member List',
          value: 'CSV Format',
          onTap: () async {
            final messenger = ScaffoldMessenger.of(context);
            messenger.showSnackBar(const SnackBar(content: Text('Generating CSV...')));
            try {
              final members = ref.read(membersProvider);
              await ref.read(csvExportServiceProvider).exportMembers(members);
            } catch (e) {
              messenger.showSnackBar(SnackBar(content: Text('Export failed: $e')));
            }
          },
        ),
        SettingsRow(
          icon: Icons.payments_outlined,
          label: 'Export Payment History',
          value: 'CSV Format',
          onTap: () async {
            final messenger = ScaffoldMessenger.of(context);
            messenger.showSnackBar(const SnackBar(content: Text('Generating Payments CSV...')));
            try {
              final payments = ref.read(paymentsProvider);
              await ref.read(csvExportServiceProvider).exportPayments(payments);
            } catch (e) {
              messenger.showSnackBar(SnackBar(content: Text('Export failed: $e')));
            }
          },
        ),
        SettingsRow(
          icon: Icons.enhanced_encryption_outlined,
          label: 'Offline Backup (Encrypted)',
          value: 'Local .igmb file',
          onTap: () => context.push('/settings/backup'),
          showDivider: false,
        ),
      ],
    );
  }

  Widget _buildSupportSection() {
    return SettingsGroup(
      title: 'Support',
      children: [
        SettingsRow(icon: Icons.help_outline_rounded, label: 'Help Center', onTap: () => context.push('/settings/help')),
        SettingsRow(icon: Icons.policy_outlined, label: 'Privacy Policy', onTap: () => context.push('/settings/privacy')),
        SettingsRow(icon: Icons.description_outlined, label: 'Terms of Service', onTap: () => context.push('/settings/terms')),
        SettingsRow(
          icon: Icons.info_outline_rounded,
          label: 'About IronBook GM',
          value: 'v2.4.0',
          onTap: () => context.push('/settings/about'),
          showDivider: false,
        ),
      ],
    );
  }

  Widget _buildTroubleshootingSection() {
    return SettingsGroup(
      title: 'Troubleshooting',
      children: [
        SettingsRow(
          icon: Icons.rebase_edit,
          label: 'Rebuild Local Database',
          value: 'Fix data discrepancies',
          onTap: () async {
            final messenger = ScaffoldMessenger.of(context);
            messenger.showSnackBar(const SnackBar(content: Text('Rebuilding cache from event log...')));
            await ref.read(membersProvider.notifier).rebuildCache();
            if (context.mounted) {
              messenger.showSnackBar(const SnackBar(content: Text('Database rebuilt and verified.')));
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
      child: TextButton(
        onPressed: _handleLogout,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.expired,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.radiusM,
            side: BorderSide(color: AppColors.expired.withValues(alpha: 0.2)),
          ),
        ),
        child: Text(
          'Log Out',
          style: AppTextStyles.body.copyWith(
            color: AppColors.expired,
            fontWeight: FontWeight.w700,
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
            'You have $unsyncedCount unsynced changes. Loging out will WIPE all local data that hasn\'t been pushed to the cloud.\n\nAre you absolutely sure?',
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
