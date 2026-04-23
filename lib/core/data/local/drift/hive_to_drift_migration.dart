import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'outbox_repository.dart';
import '../models/domain_event_model.dart';

class HiveToDriftMigration {
  static const _migrationKey = 'outbox_migration_v1_done';

  static Future<void> runIfNeeded(OutboxRepository repo) async {
    const storage = FlutterSecureStorage();
    final done = await storage.read(key: _migrationKey);
    
    if (done == 'true') {
      debugPrint('HiveToDriftMigration: Already completed. Skipping.');
      return;
    }

    debugPrint('HiveToDriftMigration: Starting migration from Hive to Drift...');
    
    try {
      if (!Hive.isBoxOpen('events')) {
        debugPrint('HiveToDriftMigration: Events box not open. Aborting.');
        return;
      }

      final box = Hive.lazyBox<DomainEvent>('events');
      final List<DomainEvent> unsyncedEvents = [];
      
      for (final key in box.keys) {
        final event = await box.get(key);
        if (event != null && !event.synced) {
          unsyncedEvents.add(event);
        }
      }

      if (unsyncedEvents.isNotEmpty) {
        debugPrint('HiveToDriftMigration: Found ${unsyncedEvents.length} unsynced events in Hive.');
        await repo.seedFromHive(unsyncedEvents);
        debugPrint('HiveToDriftMigration: Seeding complete.');
      } else {
        debugPrint('HiveToDriftMigration: No unsynced events found.');
      }

      await storage.write(key: _migrationKey, value: 'true');
      debugPrint('HiveToDriftMigration: Flag set to true.');
      
    } catch (e) {
      debugPrint('HiveToDriftMigration Error: $e');
      // We don't rethrow here to avoid blocking app start if migration fails, 
      // but in a production app you'd want careful retry logic.
    }
  }
}











