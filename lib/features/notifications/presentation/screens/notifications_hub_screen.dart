import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../../../../../shared/widgets/status_bar_wrapper.dart';

class NotificationsHubScreen extends StatelessWidget {
  const NotificationsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StatusBarWrapper(
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
              colors: [
                Colors.purple.withValues(alpha: 0.05),
                AppColors.bg,
                AppColors.bg,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildCategoryFilter(),
                const SizedBox(height: 16),
                _buildNotificationsList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Notifications',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextButton(
            onPressed: () {},
            child: const Text(
              'Mark all as read',
              style: TextStyle(color: AppColors.orange, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildCategoryChip('All', true),
            _buildCategoryChip('Payments', false),
            _buildCategoryChip('System', false),
            _buildCategoryChip('Reminders', false),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsList() {
    return Expanded(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          _buildNotificationItem(
            'Payment Successful',
            'Premium membership for John Doe renewed.',
            '2m ago',
            Icons.check_circle_rounded,
            Colors.green,
            true,
          ),
          _buildNotificationItem(
            'New Member Alert',
            'Sarah Jenkins joined with Elite Coaching plan.',
            '1h ago',
            Icons.person_add_rounded,
            AppColors.orange,
            true,
          ),
          _buildNotificationItem(
            'System Update',
            'Analytics engine updated for better insights.',
            '5h ago',
            Icons.system_update_rounded,
            Colors.blue,
            false,
          ),
          _buildNotificationItem(
            'Plan Expiry',
            'Mike Ross plan expires in 3 days.',
            '1d ago',
            Icons.warning_amber_rounded,
            Colors.amber,
            false,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool active) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: active ? AppColors.orange : AppColors.bg2,
        borderRadius: BorderRadius.circular(15),
        border:
            Border.all(color: active ? Colors.transparent : AppColors.border),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? Colors.white : AppColors.text3,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildNotificationItem(String title, String desc, String time,
      IconData icon, Color color, bool unread) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: unread ? color.withValues(alpha: 0.3) : AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold)),
                    Text(time,
                        style: const TextStyle(
                            color: AppColors.text3, fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(color: AppColors.text3, fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (unread)
            Container(
              margin: const EdgeInsets.only(left: 8, top: 4),
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
        ],
      ),
    );
  }
}









