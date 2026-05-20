enum MonitoringEventType {
  userRegistered,
  membershipCreated,
  membershipRenewed,
  paymentSuccess,
  paymentFailed,
  appError
}

class MonitoringEvent {
  final String id;
  final MonitoringEventType eventType;
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  MonitoringEvent({
    required this.id,
    required this.eventType,
    required this.payload,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'event_type': eventType.name,
    'payload': payload,
    'created_at': createdAt.toIso8601String(),
  };

  @override
  String toString() => 'MonitoringEvent(id: $id, type: ${eventType.name})';
}
