import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../../shared/widgets/app_button.dart';
import '../../../../../shared/widgets/status_bar_wrapper.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/settings_provider.dart';
import 'package:go_router/go_router.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_toggle_tile.dart';

class SecuritySettingsScreen extends ConsumerWidget {
  const SecuritySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
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
            'Security & PIN',
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
                  title: 'APP LOCK',
                  children: [
                    SettingsToggleTile(
                      icon: Icons.lock_outline_rounded,
                      title: 'PIN Security',
                      subtitle: auth.isPinSetup ? 'Configured' : 'Not setup',
                      value: auth.isPinSetup,
                      onChanged: (val) {
                        if (!auth.isPinSetup) {
                          context.push('/setup-pin');
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'PIN can be changed from the setup flow')),
                          );
                        }
                      },
                    ),
                    SettingsToggleTile(
                      icon: Icons.fingerprint_rounded,
                      title: 'Biometric Unlock',
                      subtitle: 'Use fingerprint or face ID',
                      value: settings.useBiometrics,
                      onChanged: (val) async {
                        await ref
                            .read(settingsProvider.notifier)
                            .updateSettings(settings.copyWith(useBiometrics: val));
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                AppButton(
                  text: auth.isPinSetup
                      ? 'Change Security PIN'
                      : 'Setup Security PIN',
                  style: AppButtonStyle.outline,
                  onPressed: () => context.push('/setup-pin'),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Ensure your app is protected by a secure PIN or biometric authentication to prevent unauthorized access to your gym data.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textMuted,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
