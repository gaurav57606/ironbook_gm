import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../local/drift/outbox_database.dart' as db;
import '../local/models/sale_model.dart' as domain;
import '../../providers/base_providers.dart';

import '../local/models/domain_event_model.dart';
import '../../constants/event_payload_keys.dart';

abstract class ISaleRepository {
  Future<void> upsertSale(domain.Sale sale);
  Future<void> upsertSales(List<domain.Sale> sales);
  Future<domain.Sale?> getSale(String id);
  Future<List<String>> getAllSaleIds();
  Future<List<domain.Sale>> getSalesByMember(String memberId);
  Future<List<domain.Sale>> getAllSales();
  Future<void> applyEvent(DomainEvent event);
}

class DriftSaleRepository implements ISaleRepository {
  final db.OutboxDatabase _db;

  DriftSaleRepository(this._db);

  db.SalesCompanion _toCompanion(domain.Sale sale) {
    return db.SalesCompanion.insert(
      id: sale.id,
      memberId: Value(sale.memberId),
      date: sale.date,
      totalAmount: sale.totalAmount,
      paymentMethod: sale.paymentMethod,
      invoiceNumber: sale.invoiceNumber,
      itemsJson: jsonEncode(sale.items
          .map((i) => {
                'productId': i.productId,
                'productName': i.productName,
                'price': i.price,
                'quantity': i.quantity,
              })
          .toList()),
      hmacSignature: Value(sale.hmacSignature ?? ''),
    );
  }

  @override
  Future<void> upsertSale(domain.Sale sale) async {
    debugPrint(
        '[DB] SaleRepository: Upserting sale ${sale.id} (Invoice: ${sale.invoiceNumber})');
    await _db.into(_db.sales).insertOnConflictUpdate(_toCompanion(sale));
  }

  @override
  Future<void> upsertSales(List<domain.Sale> sales) async {
    if (sales.isEmpty) return;
    await _db.batch((batch) {
      batch.insertAll(
        _db.sales,
        sales.map((sale) => _toCompanion(sale)),
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  @override
  Future<domain.Sale?> getSale(String id) async {
    final doc = await (_db.select(_db.sales)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return doc != null ? domain.Sale.fromDrift(doc) : null;
  }

  @override
  Future<List<String>> getAllSaleIds() async {
    final query = _db.selectOnly(_db.sales)..addColumns([_db.sales.id]);
    final results = await query.get();
    return results.map((row) => row.read(_db.sales.id)!).toList();
  }

  @override
  Future<List<domain.Sale>> getSalesByMember(String memberId) async {
    final docs = await (_db.select(_db.sales)
          ..where((t) => t.memberId.equals(memberId)))
        .get();
    return docs.map((d) => domain.Sale.fromDrift(d)).toList();
  }

  @override
  Future<List<domain.Sale>> getAllSales() async {
    final docs = await _db.select(_db.sales).get();
    return docs.map((d) => domain.Sale.fromDrift(d)).toList();
  }

  @override
  Future<void> applyEvent(DomainEvent event) async {
    await _db.transaction(() async {
      if (event.eventType == EventType.saleRecorded) {
        final saleId = event.payload[EventPayloadKeys.saleId] as String?;
        if (saleId != null) {
          debugPrint(
              '[DB] SaleRepository: Applying saleRecorded event for $saleId');
          final sale = domain.Sale.fromPayload(
              saleId, event.payload, event.deviceTimestamp);
          await upsertSale(sale);
        }
      }
    });
  }
}

final saleRepositoryProvider = Provider<ISaleRepository>((ref) {
  final db = ref.watch(outboxDatabaseProvider);
  return DriftSaleRepository(db);
});
