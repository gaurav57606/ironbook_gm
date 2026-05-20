import 'package:supabase_flutter/supabase_flutter.dart';
import 'monitoring_constants.dart';
import 'monitoring_models.dart';

class SupabaseMonitoringClient {
  static SupabaseClient? _client;
  bool _initAttempted = false;

  Future<void> _ensureInitialized() async {
    if (_client != null || _initAttempted) return;
    
    _initAttempted = true;
    try {
      final url = MonitoringConstants.supabaseUrl;
      final anonKey = MonitoringConstants.supabaseAnonKey;

      if (url.isEmpty || anonKey.isEmpty) return;

      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
        debug: false,
      );
      _client = Supabase.instance.client;
    } catch (_) {
      // Fail silently
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
      
      // Send batches
      final List<Future> futures = [];
      for (final entry in tableBatches.entries) {
        futures.add(
          client
              .from(entry.key)
              .upsert(entry.value) // Use upsert for identity tables (owners/members)
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
        // Legacy Archival
        routings.add(_Routing(
          table: MonitoringConstants.usersTable,
          data: {
            'user_id': event.payload['user_id'],
            'email': event.payload['email'],
            'metadata': event.payload,
            'created_at': event.createdAt.toIso8601String(),
          },
        ));
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
      case MonitoringEventType.membershipRenewed:
        // Legacy Archival
        routings.add(_Routing(
          table: MonitoringConstants.membershipsTable,
          data: {
            'member_id': event.payload['member_id'],
            'plan_name': event.payload['plan_name'],
            'price': event.payload['price'],
            'event_type': event.eventType == MonitoringEventType.membershipCreated ? 'created' : 'renewed',
            'metadata': event.payload,
            'created_at': event.createdAt.toIso8601String(),
          },
        ));
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
            'payload': event.payload,
            'created_at': event.createdAt.toIso8601String(),
          },
        ));
        break;
    }

    return routings;
  }
}

class _Routing {
  final String table;
  final Map<String, dynamic> data;
  _Routing({required this.table, required this.data});
}
