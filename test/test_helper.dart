import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ironbook_gm/data/local/adapters/manual_adapters.dart';
import 'package:ironbook_gm/data/local/models/domain_event_model.dart';
import 'package:ironbook_gm/data/local/models/member_snapshot_model.dart';
import 'package:ironbook_gm/data/local/models/payment_model.dart';
import 'package:ironbook_gm/data/local/models/plan_model.dart';
import 'package:ironbook_gm/data/local/models/owner_profile_model.dart';
import 'package:ironbook_gm/data/local/models/app_settings_model.dart';
import 'package:ironbook_gm/data/local/models/invoice_sequence.dart';
import 'package:ironbook_gm/data/local/models/product_model.dart';
import 'package:ironbook_gm/data/local/models/sale_model.dart';

class TestHelper {
  static bool _initialized = false;

  static Future<void> setupHive([String subDir = 'default']) async {
    // Initialize Hive with a specific directory for isolation
    final tempPath = 'test_hive/$subDir';
    Hive.init(tempPath);
    
    // Register all adapters
    _registerAdapters();
    
    // Open required boxes
    await _openBoxes();
    
    _initialized = true;
  }

  static void _registerAdapters() {
    if (!Hive.isAdapterRegistered(10)) Hive.registerAdapter(DomainEventAdapter());
    if (!Hive.isAdapterRegistered(11)) Hive.registerAdapter(MemberSnapshotAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(PaymentAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(PlanAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(PlanComponentAdapter());
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(OwnerProfileAdapter());
    if (!Hive.isAdapterRegistered(6)) Hive.registerAdapter(AppSettingsAdapter());
    if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(JoinDateChangeAdapter());
    if (!Hive.isAdapterRegistered(13)) Hive.registerAdapter(PlanComponentSnapshotAdapter());
    if (!Hive.isAdapterRegistered(12)) Hive.registerAdapter(InvoiceSequenceAdapter());
    if (!Hive.isAdapterRegistered(14)) Hive.registerAdapter(ProductAdapter());
    if (!Hive.isAdapterRegistered(15)) Hive.registerAdapter(SaleAdapter());
    if (!Hive.isAdapterRegistered(16)) Hive.registerAdapter(SaleItemAdapter());
  }

  static Future<void> _openBoxes() async {
    await Hive.openBox<DomainEvent>('events');
    await Hive.openBox<MemberSnapshot>('snapshots');
    await Hive.openBox<Payment>('payments');
    await Hive.openBox<Plan>('plans');
    await Hive.openBox<OwnerProfile>('owner');
    await Hive.openBox<AppSettings>('settings');
    await Hive.openBox<InvoiceSequence>('invoice_sequences');
    await Hive.openBox<Product>('products');
    await Hive.openBox<Sale>('sales');
  }

  static Future<void> cleanHive() async {
    await Hive.deleteFromDisk();
    _initialized = false;
  }
}
