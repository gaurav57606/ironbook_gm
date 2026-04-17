import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

@HiveType(typeId: 10)
class DomainEvent extends HiveObject {
  @HiveField(0)
  late String id; // uuid v4

  @HiveField(1)
  late String entityId; // memberId or 'owner' or 'settings'

  @HiveField(2)
  late EventType eventType; // EventType enum

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
    required this.deviceTimestamp,
    this.synced = false,
    this.hmacSignature = '',
    required this.deviceId,
  }) {
    this.id = id ?? const Uuid().v4();
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'entityId': entityId,
      'eventType': eventType.name,
      'payload': payload,
      'deviceTimestamp': deviceTimestamp.toUtc().toIso8601String(),
      'synced': true,
      'hmacSignature': hmacSignature,
      'deviceId': deviceId,
    };
  }

  /// Filters payload for essential data only (Cloud Privacy Policy)
  Map<String, dynamic> toEssentialFirestore() {
    final essentialPayload = Map<String, dynamic>.from(payload);
    
    // Whitelist only essential fields for cloud storage
    final whitelist = {
      'memberId', 'name', 'phone', 'joinDate', 'planId', 
      'amount', 'paymentId', 'newExpiry', 'archived'
    };
    
    essentialPayload.removeWhere((key, value) => !whitelist.contains(key));

    return {
      'id': id,
      'entityId': entityId,
      'eventType': eventType.name,
      'payload': essentialPayload,
      'deviceTimestamp': deviceTimestamp.toUtc().toIso8601String(),
      'synced': true,
      'hmacSignature': hmacSignature,
      'deviceId': deviceId,
    };
  }

  factory DomainEvent.fromFirestore(Map<String, dynamic> data) {
    return DomainEvent(
      id: data['id'],
      entityId: data['entityId'],
      eventType: EventType.values.byName(data['eventType']),
      payload: Map<String, dynamic>.from(data['payload']),
      deviceTimestamp: DateTime.parse(data['deviceTimestamp']).toLocal(),
      synced: true,
      hmacSignature: data['hmacSignature'],
      deviceId: data['deviceId'],
    );
  }
}

@HiveType(typeId: 11) // Using different typeId for enum if needed, or keeping it
enum EventType {
  @HiveField(0)
  memberCreated,
  @HiveField(1)
  planAssigned,
  @HiveField(2)
  paymentAdded,
  @HiveField(3)
  membershipExtended,
  @HiveField(4)
  joinDateEdited,
  @HiveField(5)
  invoiceGenerated,
  @HiveField(6)
  settingsChanged,
  @HiveField(7)
  ownerProfileCreated,
  @HiveField(8)
  ownerProfileUpdated,
  @HiveField(9)
  plansUpdated,
  @HiveField(10)
  memberArchived,
  @HiveField(11)
  memberUpdated,
  @HiveField(12)
  membershipRenewed,
  @HiveField(13)
  paymentRecorded,
  @HiveField(14)
  checkInRecorded,
  @HiveField(15)
  ownershipTransferred,
}
