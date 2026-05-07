import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ironbook_gm/core/data/local/drift/outbox_database.dart';
import 'package:ironbook_gm/shared/utils/clock.dart';
import '../data/members_repository.dart';

enum MemberStatus { pending, active, expiring, expired }

extension MemberStatusX on Member {
  int getDaysRemaining(DateTime relativeTo) {
    if (expiryDate == null) return 0;
    final today = DateTime(relativeTo.year, relativeTo.month, relativeTo.day);
    final expiry = DateTime(expiryDate!.year, expiryDate!.month, expiryDate!.day);
    return expiry.difference(today).inDays;
  }

  MemberStatus getStatus(DateTime relativeTo) {
    if (expiryDate == null) return MemberStatus.pending;
    final d = getDaysRemaining(relativeTo);
    if (d < 0) return MemberStatus.expired;
    if (d <= 7) return MemberStatus.expiring;
    return MemberStatus.active;
  }
}

final membersProvider = StreamProvider<List<Member>>((ref) {
  final repository = ref.watch(membersRepositoryProvider);
  return repository.watchAllMembers();
});

final memberSearchQueryProvider = StateProvider<String>((ref) => '');
final memberTabProvider = StateProvider<int>((ref) => 0); // 0: All, 1: Active, 2: Expiring, 3: Expired

final filteredMembersProvider = Provider<List<Member>>((ref) {
  final membersAsync = ref.watch(membersProvider);
  final members = membersAsync.value ?? [];
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

final memberProvider = Provider.family<AsyncValue<Member?>, String>((ref, id) {
  final membersAsync = ref.watch(membersProvider);
  return membersAsync.whenData((members) => 
    members.where((m) => m.id == id).firstOrNull
  );
});

final membersNotifierProvider = Provider<MembersNotifier>((ref) {
  final repository = ref.watch(membersRepositoryProvider);
  return MembersNotifier(repository);
});

class MembersNotifier {
  final IMembersRepository _repository;
  MembersNotifier(this._repository);

  Future<void> upsertMember(Member member) async {
    await _repository.upsertMember(member);
  }

  Future<String> addMember({
    required String name,
    required String phone,
    required String planId,
    required DateTime joinDate,
    String? gender,
    int? age,
  }) async {
    final id = const Uuid().v4();
    final member = Member(
      id: id,
      name: name,
      phone: phone,
      planId: planId,
      joinDate: joinDate,
      gender: gender,
      age: age,
      archived: false,
      totalPaid: 0,
      hmacSignature: '',
    );
    await _repository.upsertMember(member);
    return id;
  }

  Future<void> archiveMember(String id) async {
    await _repository.archiveMember(id);
  }

  Future<void> deleteMember(String id) async {
    await _repository.deleteMember(id);
  }
}
