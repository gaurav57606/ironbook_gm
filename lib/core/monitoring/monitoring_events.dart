// monitoring_events.dart
import 'package:uuid/uuid.dart';
import 'monitoring_models.dart';

/// Factory helpers — convenience wrappers around MonitoringEvent construction.
/// All actual enqueuing is done via MonitoringService.logXxx() static methods.
class MonitoringEvents {
  static const _uuid = Uuid();

  static MonitoringEvent userRegistered({
    required String userId,
    required String email,
    String? gymName,
    String? ownerName,
    String? phone,
    String? address,
  }) =>
      MonitoringEvent(
        id: _uuid.v4(),
        eventType: MonitoringEventType.userRegistered,
        createdAt: DateTime.now(),
        payload: {
          'user_id': userId,
          'email': email,
          'gym_name': gymName,
          'owner_name': ownerName,
          'phone': phone,
          'address': address,
        },
      );

  static MonitoringEvent membershipCreated({
    required String memberId,
    required String planName,
    required double price,
    String? ownerUid,
    String? name,
    String? phone,
    String? gender,
    int? age,
    DateTime? joinDate,
    DateTime? expiryDate,
  }) =>
      MonitoringEvent(
        id: _uuid.v4(),
        eventType: MonitoringEventType.membershipCreated,
        createdAt: DateTime.now(),
        payload: {
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
        },
      );

  static MonitoringEvent membershipRenewed({
    required String memberId,
    required String planName,
    required double price,
    String? ownerUid,
    String? name,
    String? phone,
    String? gender,
    int? age,
    DateTime? joinDate,
    DateTime? expiryDate,
  }) =>
      MonitoringEvent(
        id: _uuid.v4(),
        eventType: MonitoringEventType.membershipRenewed,
        createdAt: DateTime.now(),
        payload: {
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
        },
      );

  static MonitoringEvent paymentSuccess({
    required String transactionId,
    required double amount,
    required String method,
    String? ownerUid,
    String? memberId,
    String? memberName,
    String? planName,
    DateTime? joinDate,
    DateTime? expiryDate,
  }) =>
      MonitoringEvent(
        id: _uuid.v4(),
        eventType: MonitoringEventType.paymentSuccess,
        createdAt: DateTime.now(),
        payload: {
          'transaction_id': transactionId,
          'amount': amount,
          'method': method,
          'owner_uid': ownerUid,
          'member_id': memberId,
          'member_name': memberName,
          'plan_name': planName,
          'join_date': joinDate?.toIso8601String(),
          'expiry_date': expiryDate?.toIso8601String(),
        },
      );

  static MonitoringEvent appError(String message, String? stackTrace) =>
      MonitoringEvent(
        id: _uuid.v4(),
        eventType: MonitoringEventType.appError,
        createdAt: DateTime.now(),
        payload: {'message': message, 'stack_trace': stackTrace},
      );
}
