import 'package:uuid/uuid.dart';
import 'monitoring_models.dart';

class MonitoringEvents {
  static const _uuid = Uuid();

  static MonitoringEvent userRegistered(String userId, String email) => MonitoringEvent(
    id: _uuid.v4(),
    eventType: MonitoringEventType.userRegistered,
    createdAt: DateTime.now(),
    payload: {'user_id': userId, 'email': email},
  );

  static MonitoringEvent membershipCreated(String memberId, String plan) => MonitoringEvent(
    id: _uuid.v4(),
    eventType: MonitoringEventType.membershipCreated,
    createdAt: DateTime.now(),
    payload: {'member_id': memberId, 'plan': plan},
  );

  static MonitoringEvent paymentSuccess(String transactionId, double amount) => MonitoringEvent(
    id: _uuid.v4(),
    eventType: MonitoringEventType.paymentSuccess,
    createdAt: DateTime.now(),
    payload: {'transaction_id': transactionId, 'amount': amount},
  );

  static MonitoringEvent appError(String message, String? stackTrace) => MonitoringEvent(
    id: _uuid.v4(),
    eventType: MonitoringEventType.appError,
    createdAt: DateTime.now(),
    payload: {'message': message, 'stack_trace': stackTrace},
  );
}
