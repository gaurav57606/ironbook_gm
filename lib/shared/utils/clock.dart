import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Abstract clock to ensure deterministic time in tests.
abstract class IClock {
  DateTime get now;
}

/// Production implementation using system time.
class SystemClock implements IClock {
  @override
  DateTime get now => DateTime.now();
}

/// Test implementation with a fixed, controllable time.
class FrozenClock implements IClock {
  DateTime _now;

  FrozenClock(this._now);

  void setNow(DateTime newTime) => _now = newTime;
  void tick(Duration duration) => _now = _now.add(duration);

  @override
  DateTime get now => _now;
}

/// Riverpod provider for the clock.
final clockProvider = Provider<IClock>((ref) => SystemClock());







