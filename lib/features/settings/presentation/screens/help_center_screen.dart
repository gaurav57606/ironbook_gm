import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/widgets/status_bar_wrapper.dart';
import 'package:go_router/go_router.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
            'Help Center',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildHelpTile(Icons.book_outlined, 'User Guide', 'Learn how to use IronBook GM'),
            _buildHelpTile(Icons.video_collection_outlined, 'Video Tutorials', 'Watch step-by-step guides'),
            _buildHelpTile(Icons.question_answer_outlined, 'FAQs', 'Frequently asked questions'),
            _buildHelpTile(Icons.contact_support_outlined, 'Contact Support', 'Get help from our team'),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpTile(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bg3,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.orange, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.text3)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 16, color: AppColors.text3),
        ],
      ),
    );
  }
}
