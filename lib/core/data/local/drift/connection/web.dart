import 'dart:async';
import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
// ignore: deprecated_member_use
import 'package:drift/web.dart';
import 'package:flutter/foundation.dart';

/// Opens the drift database for the web.
/// 
/// This implementation tries multiple strategies to provide the best performance:
/// 1. Try modern Wasm-based SQLite (best performance/stability)
/// 2. Fallback to legacy IndexedDB-based storage (deprecated but reliable for migration)
QueryExecutor openConnection() {
  return DatabaseConnection.delayed(Future(() async {
    try {
      // ⚡ Strategy 1: Attempt WASM + Sqlite3 (Modern Standard)
      // Note: Requires sqlite3.wasm in the web/ directory
      final result = await WasmDatabase.open(
        databaseName: 'ironbook_outbox_v2', 
        sqlite3Uri: Uri.parse('sqlite3.wasm'),
        driftWorkerUri: Uri.parse('drift_worker.js'),
        initializeDatabase: () async {
          // You could run migrations here if needed before the first open
          return null;
        },
      );

      if (result.missingFeatures.isNotEmpty) {
        debugPrint('Drift WASM: Missing features ${result.missingFeatures}. Falling back to legacy.');
      } else {
        debugPrint('Drift: Using modern WASM database.');
        return result.resolvedExecutor;
      }
    } catch (e) {
      debugPrint('Drift WASM Error: $e. Using legacy fallback.');
    }

    // 🕸️ Strategy 2: Fallback to Legacy WebDatabase (IndexedDB)
    // This ensures the app still runs if WASM is blocked or files are missing
    try {
      final db = WebDatabase.withStorage(
        DriftWebStorage.indexedDb('ironbook_outbox'),
      );
      return DatabaseConnection(db);
    } catch (e) {
      debugPrint('Drift: ALL web connection strategies failed: $e');
      rethrow;
    }
  }));
}
