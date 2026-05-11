import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:drift/drift.dart' as drift;

import 'backup_encryption_service.dart';
import 'package:ironbook_gm/core/providers/base_providers.dart';
import 'package:ironbook_gm/core/providers/member_provider.dart';
import 'package:ironbook_gm/core/providers/payment_provider.dart';
import 'package:ironbook_gm/core/data/repositories/event_repository.dart';
import 'package:ironbook_gm/core/providers/auth_provider.dart';
import 'package:ironbook_gm/core/providers/owner_provider.dart';
import 'package:ironbook_gm/core/providers/plan_provider.dart';
import 'package:ironbook_gm/core/providers/sale_provider.dart';
import 'package:ironbook_gm/core/providers/settings_provider.dart';
import 'package:ironbook_gm/core/data/local/drift/outbox_database.dart' as db;

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
      'version': '1.2', 
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

    final settingsRepo = _ref.read(settingsRepositoryProvider);
    final settings = await settingsRepo.getSettings();
    await settingsRepo.updateSettings(settings.copyWith(lastBackupAt: DateTime.now()));
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
    if (version != '1.1' && version != '1.2') {
      throw Exception('Incompatible backup version: $version. Expected 1.1 or 1.2');
    }

    final data = backupData['data'] as Map<String, dynamic>;
    final parsed = _parseBackupData(data);

    await _hardWipe();
    await _applyParsedData(parsed);

    _ref.invalidate(membersProvider);
    _ref.invalidate(eventRepositoryProvider);
    _ref.invalidate(authProvider);
    _ref.invalidate(paymentsProvider);
    _ref.invalidate(ownerProvider);
    _ref.invalidate(planProvider);
    _ref.invalidate(productsProvider);
    _ref.invalidate(saleProvider);
    _ref.invalidate(settingsProvider);
  }

  _ParsedBackupData _parseBackupData(Map<String, dynamic> data) {
    final parsed = _ParsedBackupData();

    if (data.containsKey('settings')) {
      final list = data['settings'] as List;
      if (list.isNotEmpty && list.first != null) {
        parsed.settings = AppSettings.fromFirestore(Map<String, dynamic>.from(list.first));
      }
    }

    if (data.containsKey('owner')) {
      final list = data['owner'] as List;
      if (list.isNotEmpty && list.first != null) {
        parsed.owner = OwnerProfile.fromFirestore(Map<String, dynamic>.from(list.first));
      }
    }

    if (data.containsKey('plans')) {
      for (final item in data['plans'] as List) {
        parsed.plans.add(Plan.fromFirestore(Map<String, dynamic>.from(item)));
      }
    }

    if (data.containsKey('events')) {
      for (final item in data['events'] as List) {
        parsed.events.add(DomainEvent.fromFirestore(Map<String, dynamic>.from(item)));
      }
    }

    if (data.containsKey('snapshots') || data.containsKey('members')) {
      final list = (data['snapshots'] ?? data['members']) as List;
      for (final item in list) {
        final map = Map<String, dynamic>.from(item);
        parsed.snapshots.add(MemberSnapshot.fromPayload(map['memberId'], map));
      }
    }

    if (data.containsKey('payments')) {
      for (final item in data['payments'] as List) {
        parsed.payments.add(Payment.fromFirestore(Map<String, dynamic>.from(item)));
      }
    }

    if (data.containsKey('invoice_sequences')) {
      for (final item in data['invoice_sequences'] as List) {
        parsed.sequences.add(InvoiceSequence.fromFirestore(Map<String, dynamic>.from(item)));
      }
    }

    if (data.containsKey('products')) {
      for (final item in data['products'] as List) {
        parsed.products.add(Product.fromFirestore(Map<String, dynamic>.from(item)));
      }
    }

    if (data.containsKey('sales')) {
      for (final item in data['sales'] as List) {
        parsed.sales.add(Sale.fromFirestore(Map<String, dynamic>.from(item)));
      }
    }

    if (data.containsKey('sales')) {
      for (final item in data['sales'] as List) {
        parsed.sales.add(Sale.fromFirestore(Map<String, dynamic>.from(item)));
      }
    }

    return parsed;
  }

  Future<void> _applyParsedData(_ParsedBackupData parsed) async {
    final database = _ref.read(outboxDatabaseProvider);

    await database.transaction(() async {
      if (parsed.settings != null) {
        final s = parsed.settings!;
        await database.into(database.appSettingsTable).insert(db.AppSettingsTableCompanion.insert(
          gstRate: drift.Value(s.gstRate),
          expiryReminderDays: drift.Value(s.expiryReminderDays),
          whatsappReminders: drift.Value(s.whatsappReminders),
          biometricEnabled: drift.Value(s.biometricEnabled),
          useBiometrics: drift.Value(s.useBiometrics),
          businessType: drift.Value(s.businessType),
          lastBackupAt: drift.Value(s.lastBackupAt),
          hmacSignature: drift.Value(s.hmacSignature),
        ));
      }

      if (parsed.owner != null) {
        final o = parsed.owner!;
        await database.into(database.ownerProfiles).insert(db.OwnerProfilesCompanion.insert(
          gymName: o.gymName,
          ownerName: o.ownerName,
          phone: o.phone,
          address: o.address,
          gstin: drift.Value(o.gstin),
          bankName: drift.Value(o.bankName),
          accountNumber: drift.Value(o.accountNumber),
          ifsc: drift.Value(o.ifsc),
          upiId: drift.Value(o.upiId),
          logoPath: drift.Value(o.logoPath),
          level: drift.Value(o.level),
          exp: drift.Value(o.exp),
          strength: drift.Value(o.strength),
          endurance: drift.Value(o.endurance),
          dexterity: drift.Value(o.dexterity),
          selectedCharacterId: drift.Value(o.selectedCharacterId),
          hmacSignature: drift.Value(o.hmacSignature),
        ));
      }

      for (final p in parsed.plans) {
        await database.into(database.plans).insert(db.PlansCompanion.insert(
          id: p.id,
          name: p.name,
          durationMonths: p.durationMonths,
          price: p.totalPrice,
          active: drift.Value(p.active),
          componentsJson: drift.Value(jsonEncode(p.components.map((c) => {'id': c.id, 'name': c.name, 'price': c.price}).toList())),
          hmacSignature: drift.Value(p.hmacSignature ?? ''),
        ));
      }

      for (final e in parsed.events) {
        await database.into(database.outboxEvents).insert(db.OutboxEventsCompanion.insert(
          id: e.id,
          entityId: e.entityId,
          eventType: e.eventType.name,
          payloadJson: jsonEncode(e.payload),
          deviceTimestamp: e.deviceTimestamp.millisecondsSinceEpoch,
          isSynced: drift.Value(e.synced ? 1 : 0),
          hmacSignature: drift.Value(e.hmacSignature),
          deviceId: drift.Value(e.deviceId),
        ));
      }

      for (final s in parsed.snapshots) {
        await database.into(database.members).insert(db.MembersCompanion.insert(
          id: s.memberId,
          name: s.name,
          phone: drift.Value(s.phone),
          joinDate: s.joinDate,
          planId: drift.Value(s.planId),
          planName: drift.Value(s.planName),
          expiryDate: drift.Value(s.expiryDate),
          totalPaid: drift.Value(s.totalPaid),
          archived: drift.Value(s.archived),
          gender: drift.Value(s.gender),
          age: drift.Value(s.age),
          checkInPin: drift.Value(s.checkInPin),
          lastCheckIn: drift.Value(s.lastCheckIn),
          hmacSignature: drift.Value(s.hmacSignature ?? ''),
        ));
      }

      for (final p in parsed.payments) {
        await database.into(database.payments).insert(db.PaymentsCompanion.insert(
          id: p.id,
          memberId: p.memberId,
          date: p.date,
          amount: p.amount,
          method: p.method,
          reference: drift.Value(p.reference),
          planId: drift.Value(p.planId),
          planName: drift.Value(p.planName),
          durationMonths: drift.Value(p.durationMonths),
          invoiceNumber: p.invoiceNumber,
          subtotal: p.subtotal,
          gstAmount: p.gstAmount,
          gstRate: drift.Value(p.gstRate),
          componentsJson: drift.Value(jsonEncode(p.components.map((c) => {'name': c.name, 'price': c.price}).toList())),
          hmacSignature: drift.Value(p.hmacSignature ?? ''),
        ));
      }

      for (final s in parsed.sequences) {
        await database.into(database.invoiceSequences).insert(db.InvoiceSequencesCompanion.insert(
          prefix: s.prefix,
          nextNumber: drift.Value(s.nextNumber),
        ));
      }

      for (final prod in parsed.products) {
        await database.into(database.products).insert(db.ProductsCompanion.insert(
          id: prod.id,
          name: prod.name,
          price: prod.price,
          category: prod.category,
          iconCodePoint: prod.iconCodePoint,
        ));
      }

      for (final sale in parsed.sales) {
        await database.into(database.sales).insert(db.SalesCompanion.insert(
          id: sale.id,
          memberId: drift.Value(sale.memberId),
          date: sale.date,
          totalAmount: sale.totalAmount,
          paymentMethod: sale.paymentMethod,
          invoiceNumber: sale.invoiceNumber,
          itemsJson: jsonEncode(sale.items.map((i) => {'productId': i.productId, 'productName': i.productName, 'price': i.price, 'quantity': i.quantity}).toList()),
          hmacSignature: drift.Value(sale.hmacSignature ?? ''),
        ));
      }

      for (final sale in parsed.sales) {
        await database.into(database.sales).insert(db.SalesCompanion.insert(
          id: sale.id,
          memberId: drift.Value(sale.memberId),
          date: sale.date,
          totalAmount: sale.totalAmount,
          paymentMethod: sale.paymentMethod,
          invoiceNumber: sale.invoiceNumber,
          itemsJson: jsonEncode(sale.items.map((i) => {'productId': i.productId, 'productName': i.productName, 'price': i.price, 'quantity': i.quantity}).toList()),
          hmacSignature: drift.Value(sale.hmacSignature ?? ''),
        ));
      }
    });
  }

  Future<Map<String, dynamic>> _gatherAllData() async {
    final database = _ref.read(outboxDatabaseProvider);
    final Map<String, dynamic> data = {};
    
    data['members'] = (await database.select(database.members).get()).map((r) => MemberSnapshot.fromDrift(r).toFirestore()).toList();
    data['payments'] = (await database.select(database.payments).get()).map((r) => Payment.fromDrift(r).toFirestore()).toList();
    data['plans'] = (await database.select(database.plans).get()).map((r) => Plan.fromDrift(r).toFirestore()).toList();
    data['owner'] = (await database.select(database.ownerProfiles).get()).map((r) => OwnerProfile.fromDrift(r).toFirestore()).toList();
    data['settings'] = (await database.select(database.appSettingsTable).get()).map((r) => AppSettings.fromDrift(r).toFirestore()).toList();
    data['invoice_sequences'] = (await database.select(database.invoiceSequences).get()).map((r) => InvoiceSequence.fromDrift(r).toFirestore()).toList();
    data['products'] = (await database.select(database.products).get()).map((r) => Product.fromDrift(r).toFirestore()).toList();
    data['sales'] = (await database.select(database.sales).get()).map((r) => Sale.fromDrift(r).toFirestore()).toList();
    data['events'] = (await database.select(database.outboxEvents).get()).map((r) => DomainEvent.fromOutbox(r).toFirestore()).toList();
    
    return data;
  }

  Future<void> _hardWipe() async {
    final database = _ref.read(outboxDatabaseProvider);
    await database.transaction(() async {
      await database.delete(database.outboxEvents).go();
      await database.delete(database.members).go();
      await database.delete(database.payments).go();
      await database.delete(database.plans).go();
      await database.delete(database.sales).go();
      await database.delete(database.invoiceSequences).go();
      await database.delete(database.products).go();
      await database.delete(database.ownerProfiles).go();
      await database.delete(database.appSettingsTable).go();
    });
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
