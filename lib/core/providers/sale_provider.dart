import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:ironbook_gm/core/data/local/models/product_model.dart';
import 'package:ironbook_gm/core/data/local/models/sale_model.dart';
import 'package:ironbook_gm/core/data/local/models/domain_event_model.dart';
import 'package:ironbook_gm/core/data/repositories/event_repository.dart';
import 'package:ironbook_gm/core/data/repositories/sale_repository.dart';
import 'package:ironbook_gm/shared/utils/clock.dart';
import 'package:ironbook_gm/core/services/hmac_service.dart';
import 'package:ironbook_gm/core/providers/base_providers.dart';
import 'package:ironbook_gm/core/services/sync_coordinator.dart';

import 'package:ironbook_gm/core/data/repositories/product_repository.dart';
import 'package:ironbook_gm/core/data/repositories/sequence_repository.dart';
import 'package:ironbook_gm/core/data/local/drift/outbox_database.dart' as db;

class SaleNotifier extends StateNotifier<List<Sale>> {
  final db.OutboxDatabase _db;
  final IProductRepository _productRepo;
  final ISequenceRepository _sequenceRepo;
  final IEventRepository _eventRepo;
  final ISaleRepository _saleRepo;
  final IClock _clock;
  final HmacService _hmac;
  final SyncCoordinator _coordinator;
  String _deviceId = 'device-loading';
  StreamSubscription? _eventSubscription;

  SaleNotifier(
    db.OutboxDatabase db,
    this._productRepo,
    this._sequenceRepo,
    this._eventRepo,
    this._saleRepo,
    this._clock,
    this._hmac,
    this._coordinator,
  ) : _db = db,
      super([]) {
    _init();
    _seedProductsIfEmpty();
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    _deviceId = await _hmac.getInstallationId();

    // 1. Listen for events (Single Source of Truth)
    _eventSubscription = _eventRepo.watch().listen((event) async {
      if (event.eventType == EventType.saleRecorded &&
          event.payload.containsKey('saleId')) {
        debugPrint(
          '[STATE] SaleNotifier: Processing sale event for ${event.entityId}',
        );
        await _saleRepo.applyEvent(event);
        final saleId = event.payload['saleId'] as String?;
        if (saleId != null) {
          final sale = await _saleRepo.getSale(saleId);
          if (sale != null && mounted) {
            final exists = state.any((s) => s.id == sale.id);
            if (!exists) {
              state = [sale, ...state];
            }
          }
        }
      }
    });

    // 2. Load all sales from Drift
    state = (await _saleRepo.getAllSales()).reversed.toList();

    // 3. Reconcile
    await _reconcileSales();
  }

  Future<void> rebuildCache() async {
    debugPrint('[STATE] SaleNotifier: Full rebuild triggered');
    await _reconcileSales();
  }

  Future<void> _reconcileSales() async {
    final recentEvents = await _eventRepo.getAllEvents();
    final saleEvents = recentEvents
        .where(
          (e) =>
              e.eventType == EventType.saleRecorded &&
              e.payload.containsKey('saleId'),
        )
        .toList();

    if (saleEvents.isEmpty) return;

    final existingIds = state.map((s) => s.id).toSet();
    final missingEvents = saleEvents.where((e) {
      final saleId = e.payload['saleId'] as String?;
      return saleId != null && !existingIds.contains(saleId);
    }).toList();

    if (missingEvents.isEmpty) return;

    final newSales = missingEvents.map((event) {
      final saleId = event.payload['saleId'] as String;
      return Sale.fromPayload(saleId, event.payload, event.deviceTimestamp);
    }).toList();

    await _saleRepo.upsertSales(newSales);

    state = (await _saleRepo.getAllSales()).reversed.toList();
  }

  @visibleForTesting
  set debugState(List<Sale> sales) => state = sales;

  void _seedProductsIfEmpty() async {
    final existing = await _productRepo.getAllProducts();
    if (existing.isEmpty) {
      final initialProducts = [
        Product(
          id: 'p1',
          name: 'Whey Protein',
          price: 120,
          category: 'Supplements',
          iconCodePoint: 0xe293,
        ),
        Product(
          id: 'p2',
          name: 'BCAA Powder',
          price: 80,
          category: 'Supplements',
          iconCodePoint: 0xe2e3,
        ),
        Product(
          id: 'p3',
          name: 'Pre-Workout',
          price: 95,
          category: 'Supplements',
          iconCodePoint: 0xe113,
        ),
        Product(
          id: 'p4',
          name: 'Creatine',
          price: 70,
          category: 'Supplements',
          iconCodePoint: 0xe54d,
        ),
        Product(
          id: 'p5',
          name: 'IronBook Tee',
          price: 45,
          category: 'Merch',
          iconCodePoint: 0xe170,
        ),
        Product(
          id: 'p6',
          name: 'Steel Shaker',
          price: 25,
          category: 'Merch',
          iconCodePoint: 0xe3ab,
        ),
      ];
      for (var p in initialProducts) {
        await _productRepo.upsertProduct(p);
      }
    }
  }

  Future<void> recordSale({
    required List<SaleItem> items,
    required String method,
    required double total,
    String memberId = 'walk-in',
  }) async {
    final saleId = const Uuid().v4();
    final now = _clock.now;

    // Generate Invoice Number for Sale via Drift
    final prefix = 'SAL-${now.year}-';
    final invoiceNumber = await _sequenceRepo.getNextInvoiceNumber(prefix);

    final sale = Sale(
      id: saleId,
      memberId: memberId,
      date: now,
      totalAmount: total,
      paymentMethod: method,
      items: items,
      invoiceNumber: invoiceNumber,
    );

    // Emit Domain Event FIRST
    final event = DomainEvent(
      entityId: saleId,
      eventType: EventType.saleRecorded,
      deviceId: _deviceId,
      deviceTimestamp: now,
      payload: {
        'saleId': saleId,
        'memberId': memberId,
        'total': total,
        'method': method,
        'items': items
            .map(
              (i) => {
                'productId': i.productId,
                'productName': i.productName,
                'qty': i.quantity,
                'price': i.price,
              },
            )
            .toList(),
        'invoiceNumber': invoiceNumber,
      },
    );

    await _db.transaction(() async {
      debugPrint('[TRANSACTION] SaleNotifier: Starting recordSale for $saleId');
      await _eventRepo.persist(event);

      // Persist Locally in Drift
      await _saleRepo.upsertSale(sale);
      debugPrint('[TRANSACTION] SaleNotifier: recordSale transaction complete');
    });

    _coordinator.triggerSync();
  }
}

final productsProvider = StreamProvider<List<Product>>((ref) {
  final repo = ref.watch(productRepositoryProvider);
  return repo.watchAllProducts();
});

final saleProvider = StateNotifierProvider<SaleNotifier, List<Sale>>((ref) {
  final productRepo = ref.watch(productRepositoryProvider);
  final sequenceRepo = ref.watch(sequenceRepositoryProvider);
  final eventRepo = ref.watch(eventRepositoryProvider);
  final saleRepo = ref.watch(saleRepositoryProvider);
  final clock = ref.watch(clockProvider);
  final db = ref.watch(outboxDatabaseProvider);
  final hmac = ref.watch(hmacServiceProvider);
  final coordinator = ref.watch(syncCoordinatorProvider);

  return SaleNotifier(
    db,
    productRepo,
    sequenceRepo,
    eventRepo,
    saleRepo,
    clock,
    hmac,
    coordinator,
  );
});
