import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:ironbook_gm/core/data/local/models/product_model.dart';
import 'package:ironbook_gm/core/data/local/models/sale_model.dart';
import 'package:ironbook_gm/core/data/local/models/domain_event_model.dart';
import 'package:ironbook_gm/core/data/local/models/invoice_sequence.dart';
import 'package:ironbook_gm/core/data/repositories/event_repository.dart';
import 'package:ironbook_gm/core/data/repositories/sale_repository.dart';
import 'package:ironbook_gm/shared/utils/clock.dart';
import 'package:ironbook_gm/core/services/hmac_service.dart';
import 'package:ironbook_gm/core/providers/base_providers.dart';
import 'payment_provider.dart';

import 'package:ironbook_gm/core/data/repositories/product_repository.dart';
import 'package:ironbook_gm/core/data/repositories/sequence_repository.dart';

class SaleNotifier extends StateNotifier<List<Sale>> {
  final IProductRepository _productRepo;
  final ISequenceRepository _sequenceRepo;
  final IEventRepository _eventRepo;
  final ISaleRepository _saleRepo;
  final IClock _clock;
  final HmacService _hmac;
  String _deviceId = 'device-loading';
  
  SaleNotifier(
    this._productRepo,
    this._sequenceRepo,
    this._eventRepo,
    this._saleRepo,
    this._clock,
    this._hmac,
  ) : super([]) {
    _init();
    _seedProductsIfEmpty();
  }

  Future<void> _init() async {
    _deviceId = await _hmac.getInstallationId();

    // 1. Listen for events
    _eventRepo.watch().listen((event) async {
      if (event.eventType == EventType.paymentRecorded && event.payload.containsKey('saleId')) {
        await _saleRepo.applyEvent(event);
        final saleId = event.payload['saleId'] as String?;
        if (saleId != null) {
          final sale = await _saleRepo.getSale(saleId);
          if (sale != null) {
            state = [sale, ...state];
          }
        }
      }
    });

    // 2. Load all sales from Drift
    state = (await _saleRepo.getAllSales()).reversed.toList();

    // 3. Reconcile
    await reconcileSales();
  }

  Future<void> reconcileSales() async {
    final recentEvents = await _eventRepo.getAll();
    final saleEvents = recentEvents
        .where((e) => e.eventType == EventType.paymentRecorded && e.payload.containsKey('saleId'))
        .toList();
    
    if (saleEvents.isEmpty) return;

    final existingIds = await _saleRepo.getAllSaleIds();
    final List<Sale> newSales = [];

    for (final event in saleEvents) {
      final saleId = event.payload['saleId'] as String?;
      if (saleId == null || existingIds.contains(saleId)) continue;

      final sale = Sale.fromPayload(saleId, event.payload, event.deviceTimestamp);

      // Sign the sale
      final signature = await _hmac.signSnapshot(sale.id, sale.toFirestore());
      sale.hmacSignature = signature;

      newSales.add(sale);
    }

    if (newSales.isNotEmpty) {
      await _saleRepo.upsertSales(newSales);
      state = (await _saleRepo.getAllSales()).reversed.toList();
    }
  }

  @visibleForTesting
  set debugState(List<Sale> sales) => state = sales;

  void _seedProductsIfEmpty() async {
    final existing = await _productRepo.getAllProducts();
    if (existing.isEmpty) {
      final initialProducts = [
        Product(id: 'p1', name: 'Whey Protein', price: 120, category: 'Supplements', iconCodePoint: 0xe293),
        Product(id: 'p2', name: 'BCAA Powder', price: 80, category: 'Supplements', iconCodePoint: 0xe2e3),
        Product(id: 'p3', name: 'Pre-Workout', price: 95, category: 'Supplements', iconCodePoint: 0xe113),
        Product(id: 'p4', name: 'Creatine', price: 70, category: 'Supplements', iconCodePoint: 0xe54d),
        Product(id: 'p5', name: 'IronBook Tee', price: 45, category: 'Merch', iconCodePoint: 0xe170),
        Product(id: 'p6', name: 'Steel Shaker', price: 25, category: 'Merch', iconCodePoint: 0xe3ab),
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
      eventType: EventType.paymentRecorded,
      deviceId: _deviceId,
      deviceTimestamp: now,
      payload: {
        'saleId': saleId,
        'memberId': memberId,
        'total': total,
        'method': method,
        'items': items.map((i) => {
          'productId': i.productId,
          'productName': i.productName,
          'qty': i.quantity,
          'price': i.price,
        }).toList(),
        'invoiceNumber': invoiceNumber,
      },
    );
    
    await _eventRepo.persist(event);

    // Persist Locally in Drift
    await _saleRepo.upsertSale(sale);
    
    final saved = await _saleRepo.getSale(sale.id);
    if (saved != null) {
      state = [saved, ...state];
    }
  }
}

final productsProvider = FutureProvider<List<Product>>((ref) async {
  final repo = ref.watch(productRepositoryProvider);
  return repo.getAllProducts();
});

final saleProvider = StateNotifierProvider<SaleNotifier, List<Sale>>((ref) {
  final productRepo = ref.watch(productRepositoryProvider);
  final sequenceRepo = ref.watch(sequenceRepositoryProvider);
  final eventRepo = ref.watch(eventRepositoryProvider);
  final saleRepo = ref.watch(saleRepositoryProvider);
  final clock = ref.watch(clockProvider);
  final hmac = ref.watch(hmacServiceProvider);
  
  return SaleNotifier(productRepo, sequenceRepo, eventRepo, saleRepo, clock, hmac);
});
