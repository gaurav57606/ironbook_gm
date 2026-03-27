import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/colors.dart';
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
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.text, size: 20),
            onPressed: () => context.pop(),
          ),
          title: const Text(
            'Notifications',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                title: 'CLIENT REMINDERS',
                children: [
                  _buildToggleTile(
                    icon: Icons.message_outlined,
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
              ),
              const SizedBox(height: 24),
              _buildSection(
                title: 'SYSTEM ALERTS',
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Membership Expiry Notice',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Text('Notify', style: TextStyle(fontSize: 11, color: AppColors.text2)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.bg4,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${auth.settings.expiryReminderDays}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.orange),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('days before expiry', style: TextStyle(fontSize: 11, color: AppColors.text2)),
                          ],
                        ),
                        Slider(
                          value: auth.settings.expiryReminderDays.toDouble(),
                          min: 1,
                          max: 15,
                          divisions: 14,
                          activeColor: AppColors.orange,
                          inactiveColor: AppColors.bg4,
                          onChanged: (val) async {
                            await ref.read(authProvider.notifier).updateSettings(
                              auth.settings.copyWith(expiryReminderDays: val.toInt()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.text3),
        ),
        const SizedBox(height: 12),
        Container(
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

  Widget _buildToggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.bg4,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: AppColors.text2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text)),
                Text(subtitle, style: const TextStyle(fontSize: 9, color: AppColors.text3)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.orange,
            activeTrackColor: AppColors.orange.withValues(alpha: 0.2),
          ),
        ],
      ),
    );
  }
}
