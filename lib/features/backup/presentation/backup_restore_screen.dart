import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/status_bar_wrapper.dart';
import '../services/backup_coordinator.dart';
import '../services/backup_encryption_service.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/sync_status_provider.dart';
import 'package:intl/intl.dart';

class BackupRestoreScreen extends ConsumerStatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  ConsumerState<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends ConsumerState<BackupRestoreScreen> {
  bool _isLoading = false;

  Future<void> _handleCreateBackup() async {
    final password = await _showPasswordDialog(
      title: 'Encrypt Backup',
      description: 'Set a password to protect your gym data. This password will be required to restore the backup.',
      confirmLabel: 'CREATE BACKUP',
    );

    if (password == null || password.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(backupCoordinatorProvider).exportBackup(password);
      if (mounted) {
        _showSuccessOverlay('Backup Created Successfully');
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Backup failed: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRestoreBackup() async {
     // Warning Dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.elevation2,
        title: Text('Wipe & Restore?', style: AppTextStyles.cardTitle),
        content: Text(
          'Restoring from a backup will PERMANENTLY WIPE all current local data and replace it with the backup content.\n\nThis action cannot be undone.',
          style: AppTextStyles.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('CANCEL', style: AppTextStyles.label),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('WIPE & RESTORE', style: AppTextStyles.label.copyWith(color: AppColors.expired)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final password = await _showPasswordDialog(
      title: 'Decrypt Backup',
      description: 'Enter the password used when creating this backup file.',
      confirmLabel: 'RESTORE DATA',
    );

    if (password == null || password.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(backupCoordinatorProvider).importBackup(password);
      if (mounted) {
        _showSuccessOverlay('Data Restored Successfully');
      }
    } catch (e) {
      if (mounted) {
        if (e is InvalidBackupPasswordException) {
          _showErrorDialog('Invalid password. Decryption failed.');
        } else {
          _showErrorDialog('Restore failed: $e');
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String?> _showPasswordDialog({
    required String title,
    required String description,
    required String confirmLabel,
  }) {
    final controller = TextEditingController();
    bool obscure = true;

    return showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.elevation2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(title, style: AppTextStyles.cardTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(description, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                obscureText: obscure,
                style: AppTextStyles.body,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Minimum 8 characters',
                  suffixIcon: IconButton(
                    icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: AppColors.textMuted),
                    onPressed: () => setState(() => obscure = !obscure),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('CANCEL', style: AppTextStyles.label),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.length < 8) {
                   ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(content: Text('Password must be at least 8 characters'))
                   );
                   return;
                }
                Navigator.pop(context, controller.text);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(confirmLabel, style: AppTextStyles.label.copyWith(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessOverlay(String message) {
     ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.elevation2,
        title: Text('Error', style: AppTextStyles.cardTitle.copyWith(color: AppColors.expired)),
        content: Text(message, style: AppTextStyles.bodySmall),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: AppTextStyles.label),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StatusBarWrapper(
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text('Backup & Restore', style: AppTextStyles.h2.copyWith(fontSize: 20)),
              ),
              body: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                   _buildAlertBanner(),
                   const SizedBox(height: 32),
                   _buildStatusSection(),
                   const SizedBox(height: 32),
                   _buildActionCard(
                     icon: Icons.cloud_upload_rounded,
                     title: 'Create Encrypted Backup',
                     subtitle: 'Securely package your data into a .igmb file that you can store anywhere.',
                     onTap: _handleCreateBackup,
                   ),
                   const SizedBox(height: 20),
                   _buildActionCard(
                     icon: Icons.settings_backup_restore_rounded,
                     title: 'Restore from File',
                     subtitle: 'Import data from a previously created .igmb backup file.',
                     onTap: _handleRestoreBackup,
                     isWarning: true,
                   ),
                   const SizedBox(height: 40),
                   _buildSecurityNote(),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAlertBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.expiring.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.expiring.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.expiring, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MANUAL PASSWORD MANAGEMENT',
                  style: AppTextStyles.label.copyWith(fontSize: 12, color: AppColors.expiring, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  'IronBook does NOT store your backup passwords. If you lose your password, the data cannot be recovered even by our support team.',
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 11, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isWarning = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.elevation1,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: (isWarning ? AppColors.expired : AppColors.primary).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: isWarning ? AppColors.expired : AppColors.primary, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.cardTitle),
                  const SizedBox(height: 4),
                  Text(subtitle, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection() {
    final settings = ref.watch(settingsProvider);
    final syncStatus = ref.watch(syncStatusProvider);
    
    final lastBackup = settings.lastBackupAt != null 
        ? DateFormat('MMM dd, yyyy • hh:mm a').format(settings.lastBackupAt!)
        : 'Never';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.elevation2,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildStatusRow(
            Icons.history_rounded,
            'Last Backup',
            lastBackup,
            settings.lastBackupAt == null ? AppColors.expired : AppColors.primary,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: AppColors.border),
          ),
          _buildStatusRow(
            Icons.sync_rounded,
            'Unsynced Changes',
            '${syncStatus.unsyncedCount} items pending',
            syncStatus.unsyncedCount > 0 ? AppColors.expiring : AppColors.textMuted,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textMuted, size: 20),
        const SizedBox(width: 12),
        Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
        const Spacer(),
        Text(value, style: AppTextStyles.label.copyWith(color: color, fontSize: 13)),
      ],
    );
  }

  Widget _buildSecurityNote() {
    return Column(
      children: [
        Icon(Icons.shield_rounded, color: AppColors.textMuted.withOpacity(0.5), size: 48),
        const SizedBox(height: 16),
        Text(
          'AES-256-GCM Encryption',
          style: AppTextStyles.label.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: 8),
        Text(
          'Your data is encrypted locally before leaving the device. Only someone with your password can read the contents.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 10),
        ),
      ],
    );
  }
}
