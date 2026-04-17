import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/status_bar_wrapper.dart';
import '../../../../providers/auth_provider.dart';
import 'package:go_router/go_router.dart';

class NotificationsSettingsScreen extends ConsumerWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    return StatusBarWrapper(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 24),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Notifications',
            style: AppTextStyles.h3,
          ),
          centerTitle: true,
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: AppColors.backgroundGradient,
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 70, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildClientReminders(ref, auth),
                const SizedBox(height: 32),
                _buildSystemAlerts(context, ref, auth),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClientReminders(WidgetRef ref, AuthState auth) {
    return _buildSection(
      title: 'CLIENT REMINDERS',
      children: [
        _buildToggleTile(
          icon: Icons.chat_rounded,
          title: 'WhatsApp Reminders',
          subtitle: 'Auto-send payment reminders via WhatsApp',
          value: auth.settings.whatsappReminders,
          onChanged: (val) async {
            await ref.read(authProvider.notifier).updateSettings(
                  auth.settings.copyWith(whatsappReminders: val),
                );
          },
        ),
      ],
    );
  }

  Widget _buildSystemAlerts(BuildContext context, WidgetRef ref, AuthState auth) {
    return _buildSection(
      title: 'SYSTEM ALERTS',
      children: [
        _buildExpiryNotice(context, ref, auth),
      ],
    );
  }

  Widget _buildExpiryNotice(BuildContext context, WidgetRef ref, AuthState auth) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Membership Expiry Notice',
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${auth.settings.expiryReminderDays} DAYS',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Notify gym owner and members before their plan expires.',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.border,
              thumbColor: AppColors.textPrimary,
              overlayColor: AppColors.primary.withValues(alpha: 0.1),
              valueIndicatorColor: AppColors.primary,
              valueIndicatorTextStyle: const TextStyle(color: Colors.white),
            ),
            child: Slider(
              value: auth.settings.expiryReminderDays.toDouble(),
              min: 1,
              max: 15,
              divisions: 14,
              label: auth.settings.expiryReminderDays.toString(),
              onChanged: (val) async {
                await ref.read(authProvider.notifier).updateSettings(
                      auth.settings.copyWith(expiryReminderDays: val.toInt()),
                    );
              },
            ),
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1 DAY', style: TextStyle(fontSize: 9)),
              Text('15 DAYS', style: TextStyle(fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: AppTextStyles.sectionTitle.copyWith(
              fontSize: 10,
              letterSpacing: 1.5,
              color: AppColors.textMuted,
            ),
          ),
        ),
        Container(
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
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.elevation2,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.2),
            inactiveThumbColor: AppColors.textMuted,
            inactiveTrackColor: AppColors.border,
          ),
        ],
      ),
    );
  }
}
