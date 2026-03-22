import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../data/local/models/member_snapshot_model.dart';
import '../data/local/models/domain_event_model.dart';

final membersProvider = StateNotifierProvider<MemberNotifier, List<MemberSnapshot>>((ref) {
  return MemberNotifier();
});

class MemberNotifier extends StateNotifier<List<MemberSnapshot>> {
  final String _deviceId = 'device-${const Uuid().v4().substring(0, 8)}';

  MemberNotifier() : super([]) {
    _init();
  }

  void _init() {
    if (!Hive.isBoxOpen('snapshots')) return;
    final box = Hive.box<MemberSnapshot>('snapshots');
    state = box.values.toList();
    
    // Listen for changes
    box.listenable().addListener(() {
      state = box.values.toList();
    });
  }

  Future<void> addMember({
    required String name,
    required String phone,
    required String planId,
    required double amount,
    required DateTime joinDate,
  }) async {
    final memberId = const Uuid().v4();
    
    // 1. Create Domain Event
    final event = DomainEvent(
      entityId: memberId,
      eventType: 'memberCreated',
      deviceId: _deviceId,
      payload: {
        'memberId': memberId,
        'name': name,
        'phone': phone,
        'planId': planId,
        'amount': amount,
        'joinDate': joinDate.toIso8601String(),
      },
    );

    // 2. Create Snapshot
    final snapshot = MemberSnapshot(
      memberId: memberId,
      name: name,
      phone: phone,
      joinDate: joinDate,
      planId: planId,
      expiryDate: joinDate.add(const Duration(days: 30)), 
      totalPaid: amount,
    );

    // 3. Persist to Hive
    final eventBox = Hive.box<DomainEvent>('events');
    final snapshotBox = Hive.box<MemberSnapshot>('snapshots');
    
    await eventBox.add(event);
    await snapshotBox.put(memberId, snapshot);
    
    // State updates automatically via listener in _init
  }
}
