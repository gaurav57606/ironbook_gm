import 'package:flutter_test/flutter_test.dart';
import 'package:ironbook_gm/data/local/models/domain_event_model.dart';
import 'package:ironbook_gm/data/local/models/member_snapshot_model.dart';
import 'package:ironbook_gm/data/local/snapshot_builder.dart';

/// Property-based testing for Event Sourcing.
/// Ensures that for any sequence of events, rebuilding from scratch 
/// is identical to incremental updates.
class SnapshotPropertyTester {
  static void verifyInvariants(List<DomainEvent> events) {
    // 1. Rebuild from scratch
    final fullRebuild = SnapshotBuilder.rebuild(events);
    
    // 2. Incremental apply
    MemberSnapshot? incremental;
    for (final e in events) {
      incremental = SnapshotBuilder.apply(incremental, e);
    }
    
    expect(fullRebuild, equals(incremental), reason: 'Rebuild must match Incremental Apply');
  }
}
