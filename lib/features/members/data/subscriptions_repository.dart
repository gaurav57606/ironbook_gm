import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ironbook_gm/core/data/local/drift/outbox_database.dart';
import 'package:ironbook_gm/core/providers/base_providers.dart';
import 'package:uuid/uuid.dart';

abstract class ISubscriptionsRepository {
  Future<MemberSubscription> createSubscription({
    required String memberId,
    required DateTime startDate,
    required DateTime endDate,
    required String? planId,
    required String? planName,
    required double amountPaid,
  });
  Future<MemberSubscription?> getLatestSubscription(String memberId);
  Future<List<MemberSubscription>> getMemberSubscriptionHistory(String memberId);
  Stream<MemberSubscription?> watchLatestSubscription(String memberId);
  Stream<List<MemberSubscription>> watchMemberSubscriptionHistory(String memberId);
}

class SubscriptionsRepository implements ISubscriptionsRepository {
  final OutboxDatabase _db;
  final _uuid = const Uuid();

  SubscriptionsRepository(this._db);

  @override
  Future<MemberSubscription> createSubscription({
    required String memberId,
    required DateTime startDate,
    required DateTime endDate,
    required String? planId,
    required String? planName,
    required double amountPaid,
  }) async {
    final sub = MemberSubscriptionsCompanion(
      id: Value(_uuid.v4()),
      memberId: Value(memberId),
      startDate: Value(startDate),
      endDate: Value(endDate),
      planId: Value(planId),
      planName: Value(planName),
      amountPaid: Value(amountPaid),
      status: const Value('active'),
      createdAt: Value(DateTime.now()),
      isSynced: const Value(false),
    );
    final record = await _db.into(_db.memberSubscriptions).insertReturning(sub);
    return record;
  }

  @override
  Future<MemberSubscription?> getLatestSubscription(String memberId) async {
    return (_db.select(_db.memberSubscriptions)
          ..where((t) => t.memberId.equals(memberId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  @override
  Future<List<MemberSubscription>> getMemberSubscriptionHistory(String memberId) async {
    return (_db.select(_db.memberSubscriptions)
          ..where((t) => t.memberId.equals(memberId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  @override
  Stream<MemberSubscription?> watchLatestSubscription(String memberId) {
    return (_db.select(_db.memberSubscriptions)
          ..where((t) => t.memberId.equals(memberId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(1))
        .watchSingleOrNull();
  }

  @override
  Stream<List<MemberSubscription>> watchMemberSubscriptionHistory(String memberId) {
    return (_db.select(_db.memberSubscriptions)
          ..where((t) => t.memberId.equals(memberId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }
}

final subscriptionsRepositoryProvider = Provider<ISubscriptionsRepository>((ref) {
  final db = ref.watch(outboxDatabaseProvider);
  return SubscriptionsRepository(db);
});

final memberSubscriptionHistoryProvider = StreamProvider.family<List<MemberSubscription>, String>((ref, memberId) {
  final repo = ref.watch(subscriptionsRepositoryProvider);
  return repo.watchMemberSubscriptionHistory(memberId);
});
