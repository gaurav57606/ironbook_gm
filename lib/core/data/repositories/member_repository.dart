import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../local/drift/outbox_database.dart';
import '../local/models/member_snapshot_model.dart';
import '../local/models/domain_event_model.dart';
import '../local/snapshot_builder.dart';
import '../../services/hmac_service.dart';
import '../../providers/base_providers.dart';

abstract class IMemberRepository {
  Future<void> upsertMember(MemberSnapshot member, {bool isSynced = false});
  Future<void> upsertMembers(List<MemberSnapshot> members, {bool isSynced = false});
  Future<void> archiveMember(String memberId);
  Future<void> deleteMember(String id);
  Future<MemberSnapshot?> getMember(String id);
  Future<List<MemberSnapshot>> getMembers(List<String> ids);
  Future<List<MemberSnapshot>> getAllMembers();
  Stream<List<MemberSnapshot>> watchAllMembers();
  Future<void> applyEvent(DomainEvent event);
  Future<int> countActiveMembers();
  Future<List<MemberSnapshot>> getUnsyncedMembers();
  Future<void> markSynced(String id);
}

class DriftMemberRepository implements IMemberRepository {
  final OutboxDatabase _db;
  final HmacService _hmac;

  DriftMemberRepository(this._db, this._hmac);

  @override
  Future<void> upsertMember(MemberSnapshot member, {bool isSynced = false}) async {
    // Ensure signed
    String signature = member.hmacSignature ?? '';
    if (signature.isEmpty) {
      signature = await _hmac.signSnapshot(member.memberId, member.toFirestore());
    }

    debugPrint('[DB] MemberRepository: Upserting member ${member.memberId} (${member.name})');
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
        isSynced: Value(isSynced),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  @override
  Future<void> upsertMembers(List<MemberSnapshot> members, {bool isSynced = false}) async {
    final List<MemberSnapshot> signedMembers = [];

    // Parallelize signing in chunks of 20 to balance isolate overhead and batch processing
    for (int i = 0; i < members.length; i += 20) {
      final chunk = members.skip(i).take(20).toList();
      final results = await Future.wait(chunk.map((m) async {
        if (m.hmacSignature != null && m.hmacSignature!.isNotEmpty) return m;
        final sig = await _hmac.signSnapshot(m.memberId, m.toFirestore());
        return m.copyWith(hmacSignature: sig);
      }));
      signedMembers.addAll(results);
    }

    debugPrint('[DB] MemberRepository: Batch upserting ${signedMembers.length} members');
    await _db.batch((batch) {
      for (final member in signedMembers) {
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
            hmacSignature: Value(member.hmacSignature ?? ''),
            isSynced: Value(isSynced),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  @override
  Future<void> applyEvent(DomainEvent event) async {
    await _db.transaction(() async {
      final current = await getMember(event.entityId);
      final updated = SnapshotBuilder.apply(current, event);
      if (updated != null) {
        await upsertMember(updated);
      } else if (event.eventType == EventType.memberArchived) {
        await archiveMember(event.entityId);
      }
    });
  }

  @override
  Future<void> archiveMember(String memberId) async {
    await (_db.update(_db.members)..where((t) => t.id.equals(memberId)))
        .write(MembersCompanion(archived: const Value(true)));
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
  Future<List<MemberSnapshot>> getMembers(List<String> ids) async {
    final docs = await (_db.select(_db.members)..where((t) => t.id.isIn(ids))).get();
    return docs.map((d) => MemberSnapshot.fromDrift(d)).toList();
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

  @override
  Future<int> countActiveMembers() async {
    final countExp = _db.members.id.count();
    final query = _db.selectOnly(_db.members)
      ..addColumns([countExp])
      ..where(_db.members.archived.equals(false));
    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }
  
  @override
  Future<List<MemberSnapshot>> getUnsyncedMembers() async {
    final docs = await (_db.select(_db.members)..where((t) => t.isSynced.equals(false))).get();
    return docs.map((d) => MemberSnapshot.fromDrift(d)).toList();
  }

  @override
  Future<void> markSynced(String id) async {
    await (_db.update(_db.members)..where((t) => t.id.equals(id)))
        .write(MembersCompanion(isSynced: const Value(true)));
  }
}

final memberRepositoryProvider = Provider<IMemberRepository>((ref) {
  final db = ref.watch(outboxDatabaseProvider);
  final hmac = ref.watch(hmacServiceProvider);
  return DriftMemberRepository(db, hmac);
});
