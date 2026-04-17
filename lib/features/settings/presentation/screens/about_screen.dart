import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/status_bar_wrapper.dart';
import 'package:go_router/go_router.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StatusBarWrapper(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: _buildAppBar(context),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: AppColors.backgroundGradient,
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                _buildLogo(),
                const SizedBox(height: 32),
                Text(
                  'IronBook GM',
                  style: AppTextStyles.h1.copyWith(fontSize: 28),
                ),
                const SizedBox(height: 8),
                _buildVersionInfo(),
                const SizedBox(height: 48),
                _buildDescription(),
                const Spacer(flex: 3),
                _buildFooter(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded,
            color: AppColors.textPrimary, size: 24),
        onPressed: () => context.pop(),
      ),
      title: Text(
        'About IronBook GM',
        style: AppTextStyles.h3,
      ),
      centerTitle: true,
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          )
        ],
      ),
      child: const Icon(Icons.fitness_center_rounded,
          size: 60, color: Colors.white),
    );
  }

  Widget _buildVersionInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'VERSION 2.4.0',
        style: AppTextStyles.label.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildDescription() {
    return Column(
      children: [
        Text(
          'The ultimate gym management suite.',
          style: AppTextStyles.h3.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'Professionally designed for gym owners who value stability, security, and world-class performance.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textMuted,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Text(
          'MADE WITH ❤️ BY ANTIGRAVITY',
          style: AppTextStyles.sectionTitle.copyWith(
            fontSize: 10,
            letterSpacing: 2,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '© 2026 IronBook GM. All rights reserved.',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textMuted,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
