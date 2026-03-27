import 'package:flutter_test/flutter_test.dart';
import 'package:ironbook_gm/core/services/hmac_service.dart';
import 'package:ironbook_gm/data/local/models/member_snapshot_model.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';

void main() {
  group('Phase 5: Performance Benchmarks', () {
    setUpAll(() async {
      final tempDir = Directory.systemTemp.createTempSync();
      Hive.init(tempDir.path);
      HmacService.setKeyForTest('benchmark_test_key_32_chars_long_1234');
    });

    test('Data Scaling: Processing 1000+ Member Events', () async {
      final watch = Stopwatch()..start();
      
      // Generate 1000 members
      final snapshots = List.generate(1000, (i) => MemberSnapshot(
        memberId: 'member_$i',
        name: 'Member $i',
        phone: '1234567890',
        joinDate: DateTime.now().subtract(const Duration(days: 30)),
        totalPaid: 0,
        archived: false,
      ));
      
      expect(snapshots.length, 1000);
      
      final elapsed = watch.elapsedMilliseconds;
      // print('Benchmark: Generated 1000 snapshots in ${elapsed}ms');
      expect(elapsed, lessThan(500), reason: 'Scaling optimization failed: Member generation too slow');
    });

    test('Cold Start: Hive Repository Initialization', () async {
      final watch = Stopwatch()..start();
      
      // Simulate box opening
      await Hive.openBox<MemberSnapshot>('snapshots');
      
      final elapsed = watch.elapsedMilliseconds;
      // print('Benchmark: Hive Initialization in ${elapsed}ms');
      expect(elapsed, lessThan(200), reason: 'Cold start optimization failed: Hive too slow');
    });
  });
}
