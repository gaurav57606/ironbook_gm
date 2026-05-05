import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'dart:io';
import 'package:ironbook_gm/core/data/local/models/member_snapshot_model.dart';
import 'package:ironbook_gm/core/data/local/adapters/manual_adapters.dart';

void main() {
  test('Hive Data Persistence Logic Verification', () async {
    // Setup temporary directory for Hive
    final tempDir = Directory.systemTemp.createTempSync();
    Hive.init(tempDir.path);
    
    // Register adapters
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(MemberSnapshotAdapter());
    }

    const boxName = 'test_members_box';
    
    // 1. Write data
    var box = await Hive.openBox<MemberSnapshot>(boxName);
    final member = MemberSnapshot(
      memberId: 'm1',
      name: 'Test Member',
      phone: '1234567890',
      joinDate: DateTime.now(),
      planId: 'p1',
      planName: 'Gold',
      expiryDate: DateTime.now().add(const Duration(days: 30)),
      lastUpdated: DateTime.now(),
    );
    
    await box.put(member.memberId, member);
    await box.close();
    
    // 2. Re-open and Verify
    box = await Hive.openBox<MemberSnapshot>(boxName);
    final retrieved = box.get('m1');
    
    expect(retrieved, isNotNull);
    expect(retrieved!.name, 'Test Member');
    expect(retrieved.phone, '1234567890');
    expect(retrieved.memberId, 'm1');
    
    await box.deleteFromDisk();
    tempDir.deleteSync(recursive: true);
  });
}



