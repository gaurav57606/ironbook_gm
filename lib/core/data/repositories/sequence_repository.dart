import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../local/drift/outbox_database.dart';
import '../../providers/base_providers.dart';

abstract class ISequenceRepository {
  Future<String> getNextInvoiceNumber(String prefix);
  Future<void> reset(String prefix);
}

class DriftSequenceRepository implements ISequenceRepository {
  final OutboxDatabase _db;

  DriftSequenceRepository(this._db);

  @override
  Future<String> getNextInvoiceNumber(String prefix) async {
    return await _db.transaction(() async {
      final seq = await (_db.select(_db.invoiceSequences)..where((t) => t.prefix.equals(prefix))).getSingleOrNull();
      final currentNumber = seq?.nextNumber ?? 1;
      
      await _db.into(_db.invoiceSequences).insertOnConflictUpdate(
        InvoiceSequencesCompanion.insert(
          prefix: prefix,
          nextNumber: Value(currentNumber + 1),
        ),
      );
      
      return '$prefix${currentNumber.toString().padLeft(4, '0')}';
    });
  }

  @override
  Future<void> reset(String prefix) async {
    await _db.into(_db.invoiceSequences).insertOnConflictUpdate(
      InvoiceSequencesCompanion.insert(
        prefix: prefix,
        nextNumber: const Value(1),
      ),
    );
  }
}

final sequenceRepositoryProvider = Provider<ISequenceRepository>((ref) {
  final db = ref.watch(outboxDatabaseProvider);
  return DriftSequenceRepository(db);
});
