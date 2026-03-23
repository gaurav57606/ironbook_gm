import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../providers/auth_provider.dart';
import '../../../sync/sync_engine.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildProfileCard(context, auth),
          const SizedBox(height: 24),
          _buildSection('App Settings', [
            _buildTile(LucideIcons.bell, 'Notifications', 'Reminders & alerts'),
            _buildTileWithSwitch(
              LucideIcons.fingerprint,
              'Biometric Login',
              'Use fingerprint/face ID',
              auth.settings.useBiometrics,
              (val) => ref.read(authProvider.notifier).setBiometricOptIn(val),
            ),
            _buildTile(
              LucideIcons.receipt,
              'GST Settings',
              'GSTIN & Rates',
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('GST settings coming soon'))),
            ),
          ]),
          const SizedBox(height: 24),
          _buildSection('Data & Backup', [
            _buildTile(
              LucideIcons.cloud,
              'Cloud Sync',
              'Last synced: 2m ago',
              onTap: () {
                SyncEngine.pushPendingEvents();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Syncing data...')));
              },
            ),
            _buildTile(
              LucideIcons.history,
              'Restore Data',
              'Recover from cloud',
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Restore flow coming soon'))),
            ),
          ]),
          const SizedBox(height: 32),
          TextButton.icon(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              context.go('/login');
            },
            icon: const Icon(Icons.logout, color: AppColors.expired),
            label: const Text('Log Out', style: TextStyle(color: AppColors.expired)),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text('Version 2.0.0', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, AuthState auth) {
    final name = auth.owner?.gymName ?? 'My Gym';
    final owner = auth.owner?.ownerName ?? 'Owner';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bg3,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.bg4, width: 0.5),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.bg4,
            child: const Icon(LucideIcons.store, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.cardTitle.copyWith(fontSize: 18)),
                Text('Owner: $owner', style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          IconButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile editing coming soon'))),
            icon: const Icon(LucideIcons.edit3, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(title, style: AppTextStyles.label.copyWith(color: AppColors.textMuted)),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.bg2,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildTile(IconData icon, String title, String subtitle, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textPrimary, size: 22),
      title: Text(title, style: AppTextStyles.label),
      subtitle: Text(subtitle, style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
      trailing: const Icon(LucideIcons.chevronRight, size: 18),
      onTap: onTap ?? () {},
    );
  }

  Widget _buildTileWithSwitch(IconData icon, String title, String subtitle, bool value, Function(bool) onChanged) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textPrimary, size: 22),
      title: Text(title, style: AppTextStyles.label),
      subtitle: Text(subtitle, style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }
}
