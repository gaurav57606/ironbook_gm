import 'package:supabase_flutter/supabase_flutter.dart';
import 'monitoring_constants.dart';
import 'monitoring_models.dart';

class SupabaseMonitoringClient {
  static SupabaseClient? _client;
  bool _initAttempted = false;

  Future<void> _ensureInitialized() async {
    // Already connected — nothing to do.
    if (_client != null) return;

    // Try to reuse an existing Supabase instance (safest path).
    // This succeeds if Supabase.initialize() was already called anywhere.
    try {
      _client = Supabase.instance.client;
      return;
    } catch (_) {
      // Not yet initialized — fall through.
    }

    // Prevent concurrent initialization (two timer ticks overlapping).
    if (_initAttempted) return;
    _initAttempted = true;

    try {
      final url     = MonitoringConstants.supabaseUrl;
      final anonKey = MonitoringConstants.supabaseAnonKey;

      // If .env keys are missing, reset flag so next tick retries.
      // This handles the case where dotenv loads slowly or .env is missing.
      if (url.isEmpty || anonKey.isEmpty) {
        _initAttempted = false;
        return;
      }

      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
        debug: false,
      );
      _client = Supabase.instance.client;
      // Success: leave _initAttempted = true to prevent double-init crashes.

    } catch (_) {
      // Network failure, bad credentials, or timeout.
      // RESET the flag so the next 25-second flush cycle retries.
      // _client stays null — batchInsert will safely return false.
      _initAttempted = false;
    }
  }

  /// Inserts a single event. Append-only.
  Future<bool> sendEvent(MonitoringEvent event) async {
    return batchInsert([event]);
  }

  /// Batch inserts multiple events. Append-only.
  Future<bool> batchInsert(List<MonitoringEvent> events) async {
    if (events.isEmpty) return true;
    
    try {
      await _ensureInitialized();
      
      final client = _client;
      if (client == null) return false;
      
      // Group events by table
      final Map<String, List<Map<String, dynamic>>> tableBatches = {};
      
      for (final event in events) {
        final targets = _getRoutings(event);
        for (final target in targets) {
          tableBatches.putIfAbsent(target.table, () => []).add(target.data);
        }
      }
      
      // Deduplicate rows within identity tables before sending.
      // Prevents "ON CONFLICT DO UPDATE command cannot affect row a second time"
      // which occurs when paymentSuccess logs two gym_members writes in one batch.
      final List<Future> futures = [];
      for (final entry in tableBatches.entries) {
        final String tableName = entry.key;
        final List<Map<String, dynamic>> rows = entry.value;

        final List<Map<String, dynamic>> dedupedRows;
        if (tableName == MonitoringConstants.membersTable) {
          // Composite PK: (member_id, owner_uid) — deduplicate on member_id
          // keeping the last write (most up-to-date state) for each member_id.
          dedupedRows = _deduplicateByKey(rows, 'member_id');
        } else if (tableName == MonitoringConstants.ownersTable) {
          dedupedRows = _deduplicateByKey(rows, 'uid');
        } else if (tableName == MonitoringConstants.paymentEventsTable) {
          dedupedRows = _deduplicateByKey(rows, 'event_id');
        } else {
          // Append-only tables (archive, activity, audit) — no dedup needed.
          dedupedRows = rows;
        }

        futures.add(
          client
              .from(tableName)
              .upsert(dedupedRows)
              .timeout(MonitoringConstants.sendTimeout)
        );
      }
      
      await Future.wait(futures);
      return true;
    } catch (_) {
      // ALL monitoring operations must fail silently.
      return false;
    }
  }

  List<_Routing> _getRoutings(MonitoringEvent event) {
    final List<_Routing> routings = [];

    switch (event.eventType) {
      case MonitoringEventType.userRegistered:
        // Finalized Archival: Gym Owners
        if (event.payload['user_id'] != null) {
          routings.add(_Routing(
            table: MonitoringConstants.ownersTable,
            data: {
              'uid': event.payload['user_id'],
              'gym_name': event.payload['gym_name'] ?? 'Unknown Gym',
              'owner_name': event.payload['owner_name'],
              'phone': event.payload['phone'],
              'email': event.payload['email'],
              'address': event.payload['address'],
              'registered_at': event.createdAt.toIso8601String(),
              'last_seen_at': event.createdAt.toIso8601String(),
            },
          ));
        }
        break;

      case MonitoringEventType.membershipCreated:
        // Finalized Archival: Gym Members
        if (event.payload['member_id'] != null && event.payload['owner_uid'] != null) {
          routings.add(_Routing(
            table: MonitoringConstants.membersTable,
            data: {
              'member_id': event.payload['member_id'],
              'owner_uid': event.payload['owner_uid'],
              'name': event.payload['name'] ?? 'Unknown Member',
              'phone': event.payload['phone'],
              'gender': event.payload['gender'],
              'age': event.payload['age'],
              'plan_name': event.payload['plan_name'],
              'join_date': event.payload['join_date'],
              'expiry_date': event.payload['expiry_date'],
              'last_updated_at': event.createdAt.toIso8601String(),
            },
          ));
        }
        break;

      case MonitoringEventType.membershipRenewed:
        if (event.payload['member_id'] != null && event.payload['owner_uid'] != null) {
          final memberData = <String, dynamic>{
            'member_id': event.payload['member_id'],
            'owner_uid': event.payload['owner_uid'],
            'last_updated_at': event.createdAt.toIso8601String(),
          };
          // Only include fields that are non-null to avoid overwriting good data
          if (event.payload['name'] != null) memberData['name'] = event.payload['name'];
          if (event.payload['phone'] != null) memberData['phone'] = event.payload['phone'];
          if (event.payload['gender'] != null) memberData['gender'] = event.payload['gender'];
          if (event.payload['age'] != null) memberData['age'] = event.payload['age'];
          if (event.payload['plan_name'] != null) memberData['plan_name'] = event.payload['plan_name'];
          if (event.payload['expiry_date'] != null) memberData['expiry_date'] = event.payload['expiry_date'];
          if (event.payload['join_date'] != null) memberData['join_date'] = event.payload['join_date'];
          routings.add(_Routing(table: MonitoringConstants.membersTable, data: memberData));
        }
        break;

      case MonitoringEventType.paymentSuccess:
        // Legacy Archival
        routings.add(_Routing(
          table: MonitoringConstants.paymentsTable,
          data: {
            'transaction_id': event.payload['transaction_id'],
            'amount': event.payload['amount'],
            'method': event.payload['method'],
            'status': 'success',
            'metadata': event.payload,
            'created_at': event.createdAt.toIso8601String(),
          },
        ));
        // Finalized Archival: Payment Ledger & Member Update
        if (event.payload['owner_uid'] != null && event.payload['member_id'] != null) {
          routings.add(_Routing(
            table: MonitoringConstants.paymentEventsTable,
            data: {
              'event_id': event.payload['transaction_id'],
              'owner_uid': event.payload['owner_uid'],
              'member_id': event.payload['member_id'],
              'member_name': event.payload['member_name'],
              'event_type': 'paymentRecorded',
              'plan_name': event.payload['plan_name'],
              'amount': event.payload['amount'],
              'payment_mode': event.payload['method'],
              'join_date': event.payload['join_date'],
              'new_expiry_date': event.payload['expiry_date'],
              'device_timestamp': event.createdAt.toIso8601String(),
            },
          ));
          // Also update member's latest plan/expiry
          routings.add(_Routing(
            table: MonitoringConstants.membersTable,
            data: {
              'member_id': event.payload['member_id'],
              'owner_uid': event.payload['owner_uid'],
              'plan_name': event.payload['plan_name'],
              'expiry_date': event.payload['expiry_date'],
              'last_updated_at': event.createdAt.toIso8601String(),
            },
          ));
        }
        break;

      case MonitoringEventType.paymentFailed:
        routings.add(_Routing(
          table: MonitoringConstants.paymentsTable,
          data: {
            'transaction_id': event.payload['transaction_id'],
            'amount': event.payload['amount'],
            'method': event.payload['method'],
            'status': 'failed',
            'error_message': event.payload['error'],
            'metadata': event.payload,
            'created_at': event.createdAt.toIso8601String(),
          },
        ));
        break;

      case MonitoringEventType.appError:
        routings.add(_Routing(
          table: MonitoringConstants.activityTable,
          data: {
            'event_name': 'app_error',
            'severity': 'error',
            'owner_uid': event.payload['owner_uid'],
            'user_id': event.payload['user_id'],
            'payload': event.payload,
            'created_at': event.createdAt.toIso8601String(),
          },
        ));
        break;
    }

    return routings;
  }

  /// Merges duplicate rows that share the same [keyField] value within a single 
  /// batch list, keeping the last occurrence's values (most recent state).
  /// This prevents PostgreSQL's "cannot affect row a second time" upsert error.
  List<Map<String, dynamic>> _deduplicateByKey(
    List<Map<String, dynamic>> rows,
    String keyField,
  ) {
    final Map<dynamic, Map<String, dynamic>> merged = {};
    for (final row in rows) {
      final key = row[keyField];
      if (key == null) continue;
      if (!merged.containsKey(key)) {
        merged[key] = Map<String, dynamic>.from(row);
      } else {
        // Later row overwrites earlier row's values — last write wins.
        merged[key]!.addAll(row);
      }
    }
    // Re-add any rows without a key field as-is (should not normally occur).
    final orphans = rows.where((r) => r[keyField] == null).toList();
    return [...merged.values, ...orphans];
  }
}

class _Routing {
  final String table;
  final Map<String, dynamic> data;
  _Routing({required this.table, required this.data});
}
