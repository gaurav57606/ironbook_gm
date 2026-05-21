import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../local/drift/outbox_database.dart' as db;
import '../local/models/product_model.dart' as domain;
import '../../providers/base_providers.dart';

abstract class IProductRepository {
  Future<List<domain.Product>> getAllProducts();
  Stream<List<domain.Product>> watchAllProducts();
  Future<void> upsertProduct(domain.Product product);
}

class DriftProductRepository implements IProductRepository {
  final db.OutboxDatabase _db;

  DriftProductRepository(this._db);

  @override
  Future<List<domain.Product>> getAllProducts() async {
    final docs = await _db.select(_db.products).get();
    return docs.map((d) => domain.Product.fromDrift(d)).toList();
  }

  @override
  Stream<List<domain.Product>> watchAllProducts() {
    return (_db.select(_db.products)
          ..orderBy([(p) => OrderingTerm.asc(p.name)]))
        .watch()
        .map((docs) => docs.map((d) => domain.Product.fromDrift(d)).toList());
  }

  @override
  Future<void> upsertProduct(domain.Product product) async {
    await _db.into(_db.products).insertOnConflictUpdate(
      db.ProductsCompanion.insert(
        id: product.id,
        name: product.name,
        price: product.price,
        category: product.category,
        iconCodePoint: product.iconCodePoint,
      ),
    );
  }
}

final productRepositoryProvider = Provider<IProductRepository>((ref) {
  final db = ref.watch(outboxDatabaseProvider);
  return DriftProductRepository(db);
});
