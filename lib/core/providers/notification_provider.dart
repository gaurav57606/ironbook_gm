import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'base_providers.dart';
import '../data/local/drift/outbox_database.dart';

final notificationProvider = StreamProvider<List<Notification>>((ref) {
  final repo = ref.watch(outboxRepositoryProvider);
  return repo.watchNotifications();
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationProvider).value ?? [];
  return notifications.where((n) => !n.isRead).length;
});
