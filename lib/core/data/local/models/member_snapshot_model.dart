import 'package:hive/hive.dart';
import 'join_date_change_model.dart';
part 'member_snapshot_model.g.dart';

@HiveType(typeId: 11)
class MemberSnapshot extends HiveObject {
  @HiveField(0)
  late String memberId;

  @HiveField(1)
  late String name;

  @HiveField(2)
  String? phone;

  @HiveField(3)
  late DateTime joinDate;

  @HiveField(4)
  String? planId;

  @HiveField(5)
  String? planName;

  @HiveField(6)
  DateTime? expiryDate; // STORED fact

  @HiveField(7)
  late int totalPaid; // Stored in paise (integer)

  @HiveField(8)
  late List<String> paymentIds;

  @HiveField(9)
  late List<JoinDateChange> joinDateHistory;

  @HiveField(10)
  late bool archived;

  @HiveField(11)
  late DateTime lastUpdated;

  @HiveField(12)
  String? gender;

  @HiveField(13)
  int? age;

  @HiveField(14)
  String? checkInPin;

  @HiveField(15)
  DateTime? lastCheckIn;

  @HiveField(16)
  String? lastCheckInDevice;

  @HiveField(17)
  String? hmacSignature; // Cryptographic integrity seal

  @HiveField(18)
  String? photoPath; // local file path for member avatar

  @HiveField(19)
  String? photoUrl; // Supabase Storage public URL

  MemberSnapshot({
    required this.memberId,
    required this.name,
    this.phone,
    required this.joinDate,
    this.planId,
    this.planName,
    this.expiryDate,
    this.totalPaid = 0,
    List<String>? paymentIds,
    List<JoinDateChange>? joinDateHistory,
    this.archived = false,
    DateTime? lastUpdated,
    this.gender,
    this.age,
    this.checkInPin,
    this.lastCheckIn,
    this.lastCheckInDevice,
    this.hmacSignature,
    this.photoPath,
    this.photoUrl,
  }) {
    this.paymentIds = paymentIds ?? [];
    this.joinDateHistory = joinDateHistory ?? [];
    this.lastUpdated = lastUpdated ?? DateTime.now();
  }

  // ── GETTERS (Convenience for UI using today's date) ──
  int get daysRemaining => getDaysRemaining(DateTime.now());
  MemberStatus get status => getStatus(DateTime.now());

  // ── COMPUTED (Now deterministic) ──
  int getDaysRemaining(DateTime relativeTo) {
    if (expiryDate == null) return 0;
    final today =
        DateTime.utc(relativeTo.year, relativeTo.month, relativeTo.day);
    final expiry =
        DateTime.utc(expiryDate!.year, expiryDate!.month, expiryDate!.day);
    return (expiry.millisecondsSinceEpoch - today.millisecondsSinceEpoch) ~/
        86400000;
  }

  MemberStatus getStatus(DateTime relativeTo) {
    if (archived) return MemberStatus.archived;
    if (expiryDate == null) return MemberStatus.pending;

    final today =
        DateTime.utc(relativeTo.year, relativeTo.month, relativeTo.day);
    final expiry =
        DateTime.utc(expiryDate!.year, expiryDate!.month, expiryDate!.day);
    final d = (expiry.millisecondsSinceEpoch - today.millisecondsSinceEpoch) ~/
        86400000;

    if (d < 0) return MemberStatus.expired;
    if (d <= 7) return MemberStatus.expiring;
    return MemberStatus.active;
  }

