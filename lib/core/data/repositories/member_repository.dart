import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../local/drift/outbox_database.dart';
import '../local/models/member_snapshot_model.dart';
import '../local/models/domain_event_model.dart';
import '../local/snapshot_builder.dart';
import '../../services/hmac_service.dart';
import '../../providers/base_providers.dart';

abstract class IMemberRepository {
  Future<void> upsertMember(MemberSnapshot member);
  Future<void> upsertMembers(List<MemberSnapshot> members);
  Future<void> deleteMember(String id);
  Future<MemberSnapshot?> getMember(String id);
  Future<List<MemberSnapshot>> getAllMembers();
  Stream<List<MemberSnapshot>> watchAllMembers();
  Future<void> applyEvent(DomainEvent event);
}

class DriftMemberRepository implements IMemberRepository {
  final OutboxDatabase _db;
  final HmacService _hmac;

  DriftMemberRepository(this._db, this._hmac);

  @override
  Future<void> upsertMember(MemberSnapshot member) async {
    // Ensure signed
    String signature = member.hmacSignature ?? '';
    if (signature.isEmpty) {
      signature = await _hmac.signSnapshot(member.memberId, member.toFirestore());
    }

    await _db.into(_db.members).insert(
      MembersCompanion.insert(
        id: member.memberId,
        name: member.name,
        phone: Value(member.phone),
        joinDate: member.joinDate,
        planId: Value(member.planId),
        planName: Value(member.planName),
        expiryDate: Value(member.expiryDate),
        totalPaid: Value(member.totalPaid),
        archived: Value(member.archived),
        gender: Value(member.gender),
        age: Value(member.age),
        checkInPin: Value(member.checkInPin),
        lastCheckIn: Value(member.lastCheckIn),
        hmacSignature: Value(signature),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  @override
  Future<void> upsertMembers(List<MemberSnapshot> members) async {
    await _db.batch((batch) {
      for (final member in members) {
        final signature = member.hmacSignature ?? '';
        batch.insert(
          _db.members,
          MembersCompanion.insert(
            id: member.memberId,
            name: member.name,
            phone: Value(member.phone),
            joinDate: member.joinDate,
            planId: Value(member.planId),
            planName: Value(member.planName),
            expiryDate: Value(member.expiryDate),
            totalPaid: Value(member.totalPaid),
            archived: Value(member.archived),
            gender: Value(member.gender),
            age: Value(member.age),
            checkInPin: Value(member.checkInPin),
            lastCheckIn: Value(member.lastCheckIn),
            hmacSignature: Value(signature),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  @override
  Future<void> applyEvent(DomainEvent event) async {
    final current = await getMember(event.entityId);
    final updated = SnapshotBuilder.apply(current, event);
    if (updated != null) {
      await upsertMember(updated);
    } else if (event.eventType == EventType.memberArchived) {
      await deleteMember(event.entityId);
    }
  }

  @override
  Future<void> deleteMember(String id) async {
    await (_db.delete(_db.members)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<MemberSnapshot?> getMember(String id) async {
    final doc = await (_db.select(_db.members)..where((t) => t.id.equals(id))).getSingleOrNull();
    return doc != null ? MemberSnapshot.fromDrift(doc) : null;
  }

  @override
  Future<List<MemberSnapshot>> getAllMembers() async {
    final docs = await (_db.select(_db.members)..where((t) => t.archived.equals(false))).get();
    return docs.map((d) => MemberSnapshot.fromDrift(d)).toList();
  }

  @override
  Stream<List<MemberSnapshot>> watchAllMembers() {
    return (_db.select(_db.members)..where((t) => t.archived.equals(false)))
        .watch()
        .map((rows) => rows.map((r) => MemberSnapshot.fromDrift(r)).toList());
  }
}

final memberRepositoryProvider = Provider<IMemberRepository>((ref) {
  final db = ref.watch(outboxDatabaseProvider);
  final hmac = ref.watch(hmacServiceProvider);
  return DriftMemberRepository(db, hmac);
});
