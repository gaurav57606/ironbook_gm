import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../data/local/models/member_snapshot_model.dart';
import '../data/local/models/domain_event_model.dart';
import '../data/local/models/plan_model.dart';
import '../data/local/models/app_settings_model.dart';
import '../data/repositories/event_repository.dart';
import '../data/local/snapshot_builder.dart';
import '../core/utils/clock.dart';

final membersProvider = StateNotifierProvider<MemberNotifier, List<MemberSnapshot>>((ref) {
  final repo = ref.watch(eventRepositoryProvider);
  final clock = ref.watch(clockProvider);
  return MemberNotifier(repo, clock);
});

final memberSearchQueryProvider = StateProvider<String>((ref) => '');
final memberTabProvider = StateProvider<int>((ref) => 0); // 0: All, 1: Active, 2: Expiring, 3: Expired

final filteredMembersProvider = Provider<List<MemberSnapshot>>((ref) {
  final members = ref.watch(membersProvider);
  final query = ref.watch(memberSearchQueryProvider).toLowerCase();
  final tabIndex = ref.watch(memberTabProvider);
  final now = ref.watch(clockProvider).now;

  return members.where((m) {
    final matchesSearch = m.name.toLowerCase().contains(query) ||
        (m.phone?.contains(query) ?? false);
    
    if (!matchesSearch) return false;

    if (tabIndex == 0) return true; // All
    final status = m.getStatus(now);
    if (tabIndex == 1) return status == MemberStatus.active;
    if (tabIndex == 2) return status == MemberStatus.expiring;
    if (tabIndex == 3) return status == MemberStatus.expired;
    return true;
  }).toList();
});

class MemberNotifier extends StateNotifier<List<MemberSnapshot>> {
  final IEventRepository _repo;
  final IClock _clock;
  final String _deviceId = 'device-${const Uuid().v4().substring(0, 8)}';

  MemberNotifier(this._repo, this._clock) : super([]) {
    init();
  }

  void init() {
    if (!Hive.isBoxOpen('snapshots')) return;
    final box = Hive.box<MemberSnapshot>('snapshots');
    state = box.values.toList();

    // Recovery logic: If snapshots are missing but events exist, rebuild.
    _checkAndRecover();
    
    // Listen for events to rebuild snapshots
    _repo.watch().listen((event) async {
      final snapshotBox = Hive.box<MemberSnapshot>('snapshots');
      final current = snapshotBox.get(event.entityId);
      final updated = SnapshotBuilder.apply(current, event);
      if (updated != null) {
        await snapshotBox.put(event.entityId, updated);
        state = snapshotBox.values.toList();
      } else if (event.eventType == EventType.memberArchived.name) {
        await snapshotBox.delete(event.entityId);
        state = snapshotBox.values.toList();
      }
    });

    box.listenable().addListener(() {
      state = box.values.toList();
    });
  }

  Future<void> _checkAndRecover() async {
    final box = Hive.box<MemberSnapshot>('snapshots');
    if (box.isEmpty) {
       final events = _repo.getAllUnsynced(); // Simple check for demo/test
       // In a real prod app, we'd also check synced events if we had them locally
       if (events.isNotEmpty) {
         // ⚡ Bolt Optimization: Batch memory writes to avoid sequential disk I/O
         final Map<String, MemberSnapshot> batchMap = {};
         for (final event in events) {
           final current = batchMap[event.entityId] ?? box.get(event.entityId);
           final updated = SnapshotBuilder.apply(current, event);
           if (updated != null) {
              batchMap[event.entityId] = updated;
           }
         }
         if (batchMap.isNotEmpty) {
           await box.putAll(batchMap);
         }
         state = box.values.toList();
       }
    }
  }

  Future<String> addMember({
    required String name,
    required String phone,
    required String planId,
    required DateTime joinDate,
  }) async {
    final memberId = const Uuid().v4();
    final now = _clock.now;
    
    final plansBox = Hive.box<Plan>('plans');
    final plan = plansBox.get(planId);
    
    if (plan == null) throw Exception('Plan not found');

    final expiryDate = joinDate.add(Duration(days: plan.durationMonths * 30));

    final memberEvent = DomainEvent(
      entityId: memberId,
      eventType: EventType.memberCreated.name,
      deviceId: _deviceId,
      deviceTimestamp: now,
      payload: {
        'memberId': memberId,
        'name': name,
        'phone': phone,
        'planId': planId,
        'planName': plan.name,
        'joinDate': joinDate.toIso8601String(),
        'expiryDate': expiryDate.toIso8601String(),
      },
    );

    await _repo.persist(memberEvent);
    return memberId;
  }

  Future<void> renewMember({
    required String memberId,
    required String planId,
    required String method,
  }) async {
    final now = _clock.now;
    final snapshotsBox = Hive.box<MemberSnapshot>('snapshots');
    final plansBox = Hive.box<Plan>('plans');
    final settingsBox = Hive.box<AppSettings>('settings');

    final member = snapshotsBox.get(memberId);
    final plan = plansBox.get(planId);
    final settings = settingsBox.get('settings', defaultValue: AppSettings())!;

    if (member == null || plan == null) return;

    final subtotal = (plan.totalPrice * 100).toInt();
    final gstAmount = (subtotal * settings.gstRate) ~/ 100;
    final totalAmount = subtotal + gstAmount;
    
    DateTime baseDate = member.expiryDate ?? now;
    if (baseDate.isBefore(now)) baseDate = now;
    final newExpiryDate = baseDate.add(Duration(days: plan.durationMonths * 30));

    final paymentId = const Uuid().v4();
    
    final renewEvent = DomainEvent(
      entityId: memberId,
      eventType: 'MEMBERSHIP_RENEWED',
      deviceId: _deviceId,
      deviceTimestamp: now,
      payload: {
        'memberId': memberId,
        'paymentId': paymentId,
        'planId': planId,
        'amount': totalAmount,
        'newExpiry': newExpiryDate.toIso8601String(),
      },
    );

    await _repo.persist(renewEvent);
  }

  Future<void> deleteMember(String memberId) async {
    final deleteEvent = DomainEvent(
      entityId: memberId,
      eventType: EventType.memberArchived.name,
      deviceId: _deviceId,
      deviceTimestamp: _clock.now,
      payload: {'memberId': memberId},
    );

    await _repo.persist(deleteEvent);
  }

  Future<void> updateMember({
    required String memberId,
    required String name,
    required String phone,
  }) async {
    final updateEvent = DomainEvent(
      entityId: memberId,
      eventType: 'MEMBER_UPDATED',
      deviceId: _deviceId,
      deviceTimestamp: _clock.now,
      payload: {
        'memberId': memberId,
        'name': name,
        'phone': phone,
      },
    );
    await _repo.persist(updateEvent);
  }

  Future<void> recordAttendance(String memberId) async {
    final now = _clock.now;
    final checkInEvent = DomainEvent(
      entityId: memberId,
      eventType: 'CHECK_IN_RECORDED',
      deviceId: _deviceId,
      deviceTimestamp: now,
      payload: {
        'memberId': memberId,
        'timestamp': now.toIso8601String(),
      },
    );

    await _repo.persist(checkInEvent);
  }
}
