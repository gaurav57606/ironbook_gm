import '../constants/app_spacing.dart';
import '../../shared/utils/date_utils.dart';
import '../data/local/models/member_snapshot_model.dart';

/// Authoritative service for IronBook GM Membership Lifecycle logic.
///
/// This service centralizes all logic for calculating expiries, renewals,
/// and status transitions to ensure deterministic behavior across the app.
class MembershipService {
  const MembershipService();

  /// Calculates the expiry date based on a start date and duration.
  ///
  /// The expiry is set to the end of the day to avoid mid-day expiration.
  DateTime calculateExpiry({
    required DateTime startDate,
    required int durationMonths,
  }) {
    if (durationMonths <= 0) {
      throw ArgumentError('Duration must be greater than zero.');
    }
    
    // Use the canonical addMonths utility to handle month-overflow (e.g., Jan 31 -> Feb 28)
    final calculated = AppDateUtils.addMonths(startDate, durationMonths);
    
    // Set to end of day (23:59:59.999) for a full day of access
    return DateTime(
      calculated.year,
      calculated.month,
      calculated.day,
      23,
      59,
      59,
      999,
    );
  }

  /// Calculates a renewal expiry based on current state.
  ///
  /// If the member is currently active, the renewal extends from the current expiry.
  /// If the member is expired, the renewal starts from [now].
  DateTime calculateRenewal({
    required DateTime? currentExpiry,
    required int durationMonths,
    required DateTime now,
  }) {
    // Determine the base date to start extension from
    // If active: start from current expiry
    // If expired: start from now
    DateTime baseDate;
    if (currentExpiry != null && currentExpiry.isAfter(now)) {
      baseDate = currentExpiry;
    } else {
      baseDate = now;
    }

    return calculateExpiry(
      startDate: baseDate,
      durationMonths: durationMonths,
    );
  }

  /// Deterministically derives status based on expiry and current time.
  MemberStatus deriveStatus({
    required DateTime? expiryDate,
    required DateTime now,
    bool isArchived = false,
  }) {
    if (isArchived) return MemberStatus.archived;
    if (expiryDate == null) return MemberStatus.pending;
    
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    final diff = expiry.difference(today).inDays;

    if (diff < 0) return MemberStatus.expired;
    if (diff <= 7) return MemberStatus.expiring;
    
    return MemberStatus.active;
  }

  /// Lightweight validation for membership state.
  void validateMembership({
    required DateTime? joinDate,
    required int durationMonths,
  }) {
    if (joinDate == null) {
      throw ArgumentError('Joining date cannot be null.');
    }
    if (durationMonths <= 0) {
      throw ArgumentError('Duration must be positive.');
    }
  }
}
