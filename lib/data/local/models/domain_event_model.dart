import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

@HiveType(typeId: 10)
class DomainEvent extends HiveObject {
  @HiveField(0)
  late String id; // uuid v4

  @HiveField(1)
  late String entityId; // memberId or 'owner' or 'settings'

  @HiveField(2)
  late String eventType; // EventType enum name

  @HiveField(3)
  late Map<String, dynamic> payload;

  @HiveField(4)
  late DateTime deviceTimestamp;

  @HiveField(5)
  late bool synced; // false until Firestore confirms write

  @HiveField(6)
  late String hmacSignature; // SHA-256 HMAC

  @HiveField(7)
  late String deviceId;

  DomainEvent({
    String? id,
    required this.entityId,
    required this.eventType,
    required this.payload,
    DateTime? deviceTimestamp,
    this.synced = false,
    this.hmacSignature = '',
    required this.deviceId,
  }) {
    this.id = id ?? const Uuid().v4();
    this.deviceTimestamp = deviceTimestamp ?? DateTime.now();
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'entityId': entityId,
      'eventType': eventType,
      'payload': payload,
      'deviceTimestamp': deviceTimestamp.toIso8601String(),
      'synced': true,
      'hmacSignature': hmacSignature,
      'deviceId': deviceId,
    };
  }

  factory DomainEvent.fromFirestore(Map<String, dynamic> data) {
    return DomainEvent(
      id: data['id'],
      entityId: data['entityId'],
      eventType: data['eventType'],
      payload: Map<String, dynamic>.from(data['payload']),
      deviceTimestamp: DateTime.parse(data['deviceTimestamp']),
      synced: true,
      hmacSignature: data['hmacSignature'],
      deviceId: data['deviceId'],
    );
  }
}

enum EventType {
  memberCreated,
  planAssigned,
  paymentAdded,
  membershipExtended,
  joinDateEdited,
  invoiceGenerated,
  settingsChanged,
  ownerProfileUpdated,
  memberArchived,
}
