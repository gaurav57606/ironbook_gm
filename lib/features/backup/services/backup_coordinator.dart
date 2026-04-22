import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import 'backup_encryption_service.dart';
import '../../../data/local/drift/outbox_repository.dart';
import '../../../providers/base_providers.dart';
import '../../../providers/member_provider.dart';
import '../../../providers/payment_provider.dart';
import '../../../data/repositories/event_repository.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/sync_worker.dart';

// Models
import '../../../data/local/models/domain_event_model.dart';
import '../../../data/local/models/member_snapshot_model.dart';
import '../../../data/local/models/payment_model.dart';
import '../../../data/local/models/plan_model.dart';
import '../../../data/local/models/owner_profile_model.dart';
import '../../../data/local/models/app_settings_model.dart';
import '../../../data/local/models/invoice_sequence.dart';
import '../../../data/local/models/product_model.dart';
import '../../../data/local/models/sale_model.dart';

final backupCoordinatorProvider = Provider((ref) => BackupCoordinator(ref));

class BackupCoordinator {
  final Ref _ref;
  final BackupEncryptionService _encryptionService = BackupEncryptionService();

  BackupCoordinator(this._ref);

  Future<void> exportBackup(String password) async {
    final Map<String, dynamic> backupData = {
      'version': '1.1',
      'timestamp': DateTime.now().toIso8601String(),
      'data': await _gatherAllData(),
    };

    final jsonPayload = jsonEncode(backupData);
    final encryptedBytes = await _encryptionService.encrypt(password, jsonPayload);

    final tempDir = await getTemporaryDirectory();
    final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());
    final fileName = 'ironbook_backup_$dateStr.igmb';
    final file = File('${tempDir.path}/$fileName');
    
    await file.writeAsBytes(encryptedBytes);

    final success = await Share.shareXFiles(
      [XFile(file.path)], 
      subject: 'IronBook GM Encrypted Backup',
      text: 'IronBook GM backup file generated on ${DateFormat('MMM dd, yyyy').format(DateTime.now())}.',
    );

