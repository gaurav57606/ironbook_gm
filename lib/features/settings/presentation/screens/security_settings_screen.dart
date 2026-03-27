import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/status_bar_wrapper.dart';
import '../../../../providers/auth_provider.dart';
import 'package:go_router/go_router.dart';

class SecuritySettingsScreen extends ConsumerWidget {
  const SecuritySettingsScreen({super.key});

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
            'Security & PIN',
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
              _buildSecuritySection(
                title: 'APP LOCK',
                children: [
                   _buildToggleTile(
                    icon: Icons.lock_outline,
                    title: 'PIN Security',
                    subtitle: auth.isPinSetup ? 'Configured' : 'Not setup',
                    value: auth.isPinSetup,
                    onChanged: (val) {
                      if (!auth.isPinSetup) {
                        context.push('/setup-pin');
                      } else {
                        // Logic to disable PIN might go here
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('PIN can be changed from the setup flow')),
                        );
                      }
                    },
                  ),
                  _buildToggleTile(
                    icon: Icons.fingerprint,
                    title: 'Biometric Unlock',
                    subtitle: 'Use fingerprint or face ID',
                    value: auth.settings.useBiometrics,
                    onChanged: (val) async {
                      await ref.read(authProvider.notifier).setBiometricOptIn(val);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 30),
              AppButton(
                text: auth.isPinSetup ? 'Change Security PIN' : 'Setup Security PIN',
                style: AppButtonStyle.outline,
                onPressed: () => context.push('/setup-pin'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecuritySection({required String title, required List<Widget> children}) {
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
