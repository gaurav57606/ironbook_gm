import '../local/drift/outbox_database.dart' as db;
import '../local/models/owner_profile_model.dart' as domain;
import 'package:drift/drift.dart';

abstract class IOwnerRepository {
  Future<domain.OwnerProfile?> getOwner();
  Future<void> upsertOwner(domain.OwnerProfile owner);
  Future<void> applyEvent(dynamic event);
}

class DriftOwnerRepository implements IOwnerRepository {
  final db.OutboxDatabase _db;

  DriftOwnerRepository(this._db);

  @override
  Future<domain.OwnerProfile?> getOwner() async {
    final row = await _db.select(_db.ownerProfiles).getSingleOrNull();
    if (row == null) return null;

    return domain.OwnerProfile(
      gymName: row.gymName,
      ownerName: row.ownerName,
      phone: row.phone,
      address: row.address,
      gstin: row.gstin,
      bankName: row.bankName,
      accountNumber: row.accountNumber,
      ifsc: row.ifsc,
      upiId: row.upiId,
      logoPath: row.logoPath,
      level: row.level,
      exp: row.exp,
      strength: row.strength,
      endurance: row.endurance,
      dexterity: row.dexterity,
      selectedCharacterId: row.selectedCharacterId,
    );
  }

  @override
  Future<void> upsertOwner(domain.OwnerProfile owner) async {
    await _db.into(_db.ownerProfiles).insertOnConflictUpdate(
      db.OwnerProfilesCompanion.insert(
        gymName: owner.gymName,
        ownerName: owner.ownerName,
        phone: owner.phone,
        address: owner.address,
        gstin: Value(owner.gstin),
        bankName: Value(owner.bankName),
        accountNumber: Value(owner.accountNumber),
        ifsc: Value(owner.ifsc),
        upiId: Value(owner.upiId),
        logoPath: Value(owner.logoPath),
        level: Value(owner.level),
        exp: Value(owner.exp),
        strength: Value(owner.strength),
        endurance: Value(owner.endurance),
        dexterity: Value(owner.dexterity),
        selectedCharacterId: Value(owner.selectedCharacterId),
      ),
    );
  }

  @override
  Future<void> applyEvent(dynamic event) async {
    final profile = domain.OwnerProfile.fromFirestore(event.payload);
    await upsertOwner(profile);
  }
}
