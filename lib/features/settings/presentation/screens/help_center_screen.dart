import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../../shared/widgets/status_bar_wrapper.dart';
import 'package:go_router/go_router.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
            'Help Center',
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
          child: ListView(
            padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 70, 24, 24),
            children: [
              _buildHelpTile(Icons.menu_book_rounded, 'User Guide', 'Comprehensive instructions for gym owners'),
              _buildHelpTile(Icons.video_library_rounded, 'Video Tutorials', 'Step-by-step visual training guides'),
              _buildHelpTile(Icons.quiz_rounded, 'Frequently Asked Questions', 'Quick answers to common queries'),
              _buildHelpTile(Icons.support_agent_rounded, 'Priority Support', 'Reach out for dedicated assistance'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHelpTile(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.cardTitle.copyWith(fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}









