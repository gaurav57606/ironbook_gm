import 'dart:io';
import 'package:hive/hive.dart';
import 'package:ironbook_gm/data/local/adapters/manual_adapters.dart';

class HiveTestHelper {
  static late Directory _tempDir;

  static Future<void> setup() async {
    _tempDir = await Directory.systemTemp.createTemp('ironbook_test_');
    Hive.init(_tempDir.path);
    
    // Use manual adapters instead of generated ones
    Hive.registerAdapter(PaymentAdapter(), override: true);
    Hive.registerAdapter(DomainEventAdapter(), override: true);
    Hive.registerAdapter(MemberSnapshotAdapter(), override: true);
    Hive.registerAdapter(OwnerProfileAdapter(), override: true);
    Hive.registerAdapter(AppSettingsAdapter(), override: true);
    Hive.registerAdapter(JoinDateChangeAdapter(), override: true);
    Hive.registerAdapter(PlanAdapter(), override: true);
    Hive.registerAdapter(PlanComponentAdapter(), override: true);
    Hive.registerAdapter(PlanComponentSnapshotAdapter(), override: true);
    Hive.registerAdapter(InvoiceSequenceAdapter(), override: true);
  }

  static Future<void> tearDown() async {
    await Hive.close();
    if (_tempDir.existsSync()) {
      await _tempDir.delete(recursive: true);
    }
  }

  static Future<Box<T>> openBox<T>(String name) async {
    return await Hive.openBox<T>(name);
  }
}
