import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../../shared/widgets/status_bar_wrapper.dart';
import '../../../../core/providers/settings_provider.dart';
import 'package:go_router/go_router.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_toggle_tile.dart';
import '../widgets/membership_expiry_slider.dart';

class NotificationsSettingsScreen extends ConsumerWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return StatusBarWrapper(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded,
                color: AppColors.textPrimary, size: 24),
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
            padding: EdgeInsets.fromLTRB(
                24, MediaQuery.of(context).padding.top + 70, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SettingsSection(
                  title: 'CLIENT REMINDERS',
                  titleLeftPadding: 4,
                  children: [
                    SettingsToggleTile(
                      icon: Icons.chat_rounded,
                      title: 'WhatsApp Reminders',
                      subtitle: 'Auto-send payment reminders via WhatsApp',
                      value: settings.whatsappReminders,
                      onChanged: (val) async {
                        await ref.read(settingsProvider.notifier).updateSettings(
                              settings.copyWith(whatsappReminders: val),
                            );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                SettingsSection(
                  title: 'SYSTEM ALERTS',
                  titleLeftPadding: 4,
                  children: [
                    MembershipExpirySlider(
                      expiryReminderDays: settings.expiryReminderDays,
                      onChanged: (val) async {
                        await ref.read(settingsProvider.notifier).updateSettings(
                              settings
                                  .copyWith(expiryReminderDays: val.toInt()),
                            );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
