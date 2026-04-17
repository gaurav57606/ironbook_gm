import 'package:flutter_test/flutter_test.dart';
import 'package:ironbook_gm/data/local/models/member_snapshot_model.dart';

void main() {
  group('Member Status Logic (TC-UNIT-01)', () {
    final joinDate = DateTime(2026, 1, 1);
    final expiryDate = DateTime(2026, 2, 1);

    test('Status should be active when > 7 days remaining', () {
      final member = MemberSnapshot(
        memberId: 'm1',
        name: 'Test Member',
        joinDate: joinDate,
        expiryDate: expiryDate,
      );

      // 10 days before expiry
      final relativeTo = DateTime(2026, 1, 22);
      expect(member.getStatus(relativeTo), MemberStatus.active);
    });

    test('Status should be expiring when <= 7 days remaining', () {
      final member = MemberSnapshot(
        memberId: 'm1',
        name: 'Test Member',
        joinDate: joinDate,
        expiryDate: expiryDate,
      );

      // 7 days before expiry
      final relativeTo = DateTime(2026, 1, 25);
      expect(member.getStatus(relativeTo), MemberStatus.expiring);
      
      // On expiry day
      final onExpiry = DateTime(2026, 2, 1);
      expect(member.getStatus(onExpiry), MemberStatus.expiring);
    });

    test('Status should be expired when after expiry date', () {
      final member = MemberSnapshot(
        memberId: 'm1',
        name: 'Test Member',
        joinDate: joinDate,
        expiryDate: expiryDate,
      );

      // 1 day after expiry
      final relativeTo = DateTime(2026, 2, 2);
      expect(member.getStatus(relativeTo), MemberStatus.expired);
    });

    test('Status should be pending if no expiry date', () {
      final member = MemberSnapshot(
        memberId: 'm1',
        name: 'Test Member',
        joinDate: joinDate,
        expiryDate: null,
      );

      final relativeTo = DateTime(2026, 1, 1);
      expect(member.getStatus(relativeTo), MemberStatus.pending);
    });
    
    test('Status calculations should be robust to time-of-day', () {
      final member = MemberSnapshot(
        memberId: 'm1',
        name: 'Test Member',
        joinDate: joinDate,
        expiryDate: DateTime(2026, 2, 1, 10, 0), // 10 AM
      );

      // 11 PM on the same day should still be expiring (0 days remaining)
      final sameDayLate = DateTime(2026, 2, 1, 23, 0);
      expect(member.getStatus(sameDayLate), MemberStatus.expiring);
      
      // 1 AM the next day should be expired
      final nextDayEarly = DateTime(2026, 2, 2, 1, 0);
      expect(member.getStatus(nextDayEarly), MemberStatus.expired);
    });
  });
}
