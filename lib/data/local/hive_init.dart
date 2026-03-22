import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/services/hive_encryption_service.dart';
import 'models/domain_event_model.dart';
import 'models/member_snapshot_model.dart';
import 'models/payment_model.dart';
import 'models/plan_model.dart';
import 'models/plan_component_model.dart';
import 'models/owner_profile_model.dart';
import 'models/app_settings_model.dart';
import 'models/join_date_change_model.dart';

class HiveInit {
  static Future<void> openAllBoxes() async {
    final cipher = await HiveEncryptionService.getOrCreateCipher();

    // Open every box with the cipher — no exceptions
    await Hive.openBox<DomainEvent>('events', encryptionCipher: cipher);
    await Hive.openBox<MemberSnapshot>('snapshots', encryptionCipher: cipher);
    await Hive.openBox<Payment>('payments', encryptionCipher: cipher);
    await Hive.openBox<Plan>('plans', encryptionCipher: cipher);
    await Hive.openBox<OwnerProfile>('owner', encryptionCipher: cipher);
    await Hive.openBox<AppSettings>('settings', encryptionCipher: cipher);
    await Hive.openBox<int>('invoice_sequences', encryptionCipher: cipher);
  }

  static Future<bool> openWithCorruptionGuard() async {
    try {
      await openAllBoxes();
      return true;
    } on HiveError catch (e) {
      debugPrint('Hive corruption detected: $e');
      final boxNames = [
        'events',
        'snapshots',
        'payments',
        'plans',
        'owner',
        'settings',
        'invoice_sequences'
      ];
      for (final name in boxNames) {
        try {
          await Hive.deleteBoxFromDisk(name);
        } catch (_) {}
      }
      return false; 
    }
  }
}
