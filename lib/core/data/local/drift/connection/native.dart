import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

QueryExecutor openConnection() {
  return LazyDatabase(() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'ironbook_outbox.db'));
      
      // We use createInBackground for better UI responsiveness during Tier 1
      return NativeDatabase.createInBackground(file, logStatements: kDebugMode);
    } catch (e, stack) {
      debugPrint('[DB] CRITICAL: Failed to open Drift database: $e');
      debugPrint('[DB] StackTrace: $stack');
      // In a real production scenario, we might attempt to rename the corrupted file 
      // and start fresh, but for now we rethrow to trigger the app's global error UI.
      rethrow;
    }
  });
}









