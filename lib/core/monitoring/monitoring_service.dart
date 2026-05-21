import 'monitoring_models.dart';
import 'monitoring_queue.dart';
import 'monitoring_sender.dart';
import 'supabase_monitoring_client.dart';
import 'monitoring_retry_manager.dart';

class MonitoringService {
  static final MonitoringService _instance = MonitoringService._internal();
  static int _counter = 0;
  factory MonitoringService() => _instance;

  final MonitoringQueue _queue = MonitoringQueue();
  final SupabaseMonitoringClient _client = SupabaseMonitoringClient();
  final MonitoringRetryManager _retryManager = MonitoringRetryManager();
  late final MonitoringSender _sender;

  MonitoringService._internal() {
    _sender = MonitoringSender(_client, _queue, _retryManager);
  }

  /// Internal queueing logic. Fails silently.
  static void _enqueue(MonitoringEventType type, Map<String, dynamic> payload) {
    try {
      final event = MonitoringEvent(
        id: '${DateTime.now().millisecondsSinceEpoch}_${_counter++}',
        eventType: type,
        createdAt: DateTime.now(),
        payload: payload,
      );
      _instance._queue.add(event);
    } catch (_) {
      // Never propagate exceptions
    }
  }

  // PUBLIC API

  static void logUserRegistration(String userId, String email, {String? gymName, String? ownerName, String? phone, String? address}) {
    _enqueue(MonitoringEventType.userRegistered, {
      'user_id': userId,
      'email': email,
      'gym_name': gymName,
      'owner_name': ownerName,
      'phone': phone,
      'address': address,
    });
  }

  static void logMembershipCreated(String memberId, String planName, double price, {
    String? ownerUid,
    String? name,
    String? phone,
    String? gender,
    int? age,
    DateTime? joinDate,
    DateTime? expiryDate,
  }) {
    _enqueue(MonitoringEventType.membershipCreated, {
      'member_id': memberId,
      'plan_name': planName,
      'price': price,
      'owner_uid': ownerUid,
      'name': name,
      'phone': phone,
      'gender': gender,
      'age': age,
      'join_date': joinDate?.toIso8601String(),
      'expiry_date': expiryDate?.toIso8601String(),
    });
  }

  static void logMembershipRenewed(String memberId, String planName, double price, {
    String? ownerUid,
    DateTime? expiryDate,
  }) {
    _enqueue(MonitoringEventType.membershipRenewed, {
      'member_id': memberId,
      'plan_name': planName,
      'price': price,
      'owner_uid': ownerUid,
      'expiry_date': expiryDate?.toIso8601String(),
    });
  }

  static void logPaymentSuccess(String transactionId, double amount, String method, {
    String? ownerUid,
    String? memberId,
    String? memberName,
    String? planName,
    DateTime? joinDate,
    DateTime? expiryDate,
  }) {
    _enqueue(MonitoringEventType.paymentSuccess, {
      'transaction_id': transactionId,
      'amount': amount,
      'method': method,
      'owner_uid': ownerUid,
      'member_id': memberId,
      'member_name': memberName,
      'plan_name': planName,
      'join_date': joinDate?.toIso8601String(),
      'expiry_date': expiryDate?.toIso8601String(),
    });
  }

  static void logPaymentFailure(String transactionId, double amount, String error) {
    _enqueue(MonitoringEventType.paymentFailed, {
      'transaction_id': transactionId,
      'amount': amount,
      'error': error,
    });
  }

  static void logAppError(String message, String stackTrace) {
    _enqueue(MonitoringEventType.appError, {
      'message': message,
      'stack_trace': stackTrace,
    });
  }
}
