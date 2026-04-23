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
import 'package:ironbook_gm/core/providers/base_providers.dart';
import 'package:ironbook_gm/core/providers/member_provider.dart';
import 'package:ironbook_gm/core/providers/payment_provider.dart';
import 'package:ironbook_gm/core/data/repositories/event_repository.dart';
import 'package:ironbook_gm/core/providers/auth_provider.dart';
import 'package:ironbook_gm/core/data/sync_worker.dart';
import 'package:ironbook_gm/core/providers/owner_provider.dart';
import 'package:ironbook_gm/core/providers/plan_provider.dart';
import 'package:ironbook_gm/core/providers/sale_provider.dart';
import 'package:ironbook_gm/core/providers/settings_provider.dart';

// Models
import 'package:ironbook_gm/core/data/local/models/domain_event_model.dart';
import 'package:ironbook_gm/core/data/local/models/member_snapshot_model.dart';
import 'package:ironbook_gm/core/data/local/models/payment_model.dart';
import 'package:ironbook_gm/core/data/local/models/plan_model.dart';
import 'package:ironbook_gm/core/data/local/models/owner_profile_model.dart';
import 'package:ironbook_gm/core/data/local/models/app_settings_model.dart';
import 'package:ironbook_gm/core/data/local/models/invoice_sequence.dart';
import 'package:ironbook_gm/core/data/local/models/product_model.dart';
import 'package:ironbook_gm/core/data/local/models/sale_model.dart';

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

    await Share.shareXFiles(
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

    // 1. Shadow Import: Parse first to ensure 100% success
    final data = backupData['data'] as Map<String, dynamic>;
    final parsed = _parseBackupData(data);

    // 2. ONLY IF SUCCESSFUL, proceed to wipe
    await _hardWipe();

    // 3. Insert pre-parsed data
    await _applyParsedData(parsed);

    // 4. Comprehensive invalidation to prevent "Ghost State"
    _ref.invalidate(membersProvider);
    _ref.invalidate(eventRepositoryProvider);
    _ref.invalidate(authProvider);
    _ref.invalidate(paymentsProvider);
    _ref.invalidate(unsyncedCountProvider);
    _ref.invalidate(ownerProvider);
    _ref.invalidate(planProvider);
    _ref.invalidate(productsProvider);
    _ref.invalidate(saleProvider);
    _ref.invalidate(settingsProvider);
    // Note: Add any other core providers here if needed
  }

  _ParsedBackupData _parseBackupData(Map<String, dynamic> data) {
    final parsed = _ParsedBackupData();

    if (data.containsKey('settings')) {
      final list = data['settings'] as List;
      if (list.isNotEmpty) {
        parsed.settings = AppSettings.fromFirestore(list.first as Map<String, dynamic>);
      }
    }

    if (data.containsKey('owner')) {
      final list = data['owner'] as List;
      if (list.isNotEmpty) {
        parsed.owner = OwnerProfile.fromFirestore(list.first as Map<String, dynamic>);
      }
    }

    if (data.containsKey('plans')) {
      for (final item in data['plans'] as List) {
        parsed.plans.add(Plan.fromFirestore(item as Map<String, dynamic>));
      }
    }

    if (data.containsKey('events')) {
      for (final item in data['events'] as List) {
        parsed.events.add(DomainEvent.fromFirestore(item as Map<String, dynamic>));
      }
    }

    if (data.containsKey('snapshots')) {
      for (final item in data['snapshots'] as List) {
        parsed.snapshots.add(MemberSnapshot.fromPayload(item['memberId'], item as Map<String, dynamic>));
      }
    }

    if (data.containsKey('payments')) {
      for (final item in data['payments'] as List) {
        parsed.payments.add(Payment.fromFirestore(item as Map<String, dynamic>));
      }
    }

    if (data.containsKey('invoice_sequences')) {
      for (final item in data['invoice_sequences'] as List) {
        parsed.sequences.add(InvoiceSequence.fromFirestore(item as Map<String, dynamic>));
      }
    }

    if (data.containsKey('products')) {
      for (final item in data['products'] as List) {
        parsed.products.add(Product.fromFirestore(item as Map<String, dynamic>));
      }
    }

    if (data.containsKey('sales')) {
      for (final item in data['sales'] as List) {
        parsed.sales.add(Sale.fromFirestore(item as Map<String, dynamic>));
      }
    }

    return parsed;
  }

  Future<void> _applyParsedData(_ParsedBackupData parsed) async {
    if (parsed.settings != null) {
      await Hive.box<AppSettings>('settings').put('settings', parsed.settings!);
    }

    if (parsed.owner != null) {
      await Hive.box<OwnerProfile>('owner').put('owner', parsed.owner!);
    }

    final plansBox = Hive.box<Plan>('plans');
    for (final plan in parsed.plans) {
      await plansBox.put(plan.id, plan);
    }

    if (parsed.events.isNotEmpty) {
      final eventsBox = await Hive.openLazyBox<DomainEvent>('events');
      for (final event in parsed.events) {
        await eventsBox.put(event.id, event);
      }
      
      final outboxRepo = _ref.read(outboxRepositoryProvider);
      await outboxRepo.seedFromHive(parsed.events);
    }

    if (parsed.snapshots.isNotEmpty) {
      final snapshotBox = await Hive.openLazyBox<MemberSnapshot>('snapshots');
      for (final snap in parsed.snapshots) {
        await snapshotBox.put(snap.memberId, snap);
      }
    }

    final paymentsBox = Hive.box<Payment>('payments');
    for (final payment in parsed.payments) {
      await paymentsBox.put(payment.id, payment);
    }

    final sequenceBox = Hive.box<InvoiceSequence>('invoice_sequences');
    for (final seq in parsed.sequences) {
      await sequenceBox.add(seq);
    }

    final productBox = Hive.box<Product>('products');
    for (final prod in parsed.products) {
      await productBox.put(prod.id, prod);
    }

    final saleBox = Hive.box<Sale>('sales');
    for (final sale in parsed.sales) {
      await saleBox.put(sale.id, sale);
    }
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
}

class _ParsedBackupData {
  AppSettings? settings;
  OwnerProfile? owner;
  final List<Plan> plans = [];
  final List<DomainEvent> events = [];
  final List<MemberSnapshot> snapshots = [];
  final List<Payment> payments = [];
  final List<InvoiceSequence> sequences = [];
  final List<Product> products = [];
  final List<Sale> sales = [];
}











