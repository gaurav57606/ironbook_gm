import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ironbook_gm/core/data/local/drift/outbox_database.dart';
import 'package:ironbook_gm/core/providers/base_providers.dart';

abstract class IMembersRepository {
  Future<void> upsertMember(Member member);
  Future<List<Member>> getAllMembers();
  Stream<List<Member>> watchAllMembers();
  Future<Member?> getMemberById(String id);
  Future<void> archiveMember(String id);
  Future<void> deleteMember(String id);
}

class MembersRepository implements IMembersRepository {
  final OutboxDatabase _db;

  MembersRepository(this._db);

  @override
  Future<void> upsertMember(Member member) async {
    await _db.into(_db.members).insertOnConflictUpdate(member);
  }

  @override
  Future<List<Member>> getAllMembers() async {
    return (_db.select(_db.members)..where((t) => t.archived.equals(false))).get();
  }

  @override
  Stream<List<Member>> watchAllMembers() {
    return (_db.select(_db.members)..where((t) => t.archived.equals(false))).watch();
  }

  @override
  Future<Member?> getMemberById(String id) async {
    return (_db.select(_db.members)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  @override
  Future<void> archiveMember(String id) async {
    await (_db.update(_db.members)..where((t) => t.id.equals(id))).write(
      const MembersCompanion(archived: Value(true)),
    );
  }

  @override
  Future<void> deleteMember(String id) async {
    await (_db.delete(_db.members)..where((t) => t.id.equals(id))).go();
  }
}

final membersRepositoryProvider = Provider<IMembersRepository>((ref) {
  final db = ref.watch(outboxDatabaseProvider);
  return MembersRepository(db);
});
