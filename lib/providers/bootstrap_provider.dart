import 'package:flutter_riverpod/flutter_riverpod.dart';

enum BootstrapPhase {
  tier1Pending,  // before Hive is open
  tier1Ready,    // Hive open, app rendering
  tier2Ready,    // Firebase ready
  tier2Degraded, // Firebase failed/timed out
}

final bootstrapStateProvider = StateProvider<BootstrapPhase>(
  (ref) => BootstrapPhase.tier1Pending,
);
