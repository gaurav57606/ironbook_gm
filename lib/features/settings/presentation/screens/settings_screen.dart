import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/widgets/status_bar_wrapper.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../sync/recovery_service.dart';
import '../../../../sync/sync_engine.dart';
import 'package:go_router/go_router.dart';
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

    return StatusBarWrapper(
      child: Column(
        children: [
          _buildAppBar(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 20),
              children: [
                _buildGymProfileCard(auth),
                _buildSettingsGroup('Account', [
                  _buildSettingsRow(Icons.person_outline, 'My Profile',
                      auth.owner?.ownerName ?? 'Owner', onTap: () => context.push('/settings/profile')),
                  _buildSettingsRow(Icons.lock_outline, 'Security & PIN',
                      auth.isPinSetup ? 'Set' : 'Not Set', onTap: () => context.push('/settings/security')),
                  _buildSettingsRow(
                      Icons.notifications_none, 'Notifications', null, onTap: () => context.push('/settings/notifications')),
                ]),
                _buildSettingsGroup('Gym Settings', [
                  _buildSettingsRow(Icons.fitness_center, 'Gym Profile',
                      auth.owner?.gymName ?? 'Raj\'s Fitness', onTap: () => context.push('/settings/gym-profile')),
                  _buildSettingsRow(Icons.layers_outlined, 'Subscription Plans',
                      'Live Sync Active', onTap: () => context.push('/settings/subscription')),
                  _buildSettingsRow(
                      Icons.receipt_long_outlined, 'Tax & Billing', 'GST 18%',
                      onTap: () => context.push('/settings/tax-billing')),
                ]),
                _buildSettingsGroup('Data & Sync', [
                  _buildSettingsRow(
                      Icons.cloud_upload_outlined,
                      'Backup to Cloud',
                      'Push pending changes', onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    messenger.showSnackBar(const SnackBar(
                        content: Text('Starting cloud sync...')));
                    await ref.read(syncEngineProvider).pushPendingEvents();
                    messenger.showSnackBar(
                        const SnackBar(content: Text('Sync completed.')));
                  }),
                  _buildSettingsRow(
                      Icons.cloud_download_outlined,
                      'Restore from Cloud',
                      'Download all data', onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    messenger.showSnackBar(const SnackBar(
                        content: Text('Recovering events from Firestore...')));
                    await ref.read(recoveryServiceProvider).recoverAll();
                    messenger.showSnackBar(
                        const SnackBar(content: Text('Recovery completed.')));
                  }),
                  _buildSettingsRow(
                      Icons.security_outlined,
                      'Audit Mode (No Auth)',
                      auth.settings.auditMode ? 'Enabled' : 'Disabled',
                      onTap: () async {
                    await ref.read(authProvider.notifier).updateSettings(
                      auth.settings.copyWith(auditMode: !auth.settings.auditMode),
                    );
                  }),
                ]),
                _buildSettingsGroup('Support', [
                  _buildSettingsRow(Icons.help_outline, 'Help Center', null, onTap: () => context.push('/settings/help')),
                  _buildSettingsRow(
                      Icons.info_outline, 'About IronBook GM', 'v2.4.0', onTap: () => context.push('/settings/about')),
                ]),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: TextButton(
                    onPressed: () async {
                      await fb.FirebaseAuth.instance.signOut();
                      if (!context.mounted) return;
                      context.go('/login');
                    },
                    child: const Text('Log Out',
                        style: TextStyle(
                            color: AppColors.red,
                            fontWeight: FontWeight.w600,
                            fontSize: 11)),
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
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Text(
            'Settings',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.text),
          ),
        ],
      ),
    );
  }

  Widget _buildGymProfileCard(AuthState auth) {
    return GestureDetector(
      onTap: () => context.push('/settings/gym-profile'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.bg3, AppColors.bg4],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.orange,
                borderRadius: BorderRadius.circular(11),
              ),
              alignment: Alignment.center,
              child: Text(
                  (auth.owner?.gymName ?? 'R').substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(auth.owner?.gymName ?? 'Raj\'s Fitness',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text)),
                  const Text('Solo Owner Edition · Pro Plan',
                      style: TextStyle(fontSize: 9, color: AppColors.text2)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 16, color: AppColors.text3),
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: AppColors.text3,
                letterSpacing: 0.5),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.bg3,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingsRow(IconData icon, String label, String? value,
      {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.bg4,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(icon, size: 12, color: AppColors.text2),
            ),
            const SizedBox(width: 8),
            Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.text))),
            if (value != null)
              Text(value,
                  style: const TextStyle(fontSize: 9, color: AppColors.text3)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 14, color: AppColors.text3),
          ],
        ),
      ),
    );
  }
}
