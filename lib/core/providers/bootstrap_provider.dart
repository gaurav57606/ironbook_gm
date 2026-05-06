import 'package:flutter_riverpod/flutter_riverpod.dart';

enum Tier2Status {
  pending,  // Initial state / starting services
  ready,    // Firebase & Cloud sync active
  degraded, // Timeout or error, local mode active
}

final tier2StatusProvider = StateProvider<Tier2Status>(
  (ref) => Tier2Status.pending,
);

// Deprecated: Migrating to tier2StatusProvider
enum BootstrapPhase {
  tier1Pending,
  tier1Ready,
  tier2Ready,
  tier2Degraded,
}

final bootstrapStateProvider = StateProvider<BootstrapPhase>(
  (ref) => BootstrapPhase.tier1Pending,
);









