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
    final boxNames = {
      'events': DomainEvent,
      'snapshots': MemberSnapshot,
      'payments': Payment,
      'plans': Plan,
      'owner': OwnerProfile,
      'settings': AppSettings,
      'invoice_sequences': InvoiceSequence,
      'products': Product,
      'sales': Sale,
    };

    for (final entry in boxNames.entries) {
      final name = entry.key;
      if (Hive.isBoxOpen(name)) continue;
      
      try {
        await _openBoxTyped(name, entry.value, cipher);
      } catch (e) {
        debugPrint('Hive: Failed to open box "$name" ($e). Attempting granular recovery...');
        try {
          await Hive.deleteBoxFromDisk(name);
          await _openBoxTyped(name, entry.value, cipher);
          debugPrint('Hive: Box "$name" recovered via nuke-and-reopen.');
        } catch (e2) {
          debugPrint('Hive: Critical failure opening box "$name" after deletion: $e2');
          if (name == 'events') rethrow; // Events are non-negotiable (Source of Truth)
        }
      }
    }
  }

  static Future<void> _openBoxTyped(String name, Type type, HiveCipher? cipher) async {
    if (type == DomainEvent) await Hive.openLazyBox<DomainEvent>(name, encryptionCipher: cipher);
    else if (type == MemberSnapshot) await Hive.openLazyBox<MemberSnapshot>(name, encryptionCipher: cipher);
    else if (type == Payment) await Hive.openBox<Payment>(name, encryptionCipher: cipher);
    else if (type == Plan) await Hive.openBox<Plan>(name, encryptionCipher: cipher);
    else if (type == OwnerProfile) await Hive.openBox<OwnerProfile>(name, encryptionCipher: cipher);
    else if (type == AppSettings) await Hive.openBox<AppSettings>(name, encryptionCipher: cipher);
    else if (type == InvoiceSequence) await Hive.openBox<InvoiceSequence>(name, encryptionCipher: cipher);
    else if (type == Product) await Hive.openBox<Product>(name, encryptionCipher: cipher);
    else if (type == Sale) await Hive.openBox<Sale>(name, encryptionCipher: cipher);
    else await Hive.openBox(name, encryptionCipher: cipher);
  }

  static Future<bool> openWithCorruptionGuard() async {
    try {
      await openAllBoxes();
      return true;
    } catch (e) {
      debugPrint('Hive: Hard crash on Source of Truth (events): $e');
      return false;
    }
  }
