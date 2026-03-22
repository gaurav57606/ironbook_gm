import 'package:hive/hive.dart';
import 'join_date_change_model.dart';

@HiveType(typeId: 11)
class MemberSnapshot extends HiveObject {
  @HiveField(0)
  late String memberId;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String phone;

  @HiveField(3)
  late DateTime joinDate;

  @HiveField(4)
  String? planId;

  @HiveField(5)
  String? planName;

  @HiveField(6)
  DateTime? expiryDate; // STORED fact

  @HiveField(7)
  late double totalPaid;

  @HiveField(8)
  late List<String> paymentIds;

  @HiveField(9)
  late List<JoinDateChange> joinDateHistory;

  @HiveField(10)
  late bool archived;

  @HiveField(11)
  late DateTime lastUpdated;

  MemberSnapshot({
    required this.memberId,
    required this.name,
    required this.phone,
    required this.joinDate,
    this.planId,
    this.planName,
    this.expiryDate,
    this.totalPaid = 0.0,
    List<String>? paymentIds,
    List<JoinDateChange>? joinDateHistory,
    this.archived = false,
    DateTime? lastUpdated,
  }) {
    this.paymentIds = paymentIds ?? [];
    this.joinDateHistory = joinDateHistory ?? [];
    this.lastUpdated = lastUpdated ?? DateTime.now();
  }

  // ── COMPUTED ──
  int get daysRemaining {
    if (expiryDate == null) return 0;
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final expiry = DateTime(expiryDate!.year, expiryDate!.month, expiryDate!.day);
    return expiry.difference(today).inDays;
  }

  MemberStatus get status {
    if (expiryDate == null) return MemberStatus.pending;
    final d = daysRemaining;
    if (d < 0) return MemberStatus.expired;
    if (d <= 7) return MemberStatus.expiring;
    return MemberStatus.active;
  }

  factory MemberSnapshot.fromPayload(String id, Map<String, dynamic> payload) {
    return MemberSnapshot(
      memberId: id,
      name: payload['name'],
      phone: payload['phone'],
      joinDate: DateTime.parse(payload['joinDate']),
      planId: payload['planId'],
      planName: payload['planName'],
      expiryDate: payload['expiryDate'] != null ? DateTime.parse(payload['expiryDate']) : null,
    );
  }
}

enum MemberStatus { pending, active, expiring, expired }