    // If share was attempted (share_plus doesn't always return true on all platforms, 
    // but we can assume success if no exception was thrown)
    final settingsBox = Hive.box<AppSettings>('settings');
    final settings = settingsBox.get('settings') ?? AppSettings();
    await settingsBox.put('settings', settings.copyWith(lastBackupAt: DateTime.now()));
  }

  Future<void> importBackup(String password) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['igmb'],
    );

    if (result == null || result.files.single.path == null) return;

    final file = File(result.files.single.path!);
    final bytes = await file.readAsBytes();

    final decryptedJson = await _encryptionService.decrypt(password, bytes);
    final backupData = jsonDecode(decryptedJson) as Map<String, dynamic>;

    final version = backupData['version'] as String?;
    if (version != '1.1') {
      throw Exception('Incompatible backup version: $version. Expected 1.1');
    }

    // CRITICAL: Hard wipe
    await _hardWipe();

    // Seed
    await _seedData(backupData['data'] as Map<String, dynamic>);

    // Global refresh
    _ref.invalidate(membersProvider);
    _ref.invalidate(eventRepositoryProvider);
    _ref.invalidate(authProvider);
    _ref.invalidate(paymentsProvider);
    _ref.invalidate(unsyncedCountProvider);
  }

  Future<Map<String, dynamic>> _gatherAllData() async {
    final Map<String, dynamic> data = {};
    
    final boxNames = [
      'events', 'snapshots', 'payments', 'plans', 
      'owner', 'settings', 'invoice_sequences', 'products', 'sales'
    ];

    for (final name in boxNames) {
      try {
        if (Hive.isBoxOpen(name)) {
          final box = Hive.box(name);
          data[name] = box.values.map((e) => _modelToJson(e)).toList();
        } else {
          final box = Hive.isBoxOpen(name) 
              ? Hive.lazyBox(name) 
              : await Hive.openLazyBox(name);
          
          final List<dynamic> items = [];
          for(final key in box.keys) {
            final val = await box.get(key);
            items.add(_modelToJson(val));
          }
          data[name] = items;
        }
      } catch (e) {
        debugPrint('BackupCoordinator: Failed to read box $name: $e');
      }
    }

    return data;
  }

  dynamic _modelToJson(dynamic model) {
    if (model == null) return null;
    if (model is DomainEvent) {
      final map = model.toFirestore();
      map['synced'] = model.synced; // Preserve actual local sync status
      return map;
    }
    if (model is MemberSnapshot) return model.toFirestore();
    if (model is Payment) return model.toFirestore();
    if (model is Plan) return model.toFirestore();
    if (model is OwnerProfile) return model.toFirestore();
    if (model is AppSettings) return model.toFirestore();
    if (model is InvoiceSequence) return model.toFirestore();
    if (model is Product) return model.toFirestore();
    if (model is Sale) return model.toFirestore();
    return model;
  }

  Future<void> _hardWipe() async {
    final boxNames = [
      'events', 'snapshots', 'payments', 'plans', 
      'owner', 'settings', 'invoice_sequences', 'products', 'sales'
    ];
    for (final name in boxNames) {
      if (Hive.isBoxOpen(name)) {
        await Hive.box(name).clear();
      } else if (Hive.isBoxOpen(name)) {
        await Hive.lazyBox(name).clear();
      } else {
        await Hive.deleteBoxFromDisk(name);
      }
    }

    final outboxRepo = _ref.read(outboxRepositoryProvider);
    await outboxRepo.clearAll();
  }

  Future<void> _seedData(Map<String, dynamic> data) async {
    if (data.containsKey('settings')) {
      final box = Hive.box<AppSettings>('settings');
      final list = data['settings'] as List;
      if (list.isNotEmpty) {
        await box.put('settings', AppSettings.fromFirestore(list.first as Map<String, dynamic>));
      }
    }

    if (data.containsKey('owner')) {
      final box = Hive.box<OwnerProfile>('owner');
      final list = data['owner'] as List;
      if (list.isNotEmpty) {
        await box.put('owner', OwnerProfile.fromFirestore(list.first as Map<String, dynamic>));
      }
    }

    if (data.containsKey('plans')) {
      final box = Hive.box<Plan>('plans');
      final list = data['plans'] as List;
      for (final item in list) {
        final plan = Plan.fromFirestore(item as Map<String, dynamic>);
        await box.put(plan.id, plan);
      }
    }

    if (data.containsKey('events')) {
      final box = await Hive.openLazyBox<DomainEvent>('events');
      final list = data['events'] as List;
      final List<DomainEvent> eventList = [];
      for (final item in list) {
        final event = DomainEvent.fromFirestore(item as Map<String, dynamic>);
        await box.put(event.id, event);
        eventList.add(event);
      }
      
      final outboxRepo = _ref.read(outboxRepositoryProvider);
      await outboxRepo.seedFromHive(eventList);
    }

    if (data.containsKey('snapshots')) {
      final box = await Hive.openLazyBox<MemberSnapshot>('snapshots');
      final list = data['snapshots'] as List;
      for (final item in list) {
        final snap = MemberSnapshot.fromPayload(item['memberId'], item as Map<String, dynamic>);
        await box.put(snap.memberId, snap);
      }
    }

    if (data.containsKey('payments')) {
      final box = Hive.box<Payment>('payments');
      final list = data['payments'] as List;
      for (final item in list) {
        final payment = Payment.fromFirestore(item as Map<String, dynamic>);
        await box.put(payment.id, payment);
      }
    }

    if (data.containsKey('invoice_sequences')) {
      final box = Hive.box<InvoiceSequence>('invoice_sequences');
      final list = data['invoice_sequences'] as List;
      for (final item in list) {
        final seq = InvoiceSequence.fromFirestore(item as Map<String, dynamic>);
        await box.add(seq);
      }
    }

    if (data.containsKey('products')) {
      final box = Hive.box<Product>('products');
      final list = data['products'] as List;
      for (final item in list) {
        final prod = Product.fromFirestore(item as Map<String, dynamic>);
        await box.put(prod.id, prod);
      }
    }

    if (data.containsKey('sales')) {
      final box = Hive.box<Sale>('sales');
      final list = data['sales'] as List;
      for (final item in list) {
        final sale = Sale.fromFirestore(item as Map<String, dynamic>);
        await box.put(sale.id, sale);
      }
    }
  }
}
