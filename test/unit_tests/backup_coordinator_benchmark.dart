import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:ironbook_gm/core/data/local/drift/outbox_database.dart';

void main() {
  late OutboxDatabase db;

  setUp(() {
    db = OutboxDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('Benchmark: Sequential await inside transaction vs batch', () async {
    final dummyMembers = List.generate(500, (i) => MembersCompanion.insert(
      id: 'm_$i',
      name: 'Test Member $i',
      joinDate: DateTime.now(),
      hmacSignature: const Value('sig'),
    ));

    final stopwatch = Stopwatch()..start();
    await db.transaction(() async {
      for (final m in dummyMembers) {
        await db.into(db.members).insert(m);
      }
    });
    stopwatch.stop();
    final transactionMs = stopwatch.elapsedMilliseconds;
    print('Transaction with sequential await took: $transactionMs ms');

    await db.delete(db.members).go();

    stopwatch.reset();
    stopwatch.start();
    await db.batch((batch) {
      for (final m in dummyMembers) {
        batch.insert(db.members, m);
      }
    });
    stopwatch.stop();
    final batchMs = stopwatch.elapsedMilliseconds;
    print('Batch insertion took: $batchMs ms');

    expect(batchMs, lessThan(transactionMs));
  });
}
