import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/status_bar_wrapper.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../sync/recovery_service.dart';
import '../../../../data/sync_worker.dart';
import '../../../../providers/member_provider.dart';
import '../../../../core/services/csv_export_service.dart';
import 'package:go_router/go_router.dart';
import '../../../../providers/payment_provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final unsyncedCount = ref.watch(unsyncedCountProvider).value ?? 0;

    return StatusBarWrapper(
      child: Container(
        decoration: BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 40),
                children: [
                  if (unsyncedCount > 0) _buildSyncBanner(unsyncedCount),
                  _buildGymProfileCard(auth),
                  _buildSettingsGroup('Account', [
                    _buildSettingsRow(
                      Icons.person_outline_rounded,
                      'My Profile',
                      auth.owner?.ownerName ?? 'Owner',
                      onTap: () => context.push('/settings/profile'),
                    ),
                    _buildSettingsRow(
                      Icons.lock_outline_rounded,
                      'Security & PIN',
                      auth.isPinSetup ? 'Set' : 'Not Set',
                      onTap: () => context.push('/settings/security'),
                    ),
                    _buildSettingsRow(
                      Icons.notifications_none_rounded,
                      'Notifications',
                      null,
                      onTap: () => context.push('/settings/notifications'),
                    ),
                    _buildSettingsRow(
                      Icons.transfer_within_a_station_rounded,
                      'Transfer Ownership',
                      'Business Handover',
                      onTap: () => context.push('/settings/transfer'),
                    ),
                  ]),
                  _buildSettingsGroup('Gym Settings', [
                    _buildSettingsRow(
                      Icons.fitness_center_rounded,
                      'Gym Profile',
                      auth.owner?.gymName ?? 'Raj\'s Fitness',
                      onTap: () => context.push('/settings/gym-profile'),
                    ),
                    _buildSettingsRow(
                      Icons.layers_outlined,
                      'Subscription Plans',
                      'Configure Plans',
                      onTap: () => context.push('/settings/plans'),
                    ),
                    _buildSettingsRow(
                      Icons.receipt_long_outlined,
                      'Tax & Billing',
                      'GST 18%',
                      onTap: () => context.push('/settings/tax-billing'),
                    ),
                  ]),
                  _buildSettingsGroup('Data & Sync', [
                    _buildSettingsRow(
                      Icons.cloud_upload_outlined,
                      'Backup to Cloud',
                      'Push pending changes',
                      onTap: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        messenger.showSnackBar(const SnackBar(content: Text('Starting cloud sync...')));
                        await ref.read(syncWorkerProvider).performSync();
                        if (context.mounted) {
                          messenger.showSnackBar(const SnackBar(content: Text('Sync completed.')));
                        }
                      },
                    ),
                    _buildSettingsRow(
                      Icons.cloud_download_outlined,
                      'Restore from Cloud',
                      'Download all data',
                      onTap: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        messenger.showSnackBar(const SnackBar(content: Text('Recovering events from Firestore...')));
                        await ref.read(recoveryServiceProvider).recoverAll();
                        messenger.showSnackBar(const SnackBar(content: Text('Recovery completed.')));
                      },
                    ),
                    _buildSettingsRow(
                      Icons.file_download_outlined,
                      'Export Member List',
                      'CSV Format',
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
                    _buildSettingsRow(
                      Icons.payments_outlined,
                      'Export Payment History',
                      'CSV Format',
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
                  ]),
                  _buildSettingsGroup('Support', [
                    _buildSettingsRow(Icons.help_outline_rounded, 'Help Center', null, onTap: () => context.push('/settings/help')),
                    _buildSettingsRow(Icons.info_outline_rounded, 'About IronBook GM', 'v2.4.0', onTap: () => context.push('/settings/about')),
                  ]),
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: TextButton(
                      onPressed: () async {
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
                        if (!context.mounted) return;
                        context.go('/login');
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.expired,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
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
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncBanner(int count) {
    final isCritical = count > 10;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (isCritical ? AppColors.expired : AppColors.expiring).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (isCritical ? AppColors.expired : AppColors.expiring).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            isCritical ? Icons.warning_amber_rounded : Icons.sync_problem_rounded, 
            color: isCritical ? AppColors.expired : AppColors.expiring, 
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCritical ? 'CRITICAL: DO NOT UNINSTALL' : 'Sync Pending',
                  style: AppTextStyles.label.copyWith(
                    fontSize: 12,
                    color: isCritical ? AppColors.expired : AppColors.expiring,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isCritical 
                    ? 'You have $count unsynced changes. Uninstalling will result in PERMANENT data loss.'
                    : '$count changes local-only. Backup to cloud for safety.',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 10,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Row(
        children: [
          Text(
            'Settings',
            style: AppTextStyles.h2.copyWith(fontSize: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildGymProfileCard(AuthState auth) {
    final String initial = (auth.owner?.gymName ?? 'R').substring(0, 1).toUpperCase();
    return GestureDetector(
      onTap: () => context.push('/settings/gym-profile'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.elevation1,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    auth.owner?.gymName ?? 'Raj\'s Fitness',
                    style: AppTextStyles.cardTitle.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Solo Owner Edition • Pro Plan',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 24, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          child: Text(
            title.toUpperCase(),
            style: AppTextStyles.sectionTitle.copyWith(
              fontSize: 10,
              letterSpacing: 1.5,
              color: AppColors.textMuted,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.elevation1,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingsRow(IconData icon, String label, String? value, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.5))),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.elevation2,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (value != null)
              Text(
                value,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
              ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
