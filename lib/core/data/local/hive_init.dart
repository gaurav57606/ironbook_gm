import 'package:flutter/foundation.dart';

/// Legacy Hive initialization. 
/// Hive has been decommissioned in favor of Drift (SQLite).
/// This class is kept as a stub during the final transition phase.
class HiveInit {
  static void registerAdapters() {
    // No-op: Adapters are no longer needed as we use Drift.
  }

  static Future<void> openAllBoxes() async {
    // No-op: All data is now in Drift/SQLite.
  }

  static Future<bool> openWithCorruptionGuard() async {
    // Legacy support: always returns true as storage is now Drift.
    return true;
  }
}
