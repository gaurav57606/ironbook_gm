import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/providers/notification_provider.dart';
import '../../../../core/data/local/drift/outbox_database.dart' as db;
import '../../../../shared/widgets/app_empty_state.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class NotificationsHubScreen extends ConsumerStatefulWidget {
  const NotificationsHubScreen({super.key});

  @override
  ConsumerState<NotificationsHubScreen> createState() => _NotificationsHubScreenState();
}

class _NotificationsHubScreenState extends ConsumerState<NotificationsHubScreen> {
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationProvider);

    return Scaffold(
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
              _buildHeader(context),
              _buildCategoryFilter(),
              const SizedBox(height: 16),
              notificationsAsync.when(
                data: (notifications) {
                  final filtered = _filterNotifications(notifications);
                  if (filtered.isEmpty) {
                    return Expanded(
                      child: Center(
                        child: AppEmptyState(
                          title: _selectedCategory == 'All' 
                              ? 'All caught up' 
                              : 'No $_selectedCategory alerts',
                          subtitle: 'New notifications will appear here.',
                          icon: Icons.notifications_none_rounded,
                        ),
                      ),
                    );
                  }
                  return _buildNotificationsList(filtered);
                },
                loading: () => const Expanded(
                  child: Center(child: CircularProgressIndicator(color: AppColors.orange)),
                ),
                error: (e, st) => Expanded(
                  child: Center(child: Text('Error loading notifications', style: TextStyle(color: AppColors.red))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<db.Notification> _filterNotifications(List<db.Notification> notifications) {
    if (_selectedCategory == 'All') return notifications;
    
    // Map UI labels to database categories
    final Map<String, String> mapping = {
      'Payments': 'Payment',
      'System': 'System',
      'Reminders': 'Reminder',
    };
    
    final target = mapping[_selectedCategory];
    return notifications.where((n) => n.category == target).toList();
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.s,
        right: AppSpacing.screenPadding,
        top: AppSpacing.xl,
        bottom: AppSpacing.m,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.text, size: 20),
          ),
          const Expanded(
            child: Text(
              'Notifications',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              await NotificationService.markAllAsRead();
              ref.invalidate(notificationProvider);
            },
            child: const Text(
              'Mark all as read',
              style: TextStyle(color: AppColors.orange, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final categories = ['All', 'Payments', 'System', 'Reminders'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: categories.map((cat) => _buildCategoryChip(cat, _selectedCategory == cat)).toList(),
        ),
      ),
    );
  }

  Widget _buildNotificationsList(List<db.Notification> notifications) {
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final n = notifications[index];
          return _buildNotificationItem(n, ref);
        },
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool active) {
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = label),
      child: Container(
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
      ),
    );
  }

  Widget _buildNotificationItem(db.Notification n, WidgetRef ref) {
    final Color color = _getCategoryColor(n.category);
    final IconData icon = _getCategoryIcon(n.category);
    final String timeStr = _formatTimestamp(n.timestamp);

    return InkWell(
      onTap: () async {
        await NotificationService.markAsRead(n.id);
        ref.invalidate(notificationProvider);
        if (n.payload != null && mounted) {
           // We can't easily call handlePayload with context here because it's static and complex.
           // But we can just use the router directly.
           if (n.payload!.startsWith('member:')) {
             final id = n.payload!.split(':')[1];
             context.push('/members/member-details/$id');
           }
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bg2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: !n.isRead ? color.withValues(alpha: 0.3) : AppColors.border),
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
                      Text(n.title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold)),
                      Text(timeStr,
                          style: const TextStyle(
                              color: AppColors.text3, fontSize: 10)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    n.body,
                    style: const TextStyle(color: AppColors.text3, fontSize: 11),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!n.isRead)
              Container(
                margin: const EdgeInsets.only(left: 8, top: 4),
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Payment':
        return Colors.green;
      case 'Reminder':
        return Colors.amber;
      case 'System':
        return Colors.blue;
      default:
        return AppColors.orange;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Payment':
        return Icons.check_circle_rounded;
      case 'Reminder':
        return Icons.warning_amber_rounded;
      case 'System':
        return Icons.system_update_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    
    return DateFormat('MMM d').format(dt);
  }
}
