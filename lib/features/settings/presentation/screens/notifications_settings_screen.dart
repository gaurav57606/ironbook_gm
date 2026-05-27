import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/providers/settings_provider.dart';
import 'package:go_router/go_router.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_toggle_tile.dart';
import '../widgets/membership_expiry_slider.dart';
import 'package:ironbook_gm/core/utils/subscription_duration_helper.dart';

class NotificationsSettingsScreen extends ConsumerWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
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
              const SizedBox(height: 32),
              SettingsSection(
                title: 'CALCULATION SETTINGS',
                titleLeftPadding: 4,
                children: [
                  Consumer(
                    builder: (context, ref, _) {
                      final settingsAsync = ref.watch(appSettingsProvider);
                      return settingsAsync.when(
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (settings) {
                          final current = SubscriptionMode.fromString(settings.subscriptionMode);
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            title: Text(
                              'Subscription Duration Mode',
                              style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              'How membership end dates are calculated',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                            trailing: SegmentedButton<SubscriptionMode>(
                              style: SegmentedButton.styleFrom(
                                selectedBackgroundColor: AppColors.primary,
                                selectedForegroundColor: Colors.white,
                                backgroundColor: AppColors.elevation2,
                                side: const BorderSide(color: AppColors.border),
                              ),
                              segments: const [
                                ButtonSegment(value: SubscriptionMode.fixed28, label: Text('28d')),
                                ButtonSegment(value: SubscriptionMode.fixed30, label: Text('30d')),
                                ButtonSegment(value: SubscriptionMode.calendarMonth, label: Text('Month')),
                              ],
                              selected: {current},
                              onSelectionChanged: (val) async {
                                final notifier = ref.read(appSettingsProvider.notifier);
                                await notifier.updateSubscriptionMode(val.first.toDbString());
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
