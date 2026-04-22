import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../data/local/models/product_model.dart';
import '../data/local/models/sale_model.dart';
import '../data/local/models/domain_event_model.dart';
import '../data/local/models/invoice_sequence.dart';
import '../data/repositories/event_repository.dart';
import '../core/utils/clock.dart';
import '../core/services/hmac_service.dart';
import '../providers/base_providers.dart';
import 'payment_provider.dart';

class SaleNotifier extends StateNotifier<List<Sale>> {
  final Box<Sale> _saleBox;
  final Box<Product> _productBox;
  final IEventRepository _eventRepo;
  final IClock _clock;
  final HmacService _hmac;
  String _deviceId = 'device-loading';
  final Ref _ref;
 
  SaleNotifier(
    this._saleBox,
    this._productBox,
    this._eventRepo,
    this._clock,
    this._hmac,
    this._ref,
  ) : super([]) {
    _init();
    _seedProductsIfEmpty();
  }

  Future<void> _init() async {
    _deviceId = await _hmac.getInstallationId();
    await _loadSales();
    await _reconcileSales();
  }

  Future<void> _reconcileSales() async {
    final allEvents = await _eventRepo.getAll();
    final saleEvents = allEvents.where((e) => e.eventType == EventType.paymentRecorded && e.payload.containsKey('saleId')).toList();
    
    bool updatedAny = false;
    for (final event in saleEvents) {
      final saleId = event.payload['saleId'] as String?;
      if (saleId == null) continue;

      if (!_saleBox.containsKey(saleId)) {
        // Build Sale from payload
        final items = (event.payload['items'] as List? ?? []).map((i) {
          final iMap = Map<String, dynamic>.from(i);
          return SaleItem(
            productId: iMap['productId'] ?? '',
            productName: 'Unknown Product', // Product names aren't in payload currently
            price: (iMap['price'] as num?)?.toDouble() ?? 0.0,
            quantity: iMap['qty'] ?? 1,
          );
        }).toList();

        final sale = Sale(
          id: saleId,
          date: event.deviceTimestamp,
          totalAmount: (event.payload['total'] as num?)?.toDouble() ?? 0.0,
          paymentMethod: event.payload['method'] ?? 'Cash',
          items: items,
          invoiceNumber: event.payload['invoiceNumber'] ?? 'SAL-0000',
        );
        
        // Sign and save
        final signature = await _hmac.signSnapshot(sale.id, sale.toFirestore());
        sale.hmacSignature = signature;
        await _saleBox.put(saleId, sale);
        updatedAny = true;
      }
    }

    if (updatedAny) {
      await _loadSales();
    }
  }

  Future<void> _loadSales() async {
    final sales = _saleBox.values.toList();
    final verified = <Sale>[];
    
    for (final s in sales) {
      final isValid = await _hmac.verifySnapshot(s.id, s.toFirestore(), s.hmacSignature ?? '');
      if (!isValid) {
        debugPrint('SaleNotifier: Signature mismatch for sale ${s.id}. Integrity compromised.');
        // Sales are usually high-volume and non-repairable if event loop isn't fully implemented for retail.
        // For now, we flag it in debug.
        continue;
      }
      verified.add(s);
    }
    
    state = verified.reversed.toList();
  }

  void _seedProductsIfEmpty() async {
    if (_productBox.isEmpty) {
      final initialProducts = [
        Product(id: 'p1', name: 'Whey Protein', price: 120, category: 'Supplements', iconCodePoint: 0xe293),
        Product(id: 'p2', name: 'BCAA Powder', price: 80, category: 'Supplements', iconCodePoint: 0xe2e3),
        Product(id: 'p3', name: 'Pre-Workout', price: 95, category: 'Supplements', iconCodePoint: 0xe113),
        Product(id: 'p4', name: 'Creatine', price: 70, category: 'Supplements', iconCodePoint: 0xe54d),
        Product(id: 'p5', name: 'IronBook Tee', price: 45, category: 'Merch', iconCodePoint: 0xe170),
        Product(id: 'p6', name: 'Steel Shaker', price: 25, category: 'Merch', iconCodePoint: 0xe3ab),
      ];
      for (var p in initialProducts) {
        await _productBox.put(p.id, p);
      }
    }
  }

  Future<void> recordSale({
    required List<SaleItem> items,
    required String method,
    required double total,
  }) async {
    final saleId = const Uuid().v4();
    final now = _clock.now;
    
    // Generate Invoice Number for Sale
    final sequenceBox = _ref.read(sequenceBoxProvider);
    var sequence = sequenceBox.get('sales_seq');
    if (sequence == null) {
      sequence = InvoiceSequence(prefix: 'SAL-${now.year}-');
      await sequenceBox.put('sales_seq', sequence);
    }
    final invoiceNumber = sequence.nextInvoiceId;
    sequence.nextNumber++;
    await sequence.save();

    final sale = Sale(
      id: saleId,
      date: now,
      totalAmount: total,
      paymentMethod: method,
      items: items,
      invoiceNumber: invoiceNumber,
    );

    // Emit Domain Event FIRST (Enforce Outbox-First Rule)
    final event = DomainEvent(
      entityId: saleId,
      eventType: EventType.paymentRecorded,
      deviceId: _deviceId,
      deviceTimestamp: now,
      payload: {
        'saleId': saleId,
        'total': total,
        'method': method,
        'items': items.map((i) => {
          'productId': i.productId,
          'qty': i.quantity,
          'price': i.price,
        }).toList(),
        'invoiceNumber': invoiceNumber,
      },
    );
    
    // Anchor point: This must succeed before local Hive is touched
    await _eventRepo.persist(event);

    // Persist Cache Locally
    final signature = await _hmac.signSnapshot(sale.id, sale.toFirestore());
    final signed = sale..hmacSignature = signature;
    
    await _saleBox.put(signed.id, signed);
    state = [signed, ...state];
  }
}

final productBoxProvider = Provider<Box<Product>>((ref) => Hive.box<Product>('products'));
final saleBoxProvider = Provider<Box<Sale>>((ref) => Hive.box<Sale>('sales'));

final productsProvider = Provider<List<Product>>((ref) {
  return ref.watch(productBoxProvider).values.toList();
});

final saleProvider = StateNotifierProvider<SaleNotifier, List<Sale>>((ref) {
  final saleBox = ref.watch(saleBoxProvider);
  final productBox = ref.watch(productBoxProvider);
  final eventRepo = ref.watch(eventRepositoryProvider);
  final clock = ref.watch(clockProvider);
  final hmac = ref.watch(hmacServiceProvider);
  
  return SaleNotifier(saleBox, productBox, eventRepo, clock, hmac, ref);
});
