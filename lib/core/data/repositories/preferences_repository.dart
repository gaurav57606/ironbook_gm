import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/base_providers.dart';
import '../local/drift/outbox_database.dart';

abstract class IPreferencesRepository {
  Future<String?> getString(String key);
  Future<void> setString(String key, String value);
  Future<int?> getInt(String key);
  Future<void> setInt(String key, int value);
}

class DriftPreferencesRepository implements IPreferencesRepository {
  final OutboxDatabase _db;

  DriftPreferencesRepository(this._db);

  @override
  Future<String?> getString(String key) async {
    final doc = await (_db.select(_db.preferences)..where((t) => t.key.equals(key))).getSingleOrNull();
    return doc?.value;
  }

  @override
  Future<void> setString(String key, String value) async {
    await _db.into(_db.preferences).insertOnConflictUpdate(
      PreferencesCompanion.insert(key: key, value: value),
    );
  }

  @override
  Future<int?> getInt(String key) async {
    final val = await getString(key);
    return val != null ? int.tryParse(val) : null;
  }

  @override
  Future<void> setInt(String key, int value) async {
    await setString(key, value.toString());
  }
}

final preferencesRepositoryProvider = Provider<IPreferencesRepository>((ref) {
  final db = ref.watch(outboxDatabaseProvider);
  return DriftPreferencesRepository(db);
});
