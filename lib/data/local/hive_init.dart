import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../../core/services/hive_encryption_service.dart';
import 'models/domain_event_model.dart';
import 'models/member_snapshot_model.dart';
import 'models/payment_model.dart';
import 'models/plan_model.dart';
import 'models/owner_profile_model.dart';
import 'models/app_settings_model.dart';
import 'models/invoice_sequence.dart';
import 'models/product_model.dart';
import 'models/sale_model.dart';

class HiveInit {
  static Future<void> openAllBoxes() async {
    final cipher = kIsWeb ? null : await HiveEncryptionService.getOrCreateCipher();

    // Open each box with its specific type to avoid HiveError in typed repositories
    if (!Hive.isBoxOpen('events')) await Hive.openBox<DomainEvent>('events', encryptionCipher: cipher);
    if (!Hive.isBoxOpen('snapshots')) await Hive.openBox<MemberSnapshot>('snapshots', encryptionCipher: cipher);
    if (!Hive.isBoxOpen('payments')) await Hive.openBox<Payment>('payments', encryptionCipher: cipher);
    if (!Hive.isBoxOpen('plans')) await Hive.openBox<Plan>('plans', encryptionCipher: cipher);
    if (!Hive.isBoxOpen('owner')) await Hive.openBox<OwnerProfile>('owner', encryptionCipher: cipher);
    if (!Hive.isBoxOpen('settings')) await Hive.openBox<AppSettings>('settings', encryptionCipher: cipher);
    if (!Hive.isBoxOpen('invoice_sequences')) await Hive.openBox<InvoiceSequence>('invoice_sequences', encryptionCipher: cipher);
    if (!Hive.isBoxOpen('products')) await Hive.openBox<Product>('products', encryptionCipher: cipher);
    if (!Hive.isBoxOpen('sales')) await Hive.openBox<Sale>('sales', encryptionCipher: cipher);
  }

  static Future<bool> openWithCorruptionGuard() async {
    try {
      await openAllBoxes();
      return true;
    } catch (e) {
      debugPrint('Hive first attempt failed: $e. Nuking boxes...');
      final boxNames = [
        'events', 'snapshots', 'payments', 'plans', 
        'owner', 'settings', 'invoice_sequences', 'auth',
        'products', 'sales'
      ];
      for (final name in boxNames) {
        try {
          if (Hive.isBoxOpen(name)) {
             await Hive.box(name).close();
          }
          await Hive.deleteBoxFromDisk(name);
        } catch (_) {}
      }
      
      try {
        debugPrint('Hive retrying after nuke...');
        await openAllBoxes();
        return true;
      } catch (e2) {
        debugPrint('Hive critical failure after nuke: $e2');
        return false;
      }
    }
  }
}