  MemberSnapshot copyWith({
    String? name,
    String? phone,
    DateTime? joinDate,
    DateTime? expiryDate,
    String? planId,
    String? planName,
    int? totalPaid,
    List<String>? paymentIds,
    bool? archived,
    DateTime? lastUpdated,
    String? gender,
    int? age,
    String? checkInPin,
    DateTime? lastCheckIn,
    String? lastCheckInDevice,
    String? hmacSignature,
    String? photoPath,
    String? photoUrl,
  }) {
    return MemberSnapshot(
      memberId: memberId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      joinDate: joinDate ?? this.joinDate,
      planId: planId ?? this.planId,
      planName: planName ?? this.planName,
      expiryDate: expiryDate ?? this.expiryDate,
      totalPaid: totalPaid ?? this.totalPaid,
      paymentIds: paymentIds ?? List.from(this.paymentIds),
      joinDateHistory: List.from(joinDateHistory),
      archived: archived ?? this.archived,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      checkInPin: checkInPin ?? this.checkInPin,
      lastCheckIn: lastCheckIn ?? this.lastCheckIn,
      lastCheckInDevice: lastCheckInDevice ?? this.lastCheckInDevice,
      hmacSignature: hmacSignature ?? this.hmacSignature,
      photoPath: photoPath ?? this.photoPath,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  factory MemberSnapshot.fromPayload(String id, Map<String, dynamic> payload) {
    return MemberSnapshot(
      memberId: id,
      name: payload['name'],
      phone: payload['phone'],
      joinDate: DateTime.parse(payload['joinDate']),
      planId: payload['planId'],
      planName: payload['planName'],
      expiryDate: payload['expiryDate'] != null
          ? DateTime.parse(payload['expiryDate'])
          : null,
      totalPaid: payload['totalPaid'] ?? 0,
      archived: payload['archived'] ?? false,
      paymentIds: List<String>.from(payload['paymentIds'] ?? []),
      lastUpdated: payload['lastUpdated'] != null
          ? DateTime.parse(payload['lastUpdated'])
          : DateTime.now(),
      gender: payload['gender'],
      age: payload['age'],
      checkInPin: payload['checkInPin'],
      lastCheckIn: payload['lastCheckIn'] != null
          ? DateTime.parse(payload['lastCheckIn'])
          : null,
      lastCheckInDevice: payload['lastCheckInDevice'],
      hmacSignature: payload['hmacSignature'],
      photoPath: payload['photoPath'],
      photoUrl: payload['photoUrl'],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemberSnapshot &&
          runtimeType == other.runtimeType &&
          memberId == other.memberId &&
          name == other.name &&
          phone == other.phone &&
          joinDate == other.joinDate &&
          totalPaid == other.totalPaid &&
          planId == other.planId &&
          expiryDate == other.expiryDate &&
          _listEquals(paymentIds, other.paymentIds) &&
          _listEquals(joinDateHistory, other.joinDateHistory) &&
          archived == other.archived;

  @override
  int get hashCode => Object.hash(
        memberId,
        name,
        phone,
        joinDate,
        totalPaid,
        planId,
        expiryDate,
        Object.hashAll(paymentIds),
        Object.hashAll(joinDateHistory),
        archived,
      );

  bool _listEquals(List? a, List? b) {
    if (a == null || b == null) return a == b;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() {
    return 'MemberSnapshot(id: $memberId, name: $name, paid: $totalPaid, expiry: $expiryDate)';
  }

  Map<String, dynamic> toFirestore() {
    return {
      'memberId': memberId,
      'name': name,
      'phone': phone,
      'joinDate': joinDate.toIso8601String(),
      'planId': planId,
      'planName': planName,
      'expiryDate': expiryDate?.toIso8601String(),
      'totalPaid': totalPaid,
      'paymentIds': paymentIds,
      'archived': archived,
      'lastUpdated': lastUpdated.toIso8601String(),
      'gender': gender,
      'age': age,
      'checkInPin': checkInPin,
      'lastCheckIn': lastCheckIn?.toIso8601String(),
      'lastCheckInDevice': lastCheckInDevice,
      'hmacSignature': hmacSignature,
      'photoPath': photoPath,
      'photoUrl': photoUrl,
    };
  }

  Map<String, dynamic> toJson() => toFirestore();

  // Drift Integration
  factory MemberSnapshot.fromDrift(dynamic d) {
    return MemberSnapshot(
      memberId: d.id,
      name: d.name,
      phone: d.phone,
      joinDate: d.joinDate,
      planId: d.planId,
      planName: d.planName,
      expiryDate: d.expiryDate,
      totalPaid: d.totalPaid,
      archived: d.archived,
      gender: d.gender,
      age: d.age,
      checkInPin: d.checkInPin,
      lastCheckIn: d.lastCheckIn,
      hmacSignature: d.hmacSignature,
      photoPath: d.photoPath,
    );
  }

  dynamic toDrift() {
    return null;
  }
}

enum MemberStatus { pending, active, expiring, expired, archived }
