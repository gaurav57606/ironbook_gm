import 'package:ironbook_gm/core/data/local/drift/outbox_database.dart';
import 'package:drift/native.dart';

class TestDatabaseFactory {
  static OutboxDatabase? _db;

  static Future<OutboxDatabase> create() async {
    // Return existing instance if available to avoid "database opened multiple times" warnings
    if (_db != null) return _db!;
    
    // Create a new in-memory instance for testing
    _db = OutboxDatabase(NativeDatabase.memory());
    return _db!;
  }

  static Future<void> dispose() async {
    await _db?.close();
    _db = null;
  }
}
